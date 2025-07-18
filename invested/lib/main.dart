import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const InvestedApp());
}

class InvestedApp extends StatelessWidget {
  const InvestedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invested',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const SignInScreen();
      },
    );
  }
}

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  Future<void> _signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invested - Sign In')),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.login),
          label: const Text('Sign in with Google'),
          onPressed: _signInWithGoogle,
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      OracleChatScreen(),
      GuardianAlertsScreen(),
      CatalystOpportunitiesScreen(),
    ]);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFe0eafc), Color(0xFFcfdef3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.deepPurple,
              ),
              const SizedBox(width: 8),
              const Text('Invested'),
            ],
          ),
          backgroundColor: Colors.white.withOpacity(0.95),
          elevation: 2,
        ),
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'Oracle',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_active_outlined),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up),
              label: 'Opportunities',
            ),
          ],
        ),
      ),
    );
  }
}

// Oracle Chat Tab
class OracleChatScreen extends StatefulWidget {
  @override
  State<OracleChatScreen> createState() => _OracleChatScreenState();
}

class _OracleChatScreenState extends State<OracleChatScreen>
    with TickerProviderStateMixin {
  String oracleQuestion = '';
  bool isOracleLoading = false;
  List<Map<String, String>> oracleChat = [];
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> askOracle() async {
    if (oracleQuestion.trim().isEmpty) return;
    setState(() {
      isOracleLoading = true;
      oracleChat.add({'role': 'user', 'text': oracleQuestion});
    });
    _scrollToBottom();
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/ask-oracle'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'question': oracleQuestion}),
      );
      setState(() {
        isOracleLoading = false;
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          oracleChat.add({
            'role': 'oracle',
            'text': data['answer'] ?? 'No answer',
          });
        } else {
          oracleChat.add({
            'role': 'oracle',
            'text': 'Error: ${response.statusCode}',
          });
        }
        oracleQuestion = '';
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        isOracleLoading = false;
        oracleChat.add({'role': 'oracle', 'text': 'Error: $e'});
        oracleQuestion = '';
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.deepPurple[100],
            child: const Icon(
              Icons.account_circle,
              size: 48,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Welcome, ${user?.displayName ?? user?.email ?? "User"}!',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: oracleChat.length,
                itemBuilder: (context, index) {
                  final msg = oracleChat[index];
                  final isUser = msg['role'] == 'user';
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: isUser
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isUser)
                          CircleAvatar(
                            backgroundColor: Colors.deepPurple[200],
                            child: const Icon(
                              Icons.smart_toy,
                              color: Colors.white,
                            ),
                          ),
                        if (!isUser) const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? Colors.deepPurple[100]
                                  : Colors.blue[50],
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              msg['text'] ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                color: isUser
                                    ? Colors.black87
                                    : Colors.blue[900],
                              ),
                            ),
                          ),
                        ),
                        if (isUser) const SizedBox(width: 8),
                        if (isUser)
                          CircleAvatar(
                            backgroundColor: Colors.green[200],
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Type your financial question',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (val) => oracleQuestion = val,
                    onSubmitted: (_) => askOracle(),
                    controller: TextEditingController(text: oracleQuestion),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isOracleLoading
                      ? const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : FloatingActionButton(
                          mini: true,
                          backgroundColor: Colors.deepPurple,
                          onPressed: askOracle,
                          child: const Icon(Icons.send, color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// Guardian Alerts Tab
class GuardianAlertsScreen extends StatefulWidget {
  @override
  State<GuardianAlertsScreen> createState() => _GuardianAlertsScreenState();
}

class _GuardianAlertsScreenState extends State<GuardianAlertsScreen> {
  bool isLoading = false;
  List<dynamic> alerts = [];
  String error = '';

  Future<void> fetchAlerts() async {
    setState(() {
      isLoading = true;
      error = '';
    });
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/run-guardian'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: '{}',
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Try to parse the alerts as JSON if possible
        try {
          final parsed = json.decode(
            data['alerts'].replaceAll("```json", '').replaceAll("```", ''),
          );
          setState(() {
            alerts = parsed['alerts'] ?? [];
          });
        } catch (_) {
          setState(() {
            alerts = [];
            error = 'Could not parse alerts.';
          });
        }
      } else {
        setState(() {
          error = 'Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => fetchAlerts(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Guardian Alerts',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (isLoading) const Center(child: CircularProgressIndicator()),
          if (error.isNotEmpty)
            Text(error, style: const TextStyle(color: Colors.red)),
          ...alerts.map(
            (alert) => AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              child: Card(
                elevation: 3,
                color: alert['severity'] == 'critical'
                    ? Colors.red[100]
                    : alert['severity'] == 'moderate'
                    ? Colors.yellow[100]
                    : Colors.green[100],
                child: ListTile(
                  leading: Icon(
                    alert['severity'] == 'critical'
                        ? Icons.warning_amber_rounded
                        : alert['severity'] == 'moderate'
                        ? Icons.error_outline
                        : Icons.check_circle_outline,
                    color: alert['severity'] == 'critical'
                        ? Colors.red
                        : alert['severity'] == 'moderate'
                        ? Colors.orange
                        : Colors.green,
                  ),
                  title: Text(
                    alert['type'] ?? 'Alert',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(alert['description'] ?? ''),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: alert['severity'] == 'critical'
                          ? Colors.red[300]
                          : alert['severity'] == 'moderate'
                          ? Colors.orange[200]
                          : Colors.green[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      alert['severity']?.toUpperCase() ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Catalyst Opportunities Tab
class CatalystOpportunitiesScreen extends StatefulWidget {
  @override
  State<CatalystOpportunitiesScreen> createState() =>
      _CatalystOpportunitiesScreenState();
}

class _CatalystOpportunitiesScreenState
    extends State<CatalystOpportunitiesScreen> {
  bool isLoading = false;
  List<dynamic> opportunities = [];
  String error = '';

  Future<void> fetchOpportunities() async {
    setState(() {
      isLoading = true;
      error = '';
    });
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/run-catalyst'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: '{}',
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Try to parse the opportunities as JSON if possible
        try {
          final parsed = json.decode(
            data['opportunities']
                .replaceAll("```json", '')
                .replaceAll("```", ''),
          );
          setState(() {
            opportunities = parsed['opportunities'] ?? [];
          });
        } catch (_) {
          setState(() {
            opportunities = [];
            error = 'Could not parse opportunities.';
          });
        }
      } else {
        setState(() {
          error = 'Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchOpportunities();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => fetchOpportunities(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Catalyst Opportunities',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (isLoading) const Center(child: CircularProgressIndicator()),
          if (error.isNotEmpty)
            Text(error, style: const TextStyle(color: Colors.red)),
          ...opportunities.map(
            (opp) => AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              child: Card(
                elevation: 3,
                color: Colors.blue[50],
                child: ListTile(
                  leading: Icon(
                    Icons.lightbulb_outline,
                    color: Colors.blue[700],
                  ),
                  title: Text(
                    opp['title'] ?? 'Opportunity',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(opp['description'] ?? ''),
                  trailing: opp['category'] != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            opp['category']?.toUpperCase() ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
