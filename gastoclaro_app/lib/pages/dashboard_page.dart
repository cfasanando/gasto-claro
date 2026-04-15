import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/debt.dart';
import '../models/monthly_dashboard.dart';
import '../services/dashboard_service.dart';
import '../services/debt_service.dart';
import '../services/payment_obligation_service.dart';
import '../services/payment_record_service.dart';
import '../theme/app_tokens.dart';
import '../utils/app_formatters.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_section_header.dart';
import '../widgets/app_status_chip.dart';
import '../widgets/app_surface_card.dart';
import '../widgets/payment_record_sheet.dart';
import '../models/monthly_plan.dart';
import '../services/monthly_plan_service.dart';
import '../services/debt_focus_service.dart';

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
  late Future<_DashboardBundle> futureDashboard;
  final DashboardService dashboardService = DashboardService();
  final DebtService debtService = DebtService();
  final MonthlyPlanService monthlyPlanService = MonthlyPlanService();
  final DebtFocusService debtFocusService = DebtFocusService();
  final PaymentObligationService paymentObligationService =
  PaymentObligationService();
  final PaymentRecordService paymentRecordService = PaymentRecordService();

  int? manualFocusDebtId;
  bool isSyncing = false;

  @override
  void initState() {
    super.initState();
    loadDashboard();
    loadManualFocusDebt();
  }

  @override
  void didUpdateWidget(covariant DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.year != widget.year || oldWidget.month != widget.month) {
      loadDashboard();
    }
  }

  void loadDashboard() {
    futureDashboard = _loadDashboardData();
  }

  Future<void> loadManualFocusDebt() async {
    final savedDebtId = await debtFocusService.getFocusDebtId();

    if (!mounted) {
      return;
    }

    setState(() {
      manualFocusDebtId = savedDebtId;
    });
  }

  Debt? resolveDisplayedTargetDebt({
    required List<Debt> debts,
    required Debt? suggestedDebt,
  }) {
    if (manualFocusDebtId == null) {
      return suggestedDebt;
    }

    for (final debt in debts) {
      if (
      debt.id == manualFocusDebtId &&
          debt.status == 'active' &&
          debt.currentBalance > 0) {
        return debt;
      }
    }

    return suggestedDebt;
  }

  Future<void> saveManualFocusDebt(int debtId) async {
    await debtFocusService.setFocusDebtId(debtId);

    if (!mounted) {
      return;
    }

    setState(() {
      manualFocusDebtId = debtId;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Deuda objetivo guardada'),
      ),
    );
  }

  Future<void> clearManualFocusDebt() async {
    await debtFocusService.clearFocusDebtId();

    if (!mounted) {
      return;
    }

    setState(() {
      manualFocusDebtId = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Se volvió a la sugerencia automática'),
      ),
    );
  }

  Future<void> openDebtFocusPicker(List<Debt> debts) async {
    final activeDebts = debts
        .where((debt) => debt.status == 'active' && debt.currentBalance > 0)
        .toList();

    if (activeDebts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay deudas activas disponibles'),
        ),
      );
      return;
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final estimatedHeight = 220.0 + (activeDebts.length * 72.0);
    final sheetHeight = math.min(
      screenHeight * 0.72,
      math.max(estimatedHeight, 280.0),
    );

    final selectedDebtId = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);

        return Material(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
          child: SizedBox(
            height: sheetHeight,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Elegir deuda objetivo',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        tooltip: 'Cerrar',
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.auto_fix_high_outlined),
                  title: const Text('Usar sugerencia automática'),
                  subtitle: const Text(
                    'Dejar que el panel elija la deuda foco',
                  ),
                  onTap: () => Navigator.of(context).pop(-1),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: activeDebts.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final debt = activeDebts[index];
                      final isSelected = manualFocusDebtId == debt.id;

                      return ListTile(
                        leading: Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                        ),
                        title: Text(debt.name),
                        subtitle: Text(
                          '${debt.creditorName?.trim().isNotEmpty == true ? debt.creditorName! : 'Deuda activa'} · ${AppFormatters.money(debt.currentBalance, debt.currency)}',
                        ),
                        trailing: debt.dueDay != null
                            ? Text('Día ${debt.dueDay}')
                            : null,
                        onTap: () => Navigator.of(context).pop(debt.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedDebtId == null) {
      return;
    }

    if (selectedDebtId == -1) {
      await clearManualFocusDebt();
      return;
    }

    await saveManualFocusDebt(selectedDebtId);
  }

  Future<_DashboardBundle> _loadDashboardData() async {
    final dashboard = await dashboardService.getMonthlyDashboard(
      year: widget.year,
      month: widget.month,
    );

    List<Debt> debts = [];

    try {
      debts = await debtService.getDebts();
    } catch (_) {
      debts = [];
    }

    return _DashboardBundle(
      dashboard: dashboard,
      debts: debts,
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

  List<Map<String, dynamic>> buildUrgentItems(MonthlyDashboard dashboard) {
    final items = <Map<String, dynamic>>[];
    final seen = <String>{};

    void append(List<dynamic> rawItems) {
      for (final raw in rawItems) {
        final item = Map<String, dynamic>.from(raw as Map);
        final key =
            '${item['id'] ?? item['title']}-${item['due_date']}-${item['status']}';

        if (!seen.add(key)) {
          continue;
        }

        items.add(item);

        if (items.length >= 3) {
          break;
        }
      }
    }

    append(dashboard.attentionItems);

    if (items.length < 3) {
      append(dashboard.pendingItems);
    }

    return items.take(3).toList();
  }

  List<Map<String, dynamic>> buildRecentPaidItems(MonthlyDashboard dashboard) {
    return dashboard.paidItems
        .take(3)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<Debt> getActiveDebts(List<Debt> debts) {
    return debts
        .where((item) => item.status == 'active' && item.currentBalance > 0)
        .toList();
  }

  double estimatedMonthlyPayment(Debt debt) {
    if (debt.monthlyDueAmount != null && debt.monthlyDueAmount! > 0) {
      return debt.monthlyDueAmount!;
    }

    if (debt.minimumPayment != null && debt.minimumPayment! > 0) {
      return debt.minimumPayment!;
    }

    return 0;
  }

  int? estimatedMonthsLeft(Debt debt) {
    final payment = estimatedMonthlyPayment(debt);

    if (debt.status != 'active' || debt.currentBalance <= 0 || payment <= 0) {
      return null;
    }

    return math.max(1, (debt.currentBalance / payment).ceil());
  }

  double? progressRatio(Debt debt) {
    final original = debt.originalAmount;

    if (original == null || original <= 0) {
      return null;
    }

    final paidAmount = original - debt.currentBalance;
    final normalizedPaid = paidAmount < 0
        ? 0.0
        : paidAmount > original
        ? original
        : paidAmount;

    return normalizedPaid / original;
  }

  Debt? suggestedTargetDebt(List<Debt> debts) {
    final activeDebts = getActiveDebts(debts);

    if (activeDebts.isEmpty) {
      return null;
    }

    activeDebts.sort((a, b) {
      final balanceCompare = a.currentBalance.compareTo(b.currentBalance);

      if (balanceCompare != 0) {
        return balanceCompare;
      }

      return estimatedMonthlyPayment(b).compareTo(estimatedMonthlyPayment(a));
    });

    return activeDebts.first;
  }

  _MonthStateData buildMonthState(MonthlyDashboard dashboard) {
    final double pendingIncome = math.max(
      0.0,
      dashboard.expectedIncomeTotal - dashboard.receivedIncomeTotal,
    );

    if (dashboard.remainingObligationTotal <= 0 && dashboard.actualBalance >= 0) {
      return const _MonthStateData(
        label: 'Mes en control',
        description: 'Tu mes está cubierto y no hay obligaciones pendientes.',
        accent: AppTokens.success,
      );
    }

    if (dashboard.actualBalance < 0) {
      return const _MonthStateData(
        label: 'Mes en presión',
        description: 'Lo pendiente supera tu caja actual. Prioriza pagos críticos.',
        accent: AppTokens.danger,
      );
    }

    if (pendingIncome > 0 || dashboard.remainingObligationTotal > 0) {
      return const _MonthStateData(
        label: 'Mes ajustado',
        description: 'Todavía hay movimientos por recibir o cubrir este mes.',
        accent: AppTokens.warning,
      );
    }

    return const _MonthStateData(
      label: 'Mes activo',
      description: 'Tu mes sigue en movimiento, pero sin alertas graves.',
      accent: AppTokens.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardBundle>(
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

        final bundle = snapshot.data!;
        final dashboard = bundle.dashboard;
        final debts = bundle.debts;
        final monthlyPlan = monthlyPlanService.buildPlan(
          dashboard: dashboard,
          debts: debts,
        );
        final urgentItems = buildUrgentItems(dashboard);
        final recentPaidItems = buildRecentPaidItems(dashboard);
        final monthState = buildMonthState(dashboard);

        final suggestedDebt = monthlyPlan.focusDebt;
        final targetDebt = resolveDisplayedTargetDebt(
          debts: debts,
          suggestedDebt: suggestedDebt,
        );
        final isManualFocus = targetDebt != null && manualFocusDebtId == targetDebt.id;

        final targetDebtPayment =
        targetDebt != null ? estimatedMonthlyPayment(targetDebt) : 0.0;
        final targetDebtMonths =
        targetDebt != null ? estimatedMonthsLeft(targetDebt) : null;
        final targetDebtProgress =
        targetDebt != null ? progressRatio(targetDebt) : null;

        final double pendingIncome = math.max(
          0.0,
          dashboard.expectedIncomeTotal - dashboard.receivedIncomeTotal,
        );

        return RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _MonthStateCard(
                monthLabel: AppFormatters.monthYear(widget.year, widget.month),
                state: monthState,
                actualBalance: dashboard.actualBalance,
                receivedIncome: dashboard.receivedIncomeTotal,
                remainingAmount: dashboard.remainingObligationTotal,
                pendingIncome: pendingIncome,
              ),
              const SizedBox(height: 24),
              AppSectionHeader(
                title: 'Plan del mes',
                subtitle: 'Qué cubrir primero, qué esperar y qué puedes pausar',
              ),
              const SizedBox(height: 12),
              _MonthlyPlanCard(
                plan: monthlyPlan,
                displayFocusDebt: targetDebt,
              ),
              const SizedBox(height: 24),
              AppSectionHeader(
                title: 'Lo urgente',
                subtitle: 'Lo que conviene atender primero este mes',
                action: widget.onOpenObligations == null
                    ? null
                    : TextButton(
                  onPressed: widget.onOpenObligations,
                  child: const Text('Ver obligaciones'),
                ),
              ),
              const SizedBox(height: 12),
              if (urgentItems.isEmpty)
                const AppEmptyState(
                  icon: Icons.auto_awesome_outlined,
                  title: 'No hay urgencias ahora',
                  subtitle: 'Tus alertas del periodo están bajo control.',
                )
              else
                _UrgentAgendaCard(
                  items: urgentItems,
                  onPay: registerPaymentFromDashboard,
                ),
              const SizedBox(height: 24),
              AppSectionHeader(
                title: 'Deuda objetivo',
                subtitle: 'Tu foco actual para ir saliendo de la presión',
              ),
              const SizedBox(height: 12),
              _DebtFocusCard(
                debt: targetDebt,
                estimatedMonthlyPaymentValue: targetDebtPayment,
                estimatedMonthsLeftValue: targetDebtMonths,
                progressRatioValue: targetDebtProgress,
                isManualFocus: isManualFocus,
                onChangeFocus: () => openDebtFocusPicker(debts),
                onUseAutomaticFocus: isManualFocus ? clearManualFocusDebt : null,
              ),
              const SizedBox(height: 24),
              AppSectionHeader(
                title: 'Flujo del mes',
                subtitle: 'Lectura compacta del dinero que entra y sale',
              ),
              const SizedBox(height: 12),
              _FlowSummaryCard(
                expectedIncome: dashboard.expectedIncomeTotal,
                receivedIncome: dashboard.receivedIncomeTotal,
                paidAmount: dashboard.paidTotal,
                remainingAmount: dashboard.remainingObligationTotal,
              ),
              const SizedBox(height: 24),
              AppSectionHeader(
                title: 'Actividad reciente',
                subtitle: 'Lo último que ya quedó registrado',
                action: widget.onOpenPayments == null
                    ? null
                    : TextButton(
                  onPressed: widget.onOpenPayments,
                  child: const Text('Ver pagos'),
                ),
              ),
              const SizedBox(height: 12),
              if (recentPaidItems.isEmpty)
                const AppEmptyState(
                  icon: Icons.check_circle_outline,
                  title: 'Aún no hay pagos registrados',
                  subtitle: 'Cuando registres pagos recientes aparecerán aquí.',
                )
              else
                _RecentActivityCard(
                  items: recentPaidItems,
                ),
              const SizedBox(height: 24),
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
            ],
          ),
        );
      },
    );
  }
}

