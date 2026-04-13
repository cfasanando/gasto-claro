import 'package:flutter/material.dart';

import '../models/debt.dart';
import '../services/debt_service.dart';
import '../utils/app_formatters.dart';
import '../utils/app_validators.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_section_header.dart';
import '../widgets/app_status_chip.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_entity_card.dart';
import '../widgets/debt_form_sheet.dart';

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

  InputDecoration dialogInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar deuda'),
          content: Text('¿Deseas eliminar "${debt.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
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
                    child: AppEntityCard(
                      icon: Icons.account_balance_wallet_outlined,
                      accentColor: item.status == 'paid'
                          ? AppTokens.success
                          : item.status == 'suspended'
                          ? AppTokens.warning
                          : item.status == 'cancelled'
                          ? AppTokens.danger
                          : AppTokens.info,
                      eyebrow: 'Deuda',
                      title: item.name,
                      subtitle: item.creditorName?.trim().isNotEmpty == true
                          ? item.creditorName!
                          : translateDebtType(item.debtType),
                      trailing: AppFormatters.money(item.currentBalance, item.currency),
                      statusChip: AppStatusChip(
                        label: translateStatus(item.status),
                        color: statusColor(item.status),
                        icon: statusIcon(item.status),
                      ),
                      metadata: [
                        AppEntityMeta(
                          icon: Icons.label_outline,
                          label: translateDebtType(item.debtType),
                        ),
                        if (item.dueDay != null)
                          AppEntityMeta(
                            icon: Icons.calendar_today_outlined,
                            label: 'Vence día ${item.dueDay}',
                          ),
                        if (item.monthlyDueAmount != null)
                          AppEntityMeta(
                            icon: Icons.payments_outlined,
                            label:
                            'Cuota ${AppFormatters.money(item.monthlyDueAmount!, item.currency)}',
                          ),
                        if (item.minimumPayment != null)
                          AppEntityMeta(
                            icon: Icons.savings_outlined,
                            label:
                            'Mínimo ${AppFormatters.money(item.minimumPayment!, item.currency)}',
                          ),
                        if (item.hasFixedPayment)
                          const AppEntityMeta(
                            icon: Icons.repeat_outlined,
                            label: 'Pago fijo',
                          ),
                      ],
                      actions: [
                        OutlinedButton.icon(
                          onPressed: () => openEditDebtDialog(item),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Editar'),
                        ),
                        TextButton.icon(
                          onPressed: () => confirmDeleteDebt(item),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Eliminar'),
                        ),
                      ],
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