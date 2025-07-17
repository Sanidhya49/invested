import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  String backendMessage = '';
  Map<String, dynamic>? fetchedData;
  String oracleQuestion = '';
  String? oracleAnswer;
  bool isOracleLoading = false;

  Future<void> callBackend() async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/protected'),
        headers: {'Authorization': 'Bearer $idToken'},
      );
      setState(() {
        if (response.statusCode == 200) {
          backendMessage =
              json.decode(response.body)['message'] ?? 'No message';
        } else {
          backendMessage = 'Error: ${response.statusCode}';
        }
      });
    } catch (e) {
      setState(() {
        backendMessage = 'Error: $e';
      });
    }
  }

  Future<void> fetchData() async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/fetch-data'),
        headers: {'Authorization': 'Bearer $idToken'},
      );
      setState(() {
        if (response.statusCode == 200) {
          fetchedData = json.decode(response.body);
        } else {
          fetchedData = {'error': 'Status ${response.statusCode}'};
        }
      });
    } catch (e) {
      setState(() {
        fetchedData = {'error': e.toString()};
      });
    }
  }

  Future<void> askOracle() async {
    setState(() {
      isOracleLoading = true;
      oracleAnswer = null;
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
          oracleAnswer = data['answer'] ?? 'No answer';
        } else {
          oracleAnswer = 'Error: ${response.statusCode}';
        }
      });
    } catch (e) {
      setState(() {
        isOracleLoading = false;
        oracleAnswer = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invested Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Welcome, ${user?.displayName ?? user?.email ?? "User"}!'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: callBackend,
                child: const Text('Call Backend'),
              ),
              const SizedBox(height: 16),
              Text(backendMessage),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: fetchData,
                child: const Text('Fetch Financial Data'),
              ),
              const SizedBox(height: 16),
              if (fetchedData != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.grey[200],
                  width: double.infinity,
                  child: Text(
                    const JsonEncoder.withIndent('  ').convert(fetchedData),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Ask Oracle (AI):',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Type your financial question',
                  ),
                  onChanged: (val) => oracleQuestion = val,
                ),
              ),
              ElevatedButton(
                onPressed: isOracleLoading ? null : askOracle,
                child: isOracleLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Ask Oracle'),
              ),
              const SizedBox(height: 16),
              if (oracleAnswer != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.blue[50],
                  width: double.infinity,
                  child: Text(
                    oracleAnswer!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