class _DashboardBundle {
  final MonthlyDashboard dashboard;
  final List<Debt> debts;

  const _DashboardBundle({
    required this.dashboard,
    required this.debts,
  });
}

class _MonthStateData {
  final String label;
  final String description;
  final Color accent;

  const _MonthStateData({
    required this.label,
    required this.description,
    required this.accent,
  });
}

class _MonthStateCard extends StatelessWidget {
  final String monthLabel;
  final _MonthStateData state;
  final double actualBalance;
  final double receivedIncome;
  final double remainingAmount;
  final double pendingIncome;

  const _MonthStateCard({
    required this.monthLabel,
    required this.state,
    required this.actualBalance,
    required this.receivedIncome,
    required this.remainingAmount,
    required this.pendingIncome,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(
            state.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppFormatters.money(actualBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            state.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroMiniStat(
                  label: 'Recibido',
                  value: AppFormatters.money(receivedIncome),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroMiniStat(
                  label: 'Pendiente',
                  value: AppFormatters.money(remainingAmount),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroMiniStat(
                  label: 'Por recibir',
                  value: AppFormatters.money(pendingIncome),
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

class _MonthlyPlanCard extends StatelessWidget {
  final MonthlyPlan plan;
  final Debt? displayFocusDebt;

  const _MonthlyPlanCard({
    required this.plan,
    required this.displayFocusDebt,
  });

  Color _pressureColor() {
    switch (plan.pressureLevel) {
      case 'critical':
        return AppTokens.danger;
      case 'tight':
        return AppTokens.warning;
      case 'stable':
        return AppTokens.info;
      case 'surplus':
        return AppTokens.success;
      default:
        return AppTokens.ink500;
    }
  }

  String _pressureLabel() {
    switch (plan.pressureLevel) {
      case 'critical':
        return 'Crítico';
      case 'tight':
        return 'Ajustado';
      case 'stable':
        return 'Estable';
      case 'surplus':
        return 'Con margen';
      default:
        return 'Normal';
    }
  }

  String _summaryText() {
    switch (plan.pressureLevel) {
      case 'critical':
        return 'Con lo ya recibido no cubres lo pendiente. Prioriza solo lo crítico.';
      case 'tight':
        return 'El mes puede cerrar ajustado. Cubre lo esencial antes de adelantar otros pagos.';
      case 'stable':
        return 'Tu mes está controlado, pero todavía con poco margen.';
      case 'surplus':
        return displayFocusDebt != null
            ? 'Si entra todo lo esperado, podrías adelantar ${displayFocusDebt!.name}.'
            : 'Si entra todo lo esperado, deberías cerrar el mes con margen positivo.';
      default:
        return 'Revisa tus prioridades del mes.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _summaryText(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final metricWidth = constraints.maxWidth >= 720
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: metricWidth,
                    child: _PlanMetric(
                      icon: Icons.account_balance_wallet_outlined,
                      accent: AppTokens.info,
                      label: 'Caja disponible hoy',
                      value: AppFormatters.money(plan.availableNow),
                    ),
                  ),
                  SizedBox(
                    width: metricWidth,
                    child: _PlanMetric(
                      icon: Icons.auto_graph_outlined,
                      accent: plan.projectedBalance < 0
                          ? AppTokens.danger
                          : AppTokens.success,
                      label: 'Cierre proyectado',
                      value: AppFormatters.money(plan.projectedBalance),
                    ),
                  ),
                  SizedBox(
                    width: metricWidth,
                    child: _PlanMetric(
                      icon: Icons.warning_amber_outlined,
                      accent: _pressureColor(),
                      label: 'Presión del mes',
                      value: _pressureLabel(),
                    ),
                  ),
                  SizedBox(
                    width: metricWidth,
                    child: _PlanMetric(
                      icon: Icons.flag_outlined,
                      accent: AppTokens.primary,
                      label: 'Deuda foco',
                      value: displayFocusDebt?.name ?? 'Sin foco',
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          _PlanBucketSection(
            title: 'Paga sí o sí',
            subtitle: 'Lo que no conviene dejar pasar',
            color: AppTokens.danger,
            items: plan.mustPay,
            emptyText: 'No hay pagos críticos en este momento.',
          ),
          const SizedBox(height: 16),
          _PlanBucketSection(
            title: 'Paga si entra extra',
            subtitle: 'Lo que puedes cubrir si mejora tu caja',
            color: AppTokens.warning,
            items: plan.payIfExtraIncome,
            emptyText: 'No hay pagos secundarios pendientes.',
          ),
          const SizedBox(height: 16),
          _PlanBucketSection(
            title: 'Pausa o negocia',
            subtitle: 'Lo que puedes reducir, postergar o renegociar',
            color: AppTokens.info,
            items: plan.canPause,
            emptyText: 'No se detectaron elementos pausables.',
          ),
        ],
      ),
    );
  }
}

class _PlanMetric extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String label;
  final String value;

  const _PlanMetric({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTokens.ink500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanBucketSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final List<Map<String, dynamic>> items;
  final String emptyText;

  const _PlanBucketSection({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.items,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final previewItems = items.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppStatusChip(
                label: title,
                color: color,
                icon: Icons.flag_outlined,
              ),
              const SizedBox(width: 10),
              Text(
                '${items.length}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTokens.ink500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTokens.ink500,
            ),
          ),
          const SizedBox(height: 12),
          if (previewItems.isEmpty)
            Text(
              emptyText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTokens.ink500,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ...previewItems.map(
                  (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PlanItemRow(item: item),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanItemRow extends StatelessWidget {
  final Map<String, dynamic> item;

  const _PlanItemRow({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final title = item['title']?.toString() ?? 'Obligación';
    final dueDate = AppFormatters.date(item['due_date']);
    final amount = AppFormatters.money(
      (item['amount_due'] as num?) ?? 0,
      item['currency']?.toString() ?? 'PEN',
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.chevron_right,
          size: 18,
          color: AppTokens.ink500,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTokens.ink900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Vence $dueDate',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTokens.ink500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          amount,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _UrgentAgendaCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Future<void> Function(Map<String, dynamic>) onPay;

  const _UrgentAgendaCard({
    required this.items,
    required this.onPay,
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
    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          for (int index = 0; index < items.length; index++) ...[
            _UrgentAgendaRow(
              item: items[index],
              statusColorValue: _statusColor(
                items[index]['status']?.toString() ?? '',
              ),
              statusIconValue: _statusIcon(
                items[index]['status']?.toString() ?? '',
              ),
              onPay: () => onPay(items[index]),
            ),
            if (index < items.length - 1) ...[
              const SizedBox(height: 14),
              Divider(
                height: 1,
                color: Theme.of(context).dividerColor,
              ),
              const SizedBox(height: 14),
            ],
          ],
        ],
      ),
    );
  }
}

class _UrgentAgendaRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color statusColorValue;
  final IconData statusIconValue;
  final VoidCallback onPay;

  const _UrgentAgendaRow({
    required this.item,
    required this.statusColorValue,
    required this.statusIconValue,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final status = item['status']?.toString() ?? '';
    final canPay = status != 'paid' && status != 'cancelled';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 5,
          height: 52,
          decoration: BoxDecoration(
            color: statusColorValue,
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Vence ${AppFormatters.date(item['due_date'])}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTokens.ink500,
                ),
              ),
              const SizedBox(height: 10),
              AppStatusChip(
                label: AppFormatters.obligationStatus(status),
                color: statusColorValue,
                icon: statusIconValue,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              AppFormatters.money(
                (item['amount_due'] as num?) ?? 0,
                item['currency']?.toString() ?? 'PEN',
              ),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            if (canPay) ...[
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: onPay,
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Pagar'),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _DebtFocusCard extends StatelessWidget {
  final Debt? debt;
  final double estimatedMonthlyPaymentValue;
  final int? estimatedMonthsLeftValue;
  final double? progressRatioValue;
  final bool isManualFocus;
  final VoidCallback? onChangeFocus;
  final VoidCallback? onUseAutomaticFocus;

  const _DebtFocusCard({
    required this.debt,
    required this.estimatedMonthlyPaymentValue,
    required this.estimatedMonthsLeftValue,
    required this.progressRatioValue,
    required this.isManualFocus,
    required this.onChangeFocus,
    required this.onUseAutomaticFocus,
  });

  @override
  Widget build(BuildContext context) {
    if (debt == null) {
      return const AppEmptyState(
        icon: Icons.flag_outlined,
        title: 'Aún no hay deuda objetivo',
        subtitle: 'Cuando registres deudas activas, aquí aparecerá tu foco actual.',
      );
    }

    final subtitle = debt!.creditorName?.trim().isNotEmpty == true
        ? debt!.creditorName!
        : 'Deuda activa';

    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTokens.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                ),
                child: const Icon(
                  Icons.flag_outlined,
                  color: AppTokens.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt!.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 21,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTokens.ink500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AppStatusChip(
                label: isManualFocus ? 'Foco manual' : 'Foco sugerido',
                color: isManualFocus ? AppTokens.info : AppTokens.primary,
                icon: Icons.flag_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _DebtFocusMetric(
                label: 'Saldo actual',
                value: AppFormatters.money(debt!.currentBalance, debt!.currency),
              ),
              _DebtFocusMetric(
                label: 'Pago base',
                value: estimatedMonthlyPaymentValue > 0
                    ? AppFormatters.money(
                  estimatedMonthlyPaymentValue,
                  debt!.currency,
                )
                    : 'Sin pago base',
              ),
              _DebtFocusMetric(
                label: 'Día de vencimiento',
                value: debt!.dueDay != null ? 'Día ${debt!.dueDay}' : 'Sin día',
              ),
              _DebtFocusMetric(
                label: 'Meses aprox.',
                value: estimatedMonthsLeftValue != null
                    ? '$estimatedMonthsLeftValue'
                    : 'Sin cálculo',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DebtProgressInline(
            debt: debt!,
            progressRatioValue: progressRatioValue,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: onChangeFocus,
                icon: const Icon(Icons.tune_outlined),
                label: const Text('Cambiar foco'),
              ),
              if (isManualFocus && onUseAutomaticFocus != null)
                TextButton.icon(
                  onPressed: onUseAutomaticFocus,
                  icon: const Icon(Icons.auto_fix_high_outlined),
                  label: const Text('Usar sugerencia automática'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DebtFocusMetric extends StatelessWidget {
  final String label;
  final String value;

  const _DebtFocusMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 148),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTokens.ink500,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtProgressInline extends StatelessWidget {
  final Debt debt;
  final double? progressRatioValue;

  const _DebtProgressInline({
    required this.debt,
    required this.progressRatioValue,
  });

  @override
  Widget build(BuildContext context) {
    if (progressRatioValue == null || debt.originalAmount == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTokens.surfaceMuted,
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          border: Border.all(
            color: Theme.of(context).dividerColor,
          ),
        ),
        child: Text(
          'Aún no hay monto inicial suficiente para mostrar progreso real de capital.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTokens.ink500,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final paidAmount = debt.originalAmount! - debt.currentBalance;
    final safePaidAmount = paidAmount < 0
        ? 0.0
        : paidAmount > debt.originalAmount!
        ? debt.originalAmount!
        : paidAmount;
    final percent = (progressRatioValue! * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progreso de capital',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTokens.ink500,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressRatioValue,
              minHeight: 8,
              backgroundColor: AppTokens.outline,
              valueColor:
              const AlwaysStoppedAnimation<Color>(AppTokens.primary),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$percent% pagado · ${AppFormatters.money(safePaidAmount, debt.currency)} de ${AppFormatters.money(debt.originalAmount!, debt.currency)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTokens.ink700,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowSummaryCard extends StatelessWidget {
  final double expectedIncome;
  final double receivedIncome;
  final double paidAmount;
  final double remainingAmount;

  const _FlowSummaryCard({
    required this.expectedIncome,
    required this.receivedIncome,
    required this.paidAmount,
    required this.remainingAmount,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metricWidth = constraints.maxWidth >= 720
              ? (constraints.maxWidth - 12) / 2
              : constraints.maxWidth;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: metricWidth,
                child: _FlowMetric(
                  icon: Icons.trending_up,
                  accent: AppTokens.success,
                  label: 'Ingreso esperado',
                  value: AppFormatters.money(expectedIncome),
                ),
              ),
              SizedBox(
                width: metricWidth,
                child: _FlowMetric(
                  icon: Icons.savings_outlined,
                  accent: AppTokens.info,
                  label: 'Ingreso recibido',
                  value: AppFormatters.money(receivedIncome),
                ),
              ),
              SizedBox(
                width: metricWidth,
                child: _FlowMetric(
                  icon: Icons.check_circle_outline,
                  accent: AppTokens.success,
                  label: 'Pagado',
                  value: AppFormatters.money(paidAmount),
                ),
              ),
              SizedBox(
                width: metricWidth,
                child: _FlowMetric(
                  icon: Icons.warning_amber_outlined,
                  accent: remainingAmount > 0
                      ? AppTokens.danger
                      : const Color(0xFF94A3B8),
                  label: 'Pendiente',
                  value: AppFormatters.money(remainingAmount),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FlowMetric extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String label;
  final String value;

  const _FlowMetric({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTokens.ink500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const _RecentActivityCard({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          for (int index = 0; index < items.length; index++) ...[
            _RecentActivityRow(item: items[index]),
            if (index < items.length - 1) ...[
              const SizedBox(height: 14),
              Divider(
                height: 1,
                color: Theme.of(context).dividerColor,
              ),
              const SizedBox(height: 14),
            ],
          ],
        ],
      ),
    );
  }
}

class _RecentActivityRow extends StatelessWidget {
  final Map<String, dynamic> item;

  const _RecentActivityRow({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final title = item['title']?.toString() ?? 'Pago';
    final dueDate = AppFormatters.date(item['due_date']);
    final amount = AppFormatters.money(
      (item['amount_due'] as num?) ?? 0,
      item['currency']?.toString() ?? 'PEN',
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTokens.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.check_circle_outline,
            color: AppTokens.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Registrado en el periodo · vence $dueDate',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTokens.ink500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          amount,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
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