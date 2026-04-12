import 'package:flutter/material.dart';

import '../models/payment_obligation.dart';
import '../services/payment_obligation_service.dart';
import '../services/payment_record_service.dart';

class PaymentObligationsPage extends StatefulWidget {
  final int year;
  final int month;

  const PaymentObligationsPage({
    super.key,
    required this.year,
    required this.month,
  });

  @override
  State<PaymentObligationsPage> createState() => _PaymentObligationsPageState();
}

class _PaymentObligationsPageState extends State<PaymentObligationsPage> {
  late Future<List<PaymentObligation>> futureItems;
  final PaymentObligationService obligationService = PaymentObligationService();
  final PaymentRecordService paymentRecordService = PaymentRecordService();

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  @override
  void didUpdateWidget(covariant PaymentObligationsPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.year != widget.year || oldWidget.month != widget.month) {
      loadItems();
    }
  }

  void loadItems() {
    futureItems = obligationService.getMonthlyObligations(
      year: widget.year,
      month: widget.month,
    );
  }

  Future<void> reload() async {
    setState(() {
      loadItems();
    });
  }

  String formatMoney(double value) {
    return 'S/ ${value.toStringAsFixed(2)}';
  }

  String translateStatus(String status) {
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
        return status;
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }

    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  Future<void> syncMonthly() async {
    try {
      await obligationService.syncMonthly(
        year: widget.year,
        month: widget.month,
      );

      await reload();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Obligaciones del mes sincronizadas'),
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
    }
  }

  Future<void> registerPayment(PaymentObligation item) async {
    final amountController = TextEditingController(
      text: item.amountDue.toStringAsFixed(2),
    );
    String paymentMethod = 'bank_transfer';
    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Registrar pago: ${item.title}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Monto pagado',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: paymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Método de pago',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Efectivo')),
                        DropdownMenuItem(value: 'bank_transfer', child: Text('Transferencia')),
                        DropdownMenuItem(value: 'credit_card', child: Text('Tarjeta de crédito')),
                        DropdownMenuItem(value: 'debit_card', child: Text('Tarjeta de débito')),
                        DropdownMenuItem(value: 'yape', child: Text('Yape')),
                        DropdownMenuItem(value: 'plin', child: Text('Plin')),
                        DropdownMenuItem(value: 'other', child: Text('Otro')),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          paymentMethod = value ?? 'bank_transfer';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Nota',
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

    if (amount == null || amount <= 0) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un monto válido'),
        ),
      );

      return;
    }

    try {
      final now = DateTime.now();
      final paidAt =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await paymentRecordService.createPaymentRecord(
        paymentObligationId: item.id,
        paidAmount: amount,
        currency: item.currency,
        paidAt: paidAt,
        paymentMethod: paymentMethod,
        note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
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
    return FutureBuilder<List<PaymentObligation>>(
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
                    'No se pudieron cargar las obligaciones',
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
                      'Obligaciones del mes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: syncMonthly,
                    icon: const Icon(Icons.sync),
                    label: const Text('Sincronizar'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const Text('No hay obligaciones registradas para este mes.')
              else
                ...items.map(
                      (item) => Card(
                    child: ListTile(
                      title: Text(item.title),
                      subtitle: Text(
                        'Vence: ${formatDate(item.dueDate)}\n'
                            'Estado: ${translateStatus(item.status)}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            formatMoney(item.amountDue),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          if (item.status != 'paid' && item.status != 'cancelled')
                            GestureDetector(
                              onTap: () => registerPayment(item),
                              child: const Text(
                                'Pagar',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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