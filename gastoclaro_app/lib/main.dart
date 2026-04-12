import 'package:flutter/material.dart';

import 'models/monthly_dashboard.dart';
import 'services/dashboard_service.dart';

void main() {
  runApp(const GastoClaroApp());
}

class GastoClaroApp extends StatelessWidget {
  const GastoClaroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GastoClaro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<MonthlyDashboard> futureDashboard;
  final DashboardService dashboardService = DashboardService();

  int year = 2026;
  int month = 4;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  void loadDashboard() {
    futureDashboard = dashboardService.getMonthlyDashboard(
      year: year,
      month: month,
    );
  }

  void reload() {
    setState(() {
      loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GastoClaro Dashboard'),
        actions: [
          IconButton(
            onPressed: reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<MonthlyDashboard>(
        future: futureDashboard,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load dashboard',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: reload,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final dashboard = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(
                title: 'Selected month',
                value: dashboard.selectedMonth,
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                title: 'Expected income',
                value: dashboard.expectedIncomeTotal.toStringAsFixed(2),
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                title: 'Fixed expenses',
                value: dashboard.fixedExpenseTotal.toStringAsFixed(2),
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                title: 'Debt due total',
                value: dashboard.debtDueTotal.toStringAsFixed(2),
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                title: 'Obligation total',
                value: dashboard.obligationTotal.toStringAsFixed(2),
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                title: 'Projected balance',
                value: dashboard.projectedBalance.toStringAsFixed(2),
                isNegative: dashboard.projectedBalance < 0,
              ),
              const SizedBox(height: 24),
              Text(
                'Attention items',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (dashboard.attentionItems.isEmpty)
                const Text('No attention items.')
              else
                ...dashboard.attentionItems.map(_ObligationTile.new),
              const SizedBox(height: 24),
              Text(
                'Upcoming items',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (dashboard.upcomingItems.isEmpty)
                const Text('No upcoming items.')
              else
                ...dashboard.upcomingItems.map(_ObligationTile.new),
              const SizedBox(height: 24),
              Text(
                dashboard.dashboardNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final bool isNegative;

  const _SummaryCard({
    required this.title,
    required this.value,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isNegative ? Colors.red : null,
          ),
        ),
      ),
    );
  }
}

class _ObligationTile extends StatelessWidget {
  final Map<String, dynamic> item;

  const _ObligationTile(this.item);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(item['title']?.toString() ?? ''),
        subtitle: Text(
          'Due date: ${item['due_date'] ?? '-'}\n'
              'Status: ${item['schedule_status'] ?? '-'}',
        ),
        trailing: Text(
          item['amount']?.toString() ?? '0',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}