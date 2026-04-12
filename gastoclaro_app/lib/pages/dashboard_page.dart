import 'package:flutter/material.dart';

import '../models/monthly_dashboard.dart';
import '../services/dashboard_service.dart';
import '../services/payment_obligation_service.dart';
import '../utils/app_formatters.dart';

class DashboardPage extends StatefulWidget {
  final int year;
  final int month;
  final VoidCallback? onOpenObligations;
  final VoidCallback? onOpenPayments;
  final VoidCallback? onOpenIncomeEvents;

  const DashboardPage({
    super.key,
    required this.year,
    required this.month,
    this.onOpenObligations,
    this.onOpenPayments,
    this.onOpenIncomeEvents,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<MonthlyDashboard> futureDashboard;
  final DashboardService dashboardService = DashboardService();
  final PaymentObligationService paymentObligationService =
  PaymentObligationService();

  bool isSyncing = false;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  @override
  void didUpdateWidget(covariant DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.year != widget.year || oldWidget.month != widget.month) {
      loadDashboard();
    }
  }

  void loadDashboard() {
    futureDashboard = dashboardService.getMonthlyDashboard(
      year: widget.year,
      month: widget.month,
    );
  }

  Future<void> reload() async {
    setState(() {
      loadDashboard();
    });
  }

  Future<void> syncMonthlyObligations() async {
    if (isSyncing) {
      return;
    }

    setState(() {
      isSyncing = true;
    });

    try {
      await paymentObligationService.syncMonthly(
        year: widget.year,
        month: widget.month,
      );

      await reload();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Obligaciones sincronizadas correctamente'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo sincronizar: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MonthlyDashboard>(
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

        return RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Resumen del periodo',
                              style: TextStyle(
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppFormatters.monthYear(widget.year, widget.month),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: isSyncing ? null : syncMonthlyObligations,
                    icon: isSyncing
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.sync),
                    label: Text(
                      isSyncing ? 'Sincronizando...' : 'Sincronizar',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: widget.onOpenObligations,
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('Ver obligaciones'),
                  ),
                  OutlinedButton.icon(
                    onPressed: widget.onOpenPayments,
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Ver pagos'),
                  ),
                  OutlinedButton.icon(
                    onPressed: widget.onOpenIncomeEvents,
                    icon: const Icon(Icons.event_note_outlined),
                    label: const Text('Ver eventos'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SummaryCard(
                title: 'Ingreso esperado',
                value: AppFormatters.money(dashboard.expectedIncomeTotal),
                icon: Icons.trending_up,
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                title: 'Ingreso recibido',
                value: AppFormatters.money(dashboard.receivedIncomeTotal),
                icon: Icons.savings_outlined,
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                title: 'Obligaciones del mes',
                value: AppFormatters.money(dashboard.obligationTotal),
                icon: Icons.account_balance_wallet_outlined,
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                title: 'Total pagado',
                value: AppFormatters.money(dashboard.paidTotal),
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                title: 'Pendiente por pagar',
                value: AppFormatters.money(dashboard.remainingObligationTotal),
                icon: Icons.warning_amber_outlined,
                isAlert: dashboard.remainingObligationTotal > 0,
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                title: 'Balance real',
                value: AppFormatters.money(dashboard.actualBalance),
                icon: Icons.pie_chart_outline,
                isAlert: dashboard.actualBalance < 0,
              ),
              const SizedBox(height: 24),
              _SectionTitle(
                title: 'Requieren atención',
                count: dashboard.attentionItems.length,
              ),
              const SizedBox(height: 8),
              if (dashboard.attentionItems.isEmpty)
                const Text('No hay elementos en atención.')
              else
                ...dashboard.attentionItems.map(
                      (item) => _DashboardItemCard(item: item),
                ),
              const SizedBox(height: 24),
              _SectionTitle(
                title: 'Pendientes',
                count: dashboard.pendingItems.length,
              ),
              const SizedBox(height: 8),
              if (dashboard.pendingItems.isEmpty)
                const Text('No hay elementos pendientes.')
              else
                ...dashboard.pendingItems.map(
                      (item) => _DashboardItemCard(item: item),
                ),
              const SizedBox(height: 24),
              _SectionTitle(
                title: 'Pagados',
                count: dashboard.paidItems.length,
              ),
              const SizedBox(height: 8),
              if (dashboard.paidItems.isEmpty)
                const Text('No hay elementos pagados.')
              else
                ...dashboard.paidItems.map(
                      (item) => _DashboardItemCard(item: item),
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
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isAlert;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: isAlert ? Colors.red : colorScheme.primary,
        ),
        title: Text(title),
        subtitle: Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isAlert ? Colors.red : null,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;

  const _SectionTitle({
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Text(count.toString()),
        ),
      ],
    );
  }
}

class _DashboardItemCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _DashboardItemCard({
    required this.item,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      case 'pending':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = item['status']?.toString() ?? '';
    final color = _statusColor(status);

    return Card(
      child: ListTile(
        title: Text(item['title']?.toString() ?? ''),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Vence: ${AppFormatters.date(item['due_date'])}'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: color.withValues(alpha: 0.12),
              ),
              child: Text(
                AppFormatters.obligationStatus(status),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: Text(
          AppFormatters.money(
            (item['amount_due'] as num?) ?? 0,
            item['currency']?.toString() ?? 'PEN',
          ),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}