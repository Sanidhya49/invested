import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  // Placeholder data - replace with state from your backend
  Map<String, dynamic>? portfolioData;

  @override
  void initState() {
    super.initState();
    // TODO: Connect to FastAPI backend
    // Fetch investment data from an endpoint like '/api/investments'
    // and use setState to update portfolioData.
    _fetchInvestmentData();
  }

  void _fetchInvestmentData() {
    // Simulating a network call
    setState(() {
      portfolioData = {
        'totalValue': 2700000,
        'totalReturns': 12.8,
        'investments': [
          {
            'name': 'Mutual Funds',
            'amount': 1200000,
            'return': 12.5,
            'color': Colors.green.shade800,
          },
          {
            'name': 'Stocks',
            'amount': 850000,
            'return': 15.2,
            'color': Colors.green.shade500,
          },
          {
            'name': 'Fixed Deposits',
            'amount': 400000,
            'return': 6.8,
            'color': Colors.orange.shade500,
          },
        ],
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Investment Portfolio',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: portfolioData == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Value',
                                style: theme.textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                Formatters.formatCurrency(
                                  portfolioData!['totalValue'],
                                ),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Returns',
                                style: theme.textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '+${portfolioData!['totalReturns']}%',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ...portfolioData!['investments'].map<Widget>((investment) {
                  double percentage =
                      investment['amount'] / portfolioData!['totalValue'];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: investment['color'],
                                radius: 6,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  investment['name'],
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    Formatters.formatCurrency(
                                      investment['amount'],
                                    ),
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '+${investment['return']}%',
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: percentage,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              investment['color'],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
    );
  }
}
