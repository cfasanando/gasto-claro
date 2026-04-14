import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/debt.dart';
import '../services/debt_service.dart';
import '../utils/app_formatters.dart';
import '../widgets/app_destructive_action_sheet.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_entity_card.dart';
import '../widgets/app_section_header.dart';
import '../widgets/app_status_chip.dart';
import '../widgets/app_surface_card.dart';
import '../widgets/debt_form_sheet.dart';
import '../theme/app_tokens.dart';

class DebtsPage extends StatefulWidget {
  const DebtsPage({super.key});

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> {
  late Future<List<Debt>> futureItems;
  final DebtService debtService = DebtService();

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  void loadItems() {
    futureItems = debtService.getDebts();
  }

  Future<void> reload() async {
    setState(() {
      loadItems();
    });
  }

  String translateDebtType(String value) {
    switch (value) {
      case 'credit_card':
        return 'Tarjeta de crédito';
      case 'bank_loan':
        return 'Préstamo bancario';
      case 'third_party_loan':
        return 'Préstamo a tercero';
      case 'store_credit':
        return 'Crédito de tienda';
      case 'recurring_commitment':
        return 'Compromiso recurrente';
      default:
        return value;
    }
  }

  String translateStatus(String value) {
    switch (value) {
      case 'active':
        return 'Activa';
      case 'paid':
        return 'Pagada';
      case 'suspended':
        return 'Suspendida';
      case 'cancelled':
        return 'Cancelada';
      default:
        return value;
    }
  }

  Color statusColor(String value) {
    switch (value) {
      case 'active':
        return Colors.blueGrey;
      case 'paid':
        return Colors.green;
      case 'suspended':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData statusIcon(String value) {
    switch (value) {
      case 'active':
        return Icons.account_balance_wallet_outlined;
      case 'paid':
        return Icons.check_circle_outline;
      case 'suspended':
        return Icons.pause_circle_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
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

  Future<void> openCreateDebtDialog() async {
    await openDebtDialog();
  }

  Future<void> openEditDebtDialog(Debt debt) async {
    await openDebtDialog(existingDebt: debt);
  }

  Future<void> openDebtDialog({Debt? existingDebt}) async {
    final draft = await showDebtFormSheet(
      context: context,
      existingDebt: existingDebt,
    );

    if (draft == null) {
      return;
    }

    try {
      if (existingDebt == null) {
        await debtService.createDebt(
          debtType: draft.debtType,
          name: draft.name,
          creditorName: draft.creditorName,
          currency: draft.currency,
          originalAmount: draft.originalAmount,
          currentBalance: draft.currentBalance,
          monthlyDueAmount: draft.monthlyDueAmount,
          minimumPayment: draft.minimumPayment,
          interestRateMonthly: draft.interestRateMonthly,
          dueDay: draft.dueDay,
          status: draft.status,
          hasFixedPayment: draft.hasFixedPayment,
          notes: draft.notes,
        );
      } else {
        await debtService.updateDebt(
          id: existingDebt.id,
          debtType: draft.debtType,
          name: draft.name,
          creditorName: draft.creditorName,
          currency: draft.currency,
          originalAmount: draft.originalAmount,
          currentBalance: draft.currentBalance,
          monthlyDueAmount: draft.monthlyDueAmount,
          minimumPayment: draft.minimumPayment,
          interestRateMonthly: draft.interestRateMonthly,
          dueDay: draft.dueDay,
          status: draft.status,
          hasFixedPayment: draft.hasFixedPayment,
          notes: draft.notes,
        );
      }

      await reload();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existingDebt == null
                ? 'Deuda creada correctamente'
                : 'Deuda actualizada correctamente',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existingDebt == null
                ? 'No se pudo crear la deuda: $e'
                : 'No se pudo actualizar la deuda: $e',
          ),
        ),
      );
    }
  }

  Future<void> confirmDeleteDebt(Debt debt) async {
    final confirmed = await showDestructiveActionSheet(
      context: context,
      title: 'Eliminar deuda',
      message: '¿Deseas eliminar "${debt.name}"?',
      confirmLabel: 'Eliminar',
      icon: Icons.account_balance_wallet_outlined,
    );

    if (confirmed != true) {
      return;
    }

    try {
      await debtService.deleteDebt(debt.id);
      await reload();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deuda eliminada correctamente'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo eliminar la deuda: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Debt>>(
      future: futureItems,
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
                    'No se pudieron cargar las deudas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
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

        final items = snapshot.data ?? [];
        final activeDebts = getActiveDebts(items);
        final totalPending = activeDebts.fold<double>(
          0,
              (sum, item) => sum + item.currentBalance,
        );
        final totalMonthlyCommitment = activeDebts.fold<double>(
          0,
              (sum, item) => sum + estimatedMonthlyPayment(item),
        );
        final targetDebt = suggestedTargetDebt(items);
        final targetMonths =
        targetDebt != null ? estimatedMonthsLeft(targetDebt) : null;

        return RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppSectionHeader(
                title: 'Deudas registradas',
                subtitle: '${items.length} registradas',
                action: ElevatedButton.icon(
                  onPressed: openCreateDebtDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva'),
                ),
              ),
              const SizedBox(height: 16),
              if (items.isNotEmpty) ...[
                _DebtCompactSummary(
                  totalPending: totalPending,
                  totalMonthlyCommitment: totalMonthlyCommitment,
                  activeDebtCount: activeDebts.length,
                  targetDebtName: targetDebt?.name,
                  targetDebtBalance: targetDebt?.currentBalance,
                  targetDebtCurrency: targetDebt?.currency ?? 'PEN',
                  targetDebtMonths: targetMonths,
                ),
                const SizedBox(height: 16),
              ],
              if (items.isEmpty)
                const AppEmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'No hay deudas registradas',
                  subtitle: 'Agrega una deuda para comenzar a planificar pagos.',
                )
              else
                ...items.map(
                      (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DebtGoalCard(
                      debt: item,
                      debtTypeLabel: translateDebtType(item.debtType),
                      statusLabel: translateStatus(item.status),
                      statusColorValue: statusColor(item.status),
                      statusIconValue: statusIcon(item.status),
                      estimatedMonthlyPaymentValue: estimatedMonthlyPayment(item),
                      estimatedMonthsLeftValue: estimatedMonthsLeft(item),
                      progressRatioValue: progressRatio(item),
                      isSuggestedTarget: targetDebt?.id == item.id,
                      onEdit: () => openEditDebtDialog(item),
                      onDelete: () => confirmDeleteDebt(item),
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

class _DebtCompactSummary extends StatelessWidget {
  final double totalPending;
  final double totalMonthlyCommitment;
  final int activeDebtCount;
  final String? targetDebtName;
  final double? targetDebtBalance;
  final String targetDebtCurrency;
  final int? targetDebtMonths;

  const _DebtCompactSummary({
    required this.totalPending,
    required this.totalMonthlyCommitment,
    required this.activeDebtCount,
    required this.targetDebtName,
    required this.targetDebtBalance,
    required this.targetDebtCurrency,
    required this.targetDebtMonths,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plan de salida',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Vista compacta para enfocarte en cuánto falta y qué atacar primero.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTokens.ink500,
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
                    child: _DebtSummaryMetric(
                      icon: Icons.account_balance_wallet_outlined,
                      accent: AppTokens.danger,
                      label: 'Saldo total pendiente',
                      value: AppFormatters.money(totalPending),
                    ),
                  ),
                  SizedBox(
                    width: metricWidth,
                    child: _DebtSummaryMetric(
                      icon: Icons.payments_outlined,
                      accent: AppTokens.info,
                      label: 'Compromiso mensual base',
                      value: AppFormatters.money(totalMonthlyCommitment),
                    ),
                  ),
                  SizedBox(
                    width: metricWidth,
                    child: _DebtSummaryMetric(
                      icon: Icons.flag_outlined,
                      accent: AppTokens.primary,
                      label: 'Deuda objetivo sugerida',
                      value: targetDebtName ?? 'Sin sugerencia',
                      helper: targetDebtBalance != null
                          ? AppFormatters.money(
                        targetDebtBalance!,
                        targetDebtCurrency,
                      )
                          : 'No hay deudas activas',
                    ),
                  ),
                  SizedBox(
                    width: metricWidth,
                    child: _DebtSummaryMetric(
                      icon: Icons.schedule_outlined,
                      accent: AppTokens.success,
                      label: 'Salida estimada de la objetivo',
                      value: targetDebtMonths != null
                          ? '$targetDebtMonths meses aprox'
                          : 'Sin estimación',
                      helper: '$activeDebtCount deuda(s) activa(s)',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DebtSummaryMetric extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String label;
  final String value;
  final String? helper;

  const _DebtSummaryMetric({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
    this.helper,
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                if (helper != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    helper!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTokens.ink500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtGoalCard extends StatelessWidget {
  final Debt debt;
  final String debtTypeLabel;
  final String statusLabel;
  final Color statusColorValue;
  final IconData statusIconValue;
  final double estimatedMonthlyPaymentValue;
  final int? estimatedMonthsLeftValue;
  final double? progressRatioValue;
  final bool isSuggestedTarget;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DebtGoalCard({
    required this.debt,
    required this.debtTypeLabel,
    required this.statusLabel,
    required this.statusColorValue,
    required this.statusIconValue,
    required this.estimatedMonthlyPaymentValue,
    required this.estimatedMonthsLeftValue,
    required this.progressRatioValue,
    required this.isSuggestedTarget,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = debt.status == 'paid'
        ? AppTokens.success
        : debt.status == 'suspended'
        ? AppTokens.warning
        : debt.status == 'cancelled'
        ? AppTokens.danger
        : AppTokens.info;

    final subtitle = debt.creditorName?.trim().isNotEmpty == true
        ? debt.creditorName!
        : debtTypeLabel;

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
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Saldo pendiente',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTokens.ink500,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.money(debt.currentBalance, debt.currency),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AppStatusChip(
                label: statusLabel,
                color: statusColorValue,
                icon: statusIconValue,
              ),
              if (isSuggestedTarget)
                const AppStatusChip(
                  label: 'Objetivo sugerido',
                  color: AppTokens.primary,
                  icon: Icons.flag_outlined,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AppEntityMeta(
                icon: Icons.label_outline,
                label: debtTypeLabel,
              ),
              if (debt.dueDay != null)
                AppEntityMeta(
                  icon: Icons.calendar_today_outlined,
                  label: 'Vence día ${debt.dueDay}',
                ),
              if (estimatedMonthlyPaymentValue > 0)
                AppEntityMeta(
                  icon: Icons.payments_outlined,
                  label:
                  'Base ${AppFormatters.money(estimatedMonthlyPaymentValue, debt.currency)}',
                ),
              if (estimatedMonthsLeftValue != null)
                AppEntityMeta(
                  icon: Icons.schedule_outlined,
                  label: '$estimatedMonthsLeftValue meses aprox',
                ),
              if (debt.minimumPayment != null)
                AppEntityMeta(
                  icon: Icons.savings_outlined,
                  label:
                  'Mínimo ${AppFormatters.money(debt.minimumPayment!, debt.currency)}',
                ),
              if (debt.hasFixedPayment)
                const AppEntityMeta(
                  icon: Icons.repeat_outlined,
                  label: 'Pago fijo',
                ),
            ],
          ),
          const SizedBox(height: 16),
          _DebtProgressBlock(
            originalAmount: debt.originalAmount,
            currentBalance: debt.currentBalance,
            currency: debt.currency,
            progressRatio: progressRatioValue,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar'),
              ),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Eliminar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DebtProgressBlock extends StatelessWidget {
  final double? originalAmount;
  final double currentBalance;
  final String currency;
  final double? progressRatio;

  const _DebtProgressBlock({
    required this.originalAmount,
    required this.currentBalance,
    required this.currency,
    required this.progressRatio,
  });

  @override
  Widget build(BuildContext context) {
    if (progressRatio == null || originalAmount == null || originalAmount! <= 0) {
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
          'Aún no hay monto inicial suficiente para mostrar progreso real de cancelación.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTokens.ink500,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final paidAmount = originalAmount! - currentBalance;
    final safePaidAmount = paidAmount < 0
        ? 0.0
        : paidAmount > originalAmount!
        ? originalAmount!
        : paidAmount;

    final percent = (progressRatio! * 100).round();

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
            'Progreso aproximado',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTokens.ink500,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressRatio,
              minHeight: 8,
              backgroundColor: AppTokens.outline,
              valueColor:
              const AlwaysStoppedAnimation<Color>(AppTokens.primary),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$percent% pagado · ${AppFormatters.money(safePaidAmount, currency)} abonado de ${AppFormatters.money(originalAmount!, currency)}',
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