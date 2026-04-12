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

  String formatMoney(double value) {
    return 'S/ ${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel mensual'),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando panel...'),
                ],
              ),
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
                      'No se pudo cargar el panel',
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
                      child: const Text('Reintentar'),
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
                title: 'Mes seleccionado',
                value: dashboard.selectedMonth,
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                title: 'Ingreso esperado',
                value: formatMoney(dashboard.expectedIncomeTotal),
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                title: 'Ingreso recibido',
                value: formatMoney(dashboard.receivedIncomeTotal),
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                title: 'Obligaciones del mes',
                value: formatMoney(dashboard.obligationTotal),
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                title: 'Total pagado',
                value: formatMoney(dashboard.paidTotal),
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                title: 'Pendiente por pagar',
                value: formatMoney(dashboard.remainingObligationTotal),
                isNegative: dashboard.remainingObligationTotal > 0,
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                title: 'Balance proyectado',
                value: formatMoney(dashboard.projectedBalance),
                isNegative: dashboard.projectedBalance < 0,
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                title: 'Balance real',
                value: formatMoney(dashboard.actualBalance),
                isNegative: dashboard.actualBalance < 0,
              ),
              const SizedBox(height: 24),
              Text(
                'Requieren atención',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (dashboard.attentionItems.isEmpty)
                const Text('No hay elementos en atención.')
              else
                ...dashboard.attentionItems.map(
                      (item) => _ObligationTile(
                    item: item,
                    amountKey: 'amount_due',
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'Pendientes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (dashboard.pendingItems.isEmpty)
                const Text('No hay pendientes.')
              else
                ...dashboard.pendingItems.map(
                      (item) => _ObligationTile(
                    item: item,
                    amountKey: 'amount_due',
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'Pagados',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (dashboard.paidItems.isEmpty)
                const Text('No hay pagos completados.')
              else
                ...dashboard.paidItems.map(
                      (item) => _ObligationTile(
                    item: item,
                    amountKey: 'amount_due',
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'Próximos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (dashboard.upcomingItems.isEmpty)
                const Text('No hay próximos vencimientos.')
              else
                ...dashboard.upcomingItems.map(
                      (item) => _ObligationTile(
                    item: item,
                    amountKey: 'amount_due',
                  ),
                ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    dashboard.dashboardNote,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
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
  final String amountKey;

  const _ObligationTile({
    required this.item,
    required this.amountKey,
  });

  String formatMoney(dynamic value) {
    final parsed = double.tryParse(value.toString()) ?? 0;
    return 'S/ ${parsed.toStringAsFixed(2)}';
  }

  String translateStatus(String? status) {
    switch (status) {
      case 'paid':
        return 'Pagado';
      case 'partial':
        return 'Parcial';
      case 'pending':
        return 'Pendiente';
      case 'overdue':
        return 'Vencido';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(item['title']?.toString() ?? ''),
        subtitle: Text(
          'Vence: ${item['due_date'] ?? '-'}\n'
              'Estado: ${translateStatus(item['status']?.toString())}',
        ),
        trailing: Text(
          formatMoney(item[amountKey]),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}