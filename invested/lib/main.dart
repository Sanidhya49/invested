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

  Future<void> callBackend() async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    try {
      final response = await http.get(
        Uri.parse(
          'http://10.0.2.2:8000/protected',
        ), // Use 10.0.2.2 for Android emulator
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
          ],
        ),
      ),
    );
  }
}
