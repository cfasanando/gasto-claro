import 'package:flutter/material.dart';

import '../models/fixed_expense.dart';
import '../services/fixed_expense_service.dart';
import '../utils/app_formatters.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_section_header.dart';
import '../widgets/app_status_chip.dart';

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
    final nameController = TextEditingController(
      text: existingExpense?.name ?? '',
    );
    final categoryController = TextEditingController(
      text: existingExpense?.category ?? '',
    );
    final amountController = TextEditingController(
      text: existingExpense?.amount.toStringAsFixed(2) ?? '',
    );
    final dueDayController = TextEditingController(
      text: existingExpense?.dueDay?.toString() ?? '',
    );
    final notesController = TextEditingController(
      text: existingExpense?.notes ?? '',
    );

    String currency = existingExpense?.currency ?? 'PEN';
    String frequency = existingExpense?.frequency ?? 'monthly';
    bool isMandatory = existingExpense?.isMandatory ?? true;
    bool isActive = existingExpense?.isActive ?? true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                existingExpense == null
                    ? 'Nuevo gasto fijo'
                    : 'Editar gasto fijo',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Monto',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: currency,
                      decoration: const InputDecoration(
                        labelText: 'Moneda',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'PEN', child: Text('PEN')),
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          currency = value ?? 'PEN';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dueDayController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Día de vencimiento',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: frequency,
                      decoration: const InputDecoration(
                        labelText: 'Frecuencia',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'monthly',
                          child: Text('Mensual'),
                        ),
                        DropdownMenuItem(
                          value: 'weekly',
                          child: Text('Semanal'),
                        ),
                        DropdownMenuItem(
                          value: 'yearly',
                          child: Text('Anual'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          frequency = value ?? 'monthly';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Es obligatorio'),
                      value: isMandatory,
                      onChanged: (value) {
                        setDialogState(() {
                          isMandatory = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Está activo'),
                      value: isActive,
                      onChanged: (value) {
                        setDialogState(() {
                          isActive = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notas',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final amount = double.tryParse(amountController.text.trim());

    if (nameController.text.trim().isEmpty || amount == null || amount < 0) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa al menos nombre y monto válido'),
        ),
      );

      return;
    }

    try {
      if (existingExpense == null) {
        await fixedExpenseService.createFixedExpense(
          name: nameController.text.trim(),
          category: categoryController.text.trim().isEmpty
              ? null
              : categoryController.text.trim(),
          amount: amount,
          currency: currency,
          dueDay: int.tryParse(dueDayController.text.trim()),
          frequency: frequency,
          isMandatory: isMandatory,
          isActive: isActive,
          notes: notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
        );
      } else {
        await fixedExpenseService.updateFixedExpense(
          id: existingExpense.id,
          name: nameController.text.trim(),
          category: categoryController.text.trim().isEmpty
              ? null
              : categoryController.text.trim(),
          amount: amount,
          currency: currency,
          dueDay: int.tryParse(dueDayController.text.trim()),
          frequency: frequency,
          isMandatory: isMandatory,
          isActive: isActive,
          notes: notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
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
                      (item) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(item.category ?? 'Sin categoría'),
                                const SizedBox(height: 6),
                                Text('Frecuencia: ${translateFrequency(item.frequency)}'),
                                const SizedBox(height: 6),
                                Text('Vence día: ${item.dueDay ?? '-'}'),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    AppStatusChip(
                                      label: item.isActive ? 'Activo' : 'Inactivo',
                                      color: item.isActive ? Colors.green : Colors.grey,
                                      icon: item.isActive
                                          ? Icons.check_circle_outline
                                          : Icons.pause_circle_outline,
                                    ),
                                    AppStatusChip(
                                      label: item.isMandatory ? 'Obligatorio' : 'Opcional',
                                      color: item.isMandatory ? Colors.indigo : Colors.orange,
                                      icon: item.isMandatory
                                          ? Icons.priority_high_outlined
                                          : Icons.low_priority_outlined,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                AppFormatters.money(item.amount, item.currency),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              PopupMenuButton<String>(
                                tooltip: 'Acciones',
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    openEditFixedExpenseDialog(item);
                                  } else if (value == 'delete') {
                                    confirmDeleteFixedExpense(item);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 18),
                                        SizedBox(width: 8),
                                        Text('Editar'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline, size: 18),
                                        SizedBox(width: 8),
                                        Text('Eliminar'),
                                      ],
                                    ),
                                  ),
                                ],
                                icon: const Icon(Icons.more_vert),
                              ),
                            ],
                          ),
                        ],
                      ),
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