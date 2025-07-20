import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

// --- Main Application Setup ---
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
      debugShowCheckedModeBanner: false,
      title: 'Invested',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

// --- Authentication Gate ---
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const SignInScreen();
      },
    );
  }
}

// --- Sign In Screen ---
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // User cancelled
      final GoogleSignInAuthentication? googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print("Sign-in error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sign-in failed: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFe0eafc), Color(0xFFcfdef3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance_wallet_rounded, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 16),
              Text('Welcome to Invested', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Your Personal Financial Co-Pilot', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
                onPressed: () => _signInWithGoogle(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Main Home Screen with Bottom Navigation ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    OracleChatScreen(),
    GuardianAlertsScreen(),
    CatalystOpportunitiesScreen(),
    StrategistScreen(), // NEW Strategist Screen Added
    ProfileScreen(),
  ];

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
              const Icon(Icons.account_balance_wallet_rounded, color: Colors.deepPurple),
              const SizedBox(width: 8),
              const Text('Invested'),
            ],
          ),
          backgroundColor: Colors.white.withOpacity(0.95),
          elevation: 2,
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey.shade600,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Oracle'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_active_outlined), label: 'Alerts'),
            BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'Opportunities'),
            BottomNavigationBarItem(icon: Icon(Icons.insights_rounded), label: 'Strategist'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// --- Oracle Chat Tab ---
class OracleChatScreen extends StatefulWidget {
  const OracleChatScreen({super.key});
  @override
  State<OracleChatScreen> createState() => _OracleChatScreenState();
}

class _OracleChatScreenState extends State<OracleChatScreen> {
  final TextEditingController _textController = TextEditingController();
  bool isOracleLoading = false;
  List<Map<String, String>> oracleChat = [];
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> askOracle() async {
    final question = _textController.text;
    if (question.trim().isEmpty) return;
    _textController.clear();
    setState(() {
      isOracleLoading = true;
      oracleChat.add({'role': 'user', 'text': question});
    });
    _scrollToBottom();
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/ask-oracle'),
        headers: {'Authorization': 'Bearer $idToken', 'Content-Type': 'application/json'},
        body: json.encode({'question': question}),
      );
      if (mounted) {
        setState(() {
          final data = json.decode(response.body);
          oracleChat.add({'role': 'oracle', 'text': data['answer'] ?? 'Error: No answer received.'});
        });
      }
    } catch (e) {
      if (mounted) setState(() => oracleChat.add({'role': 'oracle', 'text': 'Error: $e'}));
    } finally {
      if (mounted) setState(() => isOracleLoading = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8.0),
            itemCount: oracleChat.length,
            itemBuilder: (context, index) {
              final msg = oracleChat[index];
              final isUser = msg['role'] == 'user';
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Row(
                  mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isUser) const CircleAvatar(backgroundColor: Colors.deepPurple, child: Icon(Icons.smart_toy, color: Colors.white, size: 20)),
                    if (!isUser) const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.deepPurple.shade50 : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                        ),
                        child: SelectableText(msg['text'] ?? ''),
                      ),
                    ),
                    if (isUser) const SizedBox(width: 8),
                    if (isUser) CircleAvatar(backgroundColor: Colors.green[200], child: const Icon(Icons.person, color: Colors.white)),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
                    labelText: 'Ask Oracle a question...',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (_) => askOracle(),
                ),
              ),
              const SizedBox(width: 8),
              isOracleLoading
                  ? const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())
                  : FloatingActionButton(backgroundColor: Colors.deepPurple, onPressed: askOracle, child: const Icon(Icons.send, color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }
}

// --- Guardian Alerts Tab ---
class GuardianAlertsScreen extends StatefulWidget {
  const GuardianAlertsScreen({super.key});
  @override
  State<GuardianAlertsScreen> createState() => _GuardianAlertsScreenState();
}

class _GuardianAlertsScreenState extends State<GuardianAlertsScreen> {
  bool isLoading = false;
  List<dynamic> alerts = [];
  String error = '';

  Future<void> fetchAlerts() async {
    if (isLoading) return;
    setState(() { isLoading = true; error = ''; });
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/run-guardian'),
        headers: {'Authorization': 'Bearer $idToken', 'Content-Type': 'application/json'},
        body: '{}',
      ).timeout(const Duration(seconds: 30));
      if (mounted) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          try {
            final parsed = json.decode(data['alerts'].replaceAll("```json", '').replaceAll("```", ''));
            setState(() => alerts = parsed['alerts'] ?? []);
          } catch (_) {
            setState(() => error = 'Could not parse alerts from the AI.');
          }
        } else {
          setState(() => error = 'Error from server: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (mounted) setState(() => error = 'Failed to fetch alerts: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAlerts();
  }

  Color _getSeverityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'critical': return Colors.red.shade100;
      case 'moderate': return Colors.orange.shade100;
      default: return Colors.green.shade100;
    }
  }

  IconData _getSeverityIcon(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'critical': return Icons.warning_amber_rounded;
      case 'moderate': return Icons.error_outline;
      default: return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: fetchAlerts,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Guardian Alerts', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Proactive alerts about your financial health.'),
          const SizedBox(height: 24),
          if (isLoading && alerts.isEmpty) const Center(child: CircularProgressIndicator()),
          if (error.isNotEmpty) Center(child: Text(error, style: const TextStyle(color: Colors.red))),
          if (!isLoading && alerts.isEmpty && error.isEmpty) const Center(child: Text("No alerts found. You're all clear!")),
          ...alerts.map((alert) => Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                color: _getSeverityColor(alert['severity']),
                child: ListTile(
                  leading: Icon(_getSeverityIcon(alert['severity']), size: 40),
                  title: Text(alert['type'] ?? 'Alert', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(alert['description'] ?? ''),
                  isThreeLine: true,
                ),
              )),
        ],
      ),
    );
  }
}

