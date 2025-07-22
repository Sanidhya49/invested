import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/alert_card.dart';

class GuardianAlertsScreen extends StatefulWidget {
  const GuardianAlertsScreen({super.key});
  @override
  State<GuardianAlertsScreen> createState() => _GuardianAlertsScreenState();
}

class _GuardianAlertsScreenState extends State<GuardianAlertsScreen> {
  bool isLoading = false;
  List<dynamic> alerts = [];
  String error = '';
  bool _hasFetchedOnce = false;

  Future<void> fetchAlerts() async {
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
            Uri.parse('http://10.0.2.2:8000/run-guardian'),
            headers: {
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
            },
            body: '{}',
          )
          .timeout(const Duration(seconds: 30));
      if (mounted) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          try {
            final parsed = json.decode(
              data['alerts'].replaceAll("```json", '').replaceAll("```", ''),
            );
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
    if (!_hasFetchedOnce) {
      fetchAlerts();
      setState(() {
        _hasFetchedOnce = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: fetchAlerts,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Guardian Alerts',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Proactive alerts about your financial health.'),
          const SizedBox(height: 24),
          if (isLoading && alerts.isEmpty)
            const Center(child: CircularProgressIndicator()),
          if (error.isNotEmpty)
            Center(
              child: Text(error, style: const TextStyle(color: Colors.red)),
            ),
          if (!isLoading && alerts.isEmpty && error.isEmpty)
            const Center(child: Text("No alerts found. You're all clear!")),
          ...alerts.map(
            (alert) => AlertCard(
              type: alert['type'] ?? 'Alert',
              description: alert['description'] ?? '',
              severity: alert['severity'] ?? 'info',
            ),
          ),
        ],
      ),
    );
  }
}
