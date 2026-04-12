import 'package:flutter/material.dart';

import '../models/fixed_expense.dart';
import '../services/fixed_expense_service.dart';

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

  String formatMoney(double value, String currency) {
    final symbol = currency == 'USD' ? r'$' : 'S/';
    return '$symbol ${value.toStringAsFixed(2)}';
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

  String translateState(bool isActive) {
    return isActive ? 'Activo' : 'Inactivo';
  }

  Future<void> openCreateFixedExpenseDialog() async {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final amountController = TextEditingController();
    final dueDayController = TextEditingController();
    final notesController = TextEditingController();

    String currency = 'PEN';
    String frequency = 'monthly';
    bool isMandatory = true;
    bool isActive = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nuevo gasto fijo'),
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                        DropdownMenuItem(value: 'monthly', child: Text('Mensual')),
                        DropdownMenuItem(value: 'weekly', child: Text('Semanal')),
                        DropdownMenuItem(value: 'yearly', child: Text('Anual')),
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

      await reload();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gasto fijo creado correctamente'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo crear el gasto fijo: $e'),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Gastos fijos registrados',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: openCreateFixedExpenseDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const Text('No hay gastos fijos registrados.')
              else
                ...items.map(
                      (item) => Card(
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                        '${item.category ?? 'Sin categoría'}\n'
                            'Frecuencia: ${translateFrequency(item.frequency)}\n'
                            'Estado: ${translateState(item.isActive)}\n'
                            'Vence día: ${item.dueDay ?? '-'}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatMoney(item.amount, item.currency),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            item.isMandatory ? 'Obligatorio' : 'Opcional',
                            style: const TextStyle(fontSize: 12),
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