// --- Catalyst Opportunities Tab ---
class CatalystOpportunitiesScreen extends StatefulWidget {
  const CatalystOpportunitiesScreen({super.key});
  @override
  State<CatalystOpportunitiesScreen> createState() => _CatalystOpportunitiesScreenState();
}

class _CatalystOpportunitiesScreenState extends State<CatalystOpportunitiesScreen> {
  bool isLoading = false;
  List<dynamic> opportunities = [];
  String error = '';

  Future<void> fetchOpportunities() async {
    if (isLoading) return;
    setState(() { isLoading = true; error = ''; });
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/run-catalyst'),
        headers: {'Authorization': 'Bearer $idToken', 'Content-Type': 'application/json'},
        body: '{}',
      ).timeout(const Duration(seconds: 30));
      if (mounted) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          try {
            final parsed = json.decode(data['opportunities'].replaceAll("```json", '').replaceAll("```", ''));
            setState(() => opportunities = parsed['opportunities'] ?? []);
          } catch (_) {
            setState(() => error = 'Could not parse opportunities from the AI.');
          }
        } else {
          setState(() => error = 'Error from server: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (mounted) setState(() => error = 'Failed to fetch opportunities: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchOpportunities();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: fetchOpportunities,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Catalyst Opportunities', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Actionable suggestions to improve your finances.'),
          const SizedBox(height: 24),
          if (isLoading && opportunities.isEmpty) const Center(child: CircularProgressIndicator()),
          if (error.isNotEmpty) Center(child: Text(error, style: const TextStyle(color: Colors.red))),
          if (!isLoading && opportunities.isEmpty && error.isEmpty) const Center(child: Text("No new opportunities found right now.")),
          ...opportunities.map((opp) => Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.blue.shade50,
                child: ListTile(
                  leading: Icon(Icons.lightbulb_outline, color: Colors.blue.shade700, size: 40),
                  title: Text(opp['title'] ?? 'Opportunity', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(opp['description'] ?? ''),
                  isThreeLine: true,
                ),
              )),
        ],
      ),
    );
  }
}

// --- NEW: Strategist Screen Tab ---
class StrategistScreen extends StatefulWidget {
  const StrategistScreen({super.key});
  @override
  State<StrategistScreen> createState() => _StrategistScreenState();
}

class _StrategistScreenState extends State<StrategistScreen> {
  bool isLoading = false;
  Map<String, dynamic>? strategy;
  String error = '';

  Future<void> fetchStrategy() async {
    if (isLoading) return;
    setState(() { isLoading = true; error = ''; });
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/run-strategist'),
        headers: {'Authorization': 'Bearer $idToken', 'Content-Type': 'application/json'},
        body: '{}',
      ).timeout(const Duration(seconds: 45)); // Longer timeout for this complex agent
      if (mounted) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          try {
            final parsed = json.decode(data['strategy'].replaceAll("```json", '').replaceAll("```", ''));
            setState(() => strategy = parsed);
          } catch (_) {
            setState(() => error = 'Could not parse strategy from the AI.');
          }
        } else {
          setState(() => error = 'Error from server: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (mounted) setState(() => error = 'Failed to fetch strategy: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchStrategy();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: fetchStrategy,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Investment Strategy', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Real-time analysis of your stock portfolio.'),
          const SizedBox(height: 24),
          if (isLoading) const Center(child: CircularProgressIndicator()),
          if (error.isNotEmpty) Center(child: Text(error, style: const TextStyle(color: Colors.red))),
          if (strategy != null)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Strategist's Summary", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.deepPurple)),
                    const Divider(thickness: 1.5, height: 20),
                    Text(strategy!['summary'] ?? 'No summary available.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
                    const SizedBox(height: 24),
                    Text("Recommendations", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.deepPurple)),
                    const Divider(thickness: 1.5, height: 20),
                    ...(strategy!['recommendations'] as List<dynamic>?)?.map((rec) => ListTile(
                          leading: Icon(
                            rec['advice']?.toUpperCase() == 'HOLD' ? Icons.pause_circle_filled_rounded : Icons.trending_up_rounded,
                            color: rec['advice']?.toUpperCase() == 'HOLD' ? Colors.orange.shade700 : Colors.green.shade700,
                            size: 32,
                          ),
                          title: Text(rec['symbol'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(rec['reasoning'] ?? ''),
                          isThreeLine: true,
                        )) ?? [const Text("No recommendations available.")],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --- Profile Screen Tab ---
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _connectToFi(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final idToken = await user.getIdToken();
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/start-fi-auth'),
        headers: {'Authorization': 'Bearer $idToken'},
      );
      Navigator.pop(context);
      if (response.statusCode == 200) {
        final authUrl = json.decode(response.body)['auth_url'];
        final uri = Uri.parse(authUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.deepPurple[100],
                  child: Text(
                    user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(fontSize: 24, color: Colors.deepPurple),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.displayName ?? 'User Name', style: Theme.of(context).textTheme.titleLarge, overflow: TextOverflow.ellipsis),
                      Text(user?.email ?? 'user@email.com', style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.link_rounded, color: Colors.deepPurple),
          title: const Text('Connect Financial Accounts'),
          subtitle: const Text('via Fi Money (MCP)'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _connectToFi(context),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Logout'),
          onTap: () => FirebaseAuth.instance.signOut(),
        ),
      ],
    );
  }
}