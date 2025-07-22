import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
    setState(() {
      isLoading = true;
      error = '';
    });
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    try {
      final response = await http
          .post(
            Uri.parse('http://10.0.2.2:8000/run-strategist'),
            headers: {
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
            },
            body: '{}',
          )
          .timeout(const Duration(seconds: 45));
      if (mounted) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          try {
            final parsed = json.decode(
              data['strategy'].replaceAll("```json", '').replaceAll("```", ''),
            );
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
          Text(
            'Investment Strategy',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Real-time analysis of your stock portfolio.'),
          const SizedBox(height: 24),
          if (isLoading) const Center(child: CircularProgressIndicator()),
          if (error.isNotEmpty)
            Center(
              child: Text(error, style: const TextStyle(color: Colors.red)),
            ),
          if (strategy != null)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Strategist's Summary",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.deepPurple,
                      ),
                    ),
                    const Divider(thickness: 1.5, height: 20),
                    Text(
                      strategy!['summary'] ?? 'No summary available.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Recommendations",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.deepPurple,
                      ),
                    ),
                    const Divider(thickness: 1.5, height: 20),
                    ...(strategy!['recommendations'] as List<dynamic>?)?.map(
                          (rec) => ListTile(
                            leading: Icon(
                              rec['advice']?.toUpperCase() == 'HOLD'
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.trending_up_rounded,
                              color: rec['advice']?.toUpperCase() == 'HOLD'
                                  ? Colors.orange.shade700
                                  : Colors.green.shade700,
                              size: 32,
                            ),
                            title: Text(
                              rec['symbol'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(rec['reasoning'] ?? ''),
                            isThreeLine: true,
                          ),
                        ) ??
                        [const Text("No recommendations available.")],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
