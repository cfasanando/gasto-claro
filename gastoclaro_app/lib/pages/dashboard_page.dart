import 'package:flutter/material.dart';

import '../models/monthly_dashboard.dart';
import '../services/dashboard_service.dart';
import '../services/payment_obligation_service.dart';
import '../services/payment_record_service.dart';
import '../utils/app_formatters.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_section_header.dart';
import '../widgets/app_status_chip.dart';
import '../widgets/payment_record_sheet.dart';

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
  final PaymentRecordService paymentRecordService = PaymentRecordService();

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

  Future<void> registerPaymentFromDashboard(Map<String, dynamic> item) async {
    final obligationId = item['id'] as int?;
    final amountDue = ((item['amount_due'] as num?) ?? 0).toDouble();
    final currency = item['currency']?.toString() ?? 'PEN';
    final title = item['title']?.toString() ?? 'Obligación';

    if (obligationId == null || obligationId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo identificar la obligación'),
        ),
      );

      return;
    }

    final draft = await showPaymentRecordSheet(
      context: context,
      title: title,
      amountDue: amountDue,
      currency: currency,
    );

    if (draft == null) {
      return;
    }

    try {
      await paymentRecordService.createPaymentRecord(
        paymentObligationId: obligationId,
        paidAmount: draft.paidAmount,
        currency: draft.currency,
        paidAt: draft.paidAt,
        paymentMethod: draft.paymentMethod,
        note: draft.note,
      );

      await reload();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pago registrado correctamente'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo registrar el pago: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MonthlyDashboard>(
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
              child: AppEmptyState(
                icon: Icons.error_outline,
                title: 'No se pudo cargar el panel',
                subtitle: snapshot.error.toString(),
              ),
            ),
          );
        }

        final dashboard = snapshot.data!;
        final width = MediaQuery.of(context).size.width;
        final summaryColumns = width >= 1100
            ? 4
            : width >= 720
            ? 2
            : 1;

        return RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _HeroBalanceCard(
                monthLabel: AppFormatters.monthYear(widget.year, widget.month),
                actualBalance: dashboard.actualBalance,
                remainingAmount: dashboard.remainingObligationTotal,
                paidAmount: dashboard.paidTotal,
              ),
              const SizedBox(height: 18),
              AppSectionHeader(
                title: 'Acciones rápidas',
                subtitle: 'Atajos principales para este mes',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _QuickActionCard(
                    icon: Icons.sync,
                    title: isSyncing ? 'Sincronizando...' : 'Sincronizar',
                    subtitle: 'Actualizar obligaciones',
                    color: Theme.of(context).colorScheme.primary,
                    onTap: isSyncing ? null : syncMonthlyObligations,
                  ),
                  _QuickActionCard(
                    icon: Icons.receipt_long_outlined,
                    title: 'Obligaciones',
                    subtitle: 'Ver y pagar',
                    color: const Color(0xFF0EA5E9),
                    onTap: widget.onOpenObligations,
                  ),
                  _QuickActionCard(
                    icon: Icons.payments_outlined,
                    title: 'Pagos',
                    subtitle: 'Historial del mes',
                    color: const Color(0xFF10B981),
                    onTap: widget.onOpenPayments,
                  ),
                  _QuickActionCard(
                    icon: Icons.event_note_outlined,
                    title: 'Eventos',
                    subtitle: 'Ingresos del mes',
                    color: const Color(0xFFF59E0B),
                    onTap: widget.onOpenIncomeEvents,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AppSectionHeader(
                title: 'Resumen del mes',
                subtitle: 'Vista rápida de lo más importante',
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: summaryColumns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: width >= 720 ? 1.6 : 1.9,
                children: [
                  _MetricCard(
                    title: 'Ingreso esperado',
                    value: AppFormatters.money(dashboard.expectedIncomeTotal),
                    icon: Icons.trending_up,
                    accent: const Color(0xFF10B981),
                  ),
                  _MetricCard(
                    title: 'Ingreso recibido',
                    value: AppFormatters.money(dashboard.receivedIncomeTotal),
                    icon: Icons.savings_outlined,
                    accent: const Color(0xFF0EA5E9),
                  ),
                  _MetricCard(
                    title: 'Obligaciones',
                    value: AppFormatters.money(dashboard.obligationTotal),
                    icon: Icons.account_balance_wallet_outlined,
                    accent: const Color(0xFFF59E0B),
                  ),
                  _MetricCard(
                    title: 'Pagado',
                    value: AppFormatters.money(dashboard.paidTotal),
                    icon: Icons.check_circle_outline,
                    accent: const Color(0xFF22C55E),
                  ),
                  _MetricCard(
                    title: 'Pendiente',
                    value: AppFormatters.money(dashboard.remainingObligationTotal),
                    icon: Icons.warning_amber_outlined,
                    accent: dashboard.remainingObligationTotal > 0
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF94A3B8),
                  ),
                  _MetricCard(
                    title: 'Balance real',
                    value: AppFormatters.money(dashboard.actualBalance),
                    icon: Icons.show_chart_outlined,
                    accent: dashboard.actualBalance < 0
                        ? const Color(0xFFEF4444)
                        : Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AppSectionHeader(
                title: 'Requieren atención',
                subtitle: '${dashboard.attentionItems.length} elementos',
              ),
              const SizedBox(height: 12),
              if (dashboard.attentionItems.isEmpty)
                const AppEmptyState(
                  icon: Icons.auto_awesome_outlined,
                  title: 'Todo tranquilo por aquí',
                  subtitle: 'No hay alertas activas en este momento.',
                )
              else
                ...dashboard.attentionItems.map(
                      (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DashboardObligationCard(
                      item: item,
                      showPayAction: true,
                      onPay: () => registerPaymentFromDashboard(item),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              AppSectionHeader(
                title: 'Pendientes',
                subtitle: '${dashboard.pendingItems.length} elementos',
              ),
              const SizedBox(height: 12),
              if (dashboard.pendingItems.isEmpty)
                const AppEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No hay pendientes',
                  subtitle: 'Tus obligaciones del periodo están al día.',
                )
              else
                ...dashboard.pendingItems.map(
                      (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DashboardObligationCard(
                      item: item,
                      showPayAction: true,
                      onPay: () => registerPaymentFromDashboard(item),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              AppSectionHeader(
                title: 'Pagados',
                subtitle: '${dashboard.paidItems.length} elementos',
              ),
              const SizedBox(height: 12),
              if (dashboard.paidItems.isEmpty)
                const AppEmptyState(
                  icon: Icons.check_circle_outline,
                  title: 'Aún no hay pagos registrados',
                  subtitle: 'Cuando registres pagos aparecerán aquí.',
                )
              else
                ...dashboard.paidItems.map(
                      (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DashboardObligationCard(
                      item: item,
                      showPayAction: false,
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

class _HeroBalanceCard extends StatelessWidget {
  final String monthLabel;
  final double actualBalance;
  final double remainingAmount;
  final double paidAmount;

  const _HeroBalanceCard({
    required this.monthLabel,
    required this.actualBalance,
    required this.remainingAmount,
    required this.paidAmount,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = actualBalance < 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4F46E5),
            Color(0xFF6366F1),
            Color(0xFF14B8A6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            monthLabel,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Balance real',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppFormatters.money(actualBalance),
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
              height: 1.0,
              shadows: isNegative
                  ? null
                  : [
                const Shadow(
                  color: Colors.black26,
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroMiniStat(
                  label: 'Pendiente',
                  value: AppFormatters.money(remainingAmount),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroMiniStat(
                  label: 'Pagado',
                  value: AppFormatters.money(paidAmount),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMiniStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent),
            ),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardObligationCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool showPayAction;
  final VoidCallback? onPay;

  const _DashboardObligationCard({
    required this.item,
    required this.showPayAction,
    this.onPay,
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

  IconData _statusIcon(String status) {
    switch (status) {
      case 'paid':
        return Icons.check_circle_outline;
      case 'partial':
        return Icons.timelapse_outlined;
      case 'overdue':
        return Icons.warning_amber_outlined;
      case 'pending':
        return Icons.schedule_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = item['status']?.toString() ?? '';
    final color = _statusColor(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 5,
                  height: 54,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title']?.toString() ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vence: ${AppFormatters.date(item['due_date'])}',
                      ),
                      const SizedBox(height: 10),
                      AppStatusChip(
                        label: AppFormatters.obligationStatus(status),
                        color: color,
                        icon: _statusIcon(status),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppFormatters.money(
                    (item['amount_due'] as num?) ?? 0,
                    item['currency']?.toString() ?? 'PEN',
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            if (showPayAction) ...[
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onPay,
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Registrar pago'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}