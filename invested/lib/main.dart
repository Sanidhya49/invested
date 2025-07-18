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
    return Scaffold(
      appBar: AppBar(title: const Text('Invested')),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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
    );
  }
}

// Oracle Chat Tab
class OracleChatScreen extends StatefulWidget {
  @override
  State<OracleChatScreen> createState() => _OracleChatScreenState();
}

class _OracleChatScreenState extends State<OracleChatScreen> {
  String oracleQuestion = '';
  bool isOracleLoading = false;
  List<Map<String, String>> oracleChat = [];

  Future<void> askOracle() async {
    if (oracleQuestion.trim().isEmpty) return;
    setState(() {
      isOracleLoading = true;
      oracleChat.add({'role': 'user', 'text': oracleQuestion});
    });
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
    } catch (e) {
      setState(() {
        isOracleLoading = false;
        oracleChat.add({'role': 'oracle', 'text': 'Error: $e'});
        oracleQuestion = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome, ${user?.displayName ?? user?.email ?? "User"}!'),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text('Oracle Chat', style: Theme.of(context).textTheme.titleMedium),
            Container(
              height: 300,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListView.builder(
                itemCount: oracleChat.length,
                itemBuilder: (context, index) {
                  final msg = oracleChat[index];
                  final isUser = msg['role'] == 'user';
                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.green[100] : Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        msg['text'] ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          color: isUser ? Colors.black87 : Colors.blue[900],
                        ),
                      ),
                    ),
                  );
                },
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
                      ),
                      onChanged: (val) => oracleQuestion = val,
                      onSubmitted: (_) => askOracle(),
                      controller: TextEditingController(text: oracleQuestion),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isOracleLoading ? null : askOracle,
                    child: isOracleLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            (alert) => Card(
              color: alert['severity'] == 'critical'
                  ? Colors.red[100]
                  : alert['severity'] == 'moderate'
                  ? Colors.yellow[100]
                  : Colors.green[100],
              child: ListTile(
                title: Text(alert['type'] ?? 'Alert'),
                subtitle: Text(alert['description'] ?? ''),
                trailing: Text(
                  alert['severity']?.toUpperCase() ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
            (opp) => Card(
              color: Colors.blue[50],
              child: ListTile(
                title: Text(opp['title'] ?? 'Opportunity'),
                subtitle: Text(opp['description'] ?? ''),
                trailing: Text(
                  opp['category']?.toUpperCase() ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
