import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  List<dynamic> subscriptions = [];

  @override
  void initState() {
    super.initState();
    // TODO: Connect to FastAPI backend
    // Fetch subscription data from an endpoint like '/api/subscriptions'
    _fetchSubscriptions();
  }

  void _fetchSubscriptions() {
    // Simulating a network call
    setState(() {
      subscriptions = [
        {
          'name': 'Netflix',
          'amount': 649,
          'status': 'active',
          'last_used': '2 days ago',
        },
        {
          'name': 'Spotify',
          'amount': 119,
          'status': 'active',
          'last_used': '1 day ago',
        },
        {
          'name': 'Gym Membership',
          'amount': 2500,
          'status': 'unused',
          'last_used': '45 days ago',
        },
        {
          'name': 'Adobe Creative',
          'amount': 1699,
          'status': 'active',
          'last_used': '5 days ago',
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Subscriptions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Monthly Total'),
                Text(
                  Formatters.formatCurrency(4967),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.orange.shade100,
            child: const ListTile(
              leading: Icon(Icons.warning, color: Colors.orange),
              title: Text('Potentially Unused'),
              subtitle: Text(
                'Save \u20b92,500/month by canceling unused subscriptions',
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...subscriptions.map((sub) {
            final bool isUnused = sub['status'] == 'unused';
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  sub['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Last used: ${sub['last_used']}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.formatCurrency(sub['amount']),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isUnused
                            ? Colors.red.shade100
                            : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        sub['status'],
                        style: TextStyle(
                          fontSize: 12,
                          color: isUnused ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
