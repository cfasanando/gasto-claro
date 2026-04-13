import 'package:flutter/material.dart';

import '../models/fixed_expense.dart';
import '../services/fixed_expense_service.dart';
import '../utils/app_formatters.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_section_header.dart';
import '../widgets/app_status_chip.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_entity_card.dart';
import '../widgets/fixed_expense_form_sheet.dart';

class FixedExpensesPage extends StatefulWidget {
  const FixedExpensesPage({super.key});

  @override
  State<FixedExpensesPage> createState() => _FixedExpensesPageState();
}

class _FixedExpensesPageState extends State<FixedExpensesPage> {
  late Future<List<FixedExpense>> futureItems;
  final FixedExpenseService fixedExpenseService = FixedExpenseService();

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  void loadItems() {
    futureItems = fixedExpenseService.getFixedExpenses();
  }

  Future<void> reload() async {
    setState(() {
      loadItems();
    });
  }

  String translateFrequency(String value) {
    switch (value) {
      case 'monthly':
        return 'Mensual';
      case 'weekly':
        return 'Semanal';
      case 'yearly':
        return 'Anual';
      default:
        return value;
    }
  }

  Future<void> openCreateFixedExpenseDialog() async {
    await openFixedExpenseDialog();
  }

  Future<void> openEditFixedExpenseDialog(FixedExpense expense) async {
    await openFixedExpenseDialog(existingExpense: expense);
  }

  Future<void> openFixedExpenseDialog({FixedExpense? existingExpense}) async {
    final draft = await showFixedExpenseFormSheet(
      context: context,
      existingExpense: existingExpense,
    );

    if (draft == null) {
      return;
    }

    try {
      if (existingExpense == null) {
        await fixedExpenseService.createFixedExpense(
          name: draft.name,
          category: draft.category,
          amount: draft.amount,
          currency: draft.currency,
          dueDay: draft.dueDay,
          frequency: draft.frequency,
          isMandatory: draft.isMandatory,
          isActive: draft.isActive,
          notes: draft.notes,
        );
      } else {
        await fixedExpenseService.updateFixedExpense(
          id: existingExpense.id,
          name: draft.name,
          category: draft.category,
          amount: draft.amount,
          currency: draft.currency,
          dueDay: draft.dueDay,
          frequency: draft.frequency,
          isMandatory: draft.isMandatory,
          isActive: draft.isActive,
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
            existingExpense == null
                ? 'Gasto fijo creado correctamente'
                : 'Gasto fijo actualizado correctamente',
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
            existingExpense == null
                ? 'No se pudo crear el gasto fijo: $e'
                : 'No se pudo actualizar el gasto fijo: $e',
          ),
        ),
      );
    }
  }

  Future<void> confirmDeleteFixedExpense(FixedExpense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar gasto fijo'),
          content: Text('¿Deseas eliminar "${expense.name}"?'),
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
      await fixedExpenseService.deleteFixedExpense(expense.id);
      await reload();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gasto fijo eliminado correctamente'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo eliminar el gasto fijo: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FixedExpense>>(
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
                    'No se pudieron cargar los gastos fijos',
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
                title: 'Gastos fijos registrados',
                subtitle: '${items.length} registrados',
                action: ElevatedButton.icon(
                  onPressed: openCreateFixedExpenseDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo'),
                ),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const AppEmptyState(
                  icon: Icons.home_work_outlined,
                  title: 'No hay gastos fijos registrados',
                  subtitle: 'Agrega un gasto fijo para usar mejor tu planificación.',
                )
              else
                ...items.map(
                      (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppEntityCard(
                      icon: Icons.home_work_outlined,
                      accentColor: item.isActive ? AppTokens.info : AppTokens.ink500,
                      eyebrow: 'Gasto fijo',
                      title: item.name,
                      subtitle: item.category ?? 'Sin categoría',
                      trailing: AppFormatters.money(item.amount, item.currency),
                      statusChip: AppStatusChip(
                        label: item.isActive ? 'Activo' : 'Inactivo',
                        color: item.isActive ? AppTokens.success : Colors.grey,
                        icon: item.isActive
                            ? Icons.check_circle_outline
                            : Icons.pause_circle_outline,
                      ),
                      metadata: [
                        AppEntityMeta(
                          icon: Icons.repeat_outlined,
                          label: translateFrequency(item.frequency),
                        ),
                        if ((item.dueDay ?? 0) > 0)
                          AppEntityMeta(
                            icon: Icons.calendar_today_outlined,
                            label: 'Día ${item.dueDay}',
                          ),
                        AppEntityMeta(
                          icon: item.isMandatory
                              ? Icons.priority_high_outlined
                              : Icons.low_priority_outlined,
                          label: item.isMandatory ? 'Obligatorio' : 'Opcional',
                        ),
                      ],
                      actions: [
                        OutlinedButton.icon(
                          onPressed: () => openEditFixedExpenseDialog(item),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Editar'),
                        ),
                        TextButton.icon(
                          onPressed: () => confirmDeleteFixedExpense(item),
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