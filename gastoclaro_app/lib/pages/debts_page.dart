import 'package:flutter/material.dart';

import '../models/debt.dart';
import '../services/debt_service.dart';

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

  String formatMoney(double value, String currency) {
    final symbol = currency == 'USD' ? r'$' : 'S/';
    return '$symbol ${value.toStringAsFixed(2)}';
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

  Future<void> openCreateDebtDialog() async {
    await openDebtDialog();
  }

  Future<void> openEditDebtDialog(Debt debt) async {
    await openDebtDialog(existingDebt: debt);
  }

  Future<void> openDebtDialog({Debt? existingDebt}) async {
    final nameController = TextEditingController(text: existingDebt?.name ?? '');
    final creditorController = TextEditingController(
      text: existingDebt?.creditorName ?? '',
    );
    final originalAmountController = TextEditingController(
      text: existingDebt?.originalAmount?.toStringAsFixed(2) ?? '',
    );
    final currentBalanceController = TextEditingController(
      text: existingDebt?.currentBalance.toStringAsFixed(2) ?? '',
    );
    final monthlyDueController = TextEditingController(
      text: existingDebt?.monthlyDueAmount?.toStringAsFixed(2) ?? '',
    );
    final minimumPaymentController = TextEditingController(
      text: existingDebt?.minimumPayment?.toStringAsFixed(2) ?? '',
    );
    final interestRateController = TextEditingController(
      text: existingDebt?.interestRateMonthly?.toStringAsFixed(2) ?? '',
    );
    final dueDayController = TextEditingController(
      text: existingDebt?.dueDay?.toString() ?? '',
    );
    final notesController = TextEditingController(
      text: existingDebt?.notes ?? '',
    );

    String debtType = existingDebt?.debtType ?? 'credit_card';
    String currency = existingDebt?.currency ?? 'PEN';
    String status = existingDebt?.status ?? 'active';
    bool hasFixedPayment = existingDebt?.hasFixedPayment ?? true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                existingDebt == null ? 'Nueva deuda' : 'Editar deuda',
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
                      controller: creditorController,
                      decoration: const InputDecoration(
                        labelText: 'Entidad o acreedor',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: debtType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de deuda',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'credit_card',
                          child: Text('Tarjeta de crédito'),
                        ),
                        DropdownMenuItem(
                          value: 'bank_loan',
                          child: Text('Préstamo bancario'),
                        ),
                        DropdownMenuItem(
                          value: 'third_party_loan',
                          child: Text('Préstamo a tercero'),
                        ),
                        DropdownMenuItem(
                          value: 'store_credit',
                          child: Text('Crédito de tienda'),
                        ),
                        DropdownMenuItem(
                          value: 'recurring_commitment',
                          child: Text('Compromiso recurrente'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          debtType = value ?? 'credit_card';
                        });
                      },
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
                      controller: originalAmountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Monto original',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: currentBalanceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Saldo actual',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: monthlyDueController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Cuota mensual',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: minimumPaymentController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Pago mínimo',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: interestRateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Interés mensual (%)',
                      ),
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
                      value: status,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'active',
                          child: Text('Activa'),
                        ),
                        DropdownMenuItem(
                          value: 'paid',
                          child: Text('Pagada'),
                        ),
                        DropdownMenuItem(
                          value: 'suspended',
                          child: Text('Suspendida'),
                        ),
                        DropdownMenuItem(
                          value: 'cancelled',
                          child: Text('Cancelada'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          status = value ?? 'active';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Tiene pago fijo'),
                      value: hasFixedPayment,
                      onChanged: (value) {
                        setDialogState(() {
                          hasFixedPayment = value;
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

    final currentBalance = double.tryParse(currentBalanceController.text.trim());

    if (nameController.text.trim().isEmpty || currentBalance == null || currentBalance < 0) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa al menos nombre y saldo actual válido'),
        ),
      );

      return;
    }

    try {
      if (existingDebt == null) {
        await debtService.createDebt(
          debtType: debtType,
          name: nameController.text.trim(),
          creditorName: creditorController.text.trim().isEmpty
              ? null
              : creditorController.text.trim(),
          currency: currency,
          originalAmount: double.tryParse(originalAmountController.text.trim()),
          currentBalance: currentBalance,
          monthlyDueAmount: double.tryParse(monthlyDueController.text.trim()),
          minimumPayment: double.tryParse(minimumPaymentController.text.trim()),
          interestRateMonthly: double.tryParse(interestRateController.text.trim()),
          dueDay: int.tryParse(dueDayController.text.trim()),
          status: status,
          hasFixedPayment: hasFixedPayment,
          notes: notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
        );
      } else {
        await debtService.updateDebt(
          id: existingDebt.id,
          debtType: debtType,
          name: nameController.text.trim(),
          creditorName: creditorController.text.trim().isEmpty
              ? null
              : creditorController.text.trim(),
          currency: currency,
          originalAmount: double.tryParse(originalAmountController.text.trim()),
          currentBalance: currentBalance,
          monthlyDueAmount: double.tryParse(monthlyDueController.text.trim()),
          minimumPayment: double.tryParse(minimumPaymentController.text.trim()),
          interestRateMonthly: double.tryParse(interestRateController.text.trim()),
          dueDay: int.tryParse(dueDayController.text.trim()),
          status: status,
          hasFixedPayment: hasFixedPayment,
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Deudas registradas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: openCreateDebtDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const Text('No hay deudas registradas.')
              else
                ...items.map(
                      (item) => Card(
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                        '${translateDebtType(item.debtType)}\n'
                            'Estado: ${translateStatus(item.status)}\n'
                            'Vence día: ${item.dueDay ?? '-'}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatMoney(item.currentBalance, item.currency),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              if (item.monthlyDueAmount != null)
                                Text(
                                  'Cuota: ${formatMoney(item.monthlyDueAmount!, item.currency)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            tooltip: 'Acciones',
                            onSelected: (value) {
                              if (value == 'edit') {
                                openEditDebtDialog(item);
                              } else if (value == 'delete') {
                                confirmDeleteDebt(item);
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