import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/opportunity_card.dart';

class CatalystOpportunitiesScreen extends StatefulWidget {
  const CatalystOpportunitiesScreen({super.key});
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
            Uri.parse('http://10.0.2.2:8000/run-catalyst'),
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
              data['opportunities']
                  .replaceAll("```json", '')
                  .replaceAll("```", ''),
            );
            setState(() => opportunities = parsed['opportunities'] ?? []);
          } catch (_) {
            setState(
              () => error = 'Could not parse opportunities from the AI.',
            );
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
          Text(
            'Catalyst Opportunities',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Actionable suggestions to improve your finances.'),
          const SizedBox(height: 24),
          if (isLoading && opportunities.isEmpty)
            const Center(child: CircularProgressIndicator()),
          if (error.isNotEmpty)
            Center(
              child: Text(error, style: const TextStyle(color: Colors.red)),
            ),
          if (!isLoading && opportunities.isEmpty && error.isEmpty)
            const Center(child: Text("No new opportunities found right now.")),
          ...opportunities.map(
            (opp) => OpportunityCard(
              title: opp['title'] ?? 'Opportunity',
              description: opp['description'] ?? '',
              category: opp['category'],
            ),
          ),
        ],
      ),
    );
  }
}
