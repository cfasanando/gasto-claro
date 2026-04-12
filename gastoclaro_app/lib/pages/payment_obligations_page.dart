import 'package:flutter/material.dart';

import '../models/payment_obligation.dart';
import '../services/payment_obligation_service.dart';
import '../services/payment_record_service.dart';
import '../utils/app_formatters.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_section_header.dart';
import '../widgets/app_status_chip.dart';

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

  bool isSyncing = false;

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

  Color statusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      case 'pending':
        return Colors.blueGrey;
      case 'overdue':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData statusIcon(String status) {
    switch (status) {
      case 'paid':
        return Icons.check_circle_outline;
      case 'partial':
        return Icons.timelapse_outlined;
      case 'pending':
        return Icons.schedule_outlined;
      case 'overdue':
        return Icons.warning_amber_outlined;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Future<void> syncMonthly() async {
    if (isSyncing) {
      return;
    }

    setState(() {
      isSyncing = true;
    });

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
    } finally {
      if (mounted) {
        setState(() {
          isSyncing = false;
        });
      }
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
              AppSectionHeader(
                title: 'Obligaciones del mes',
                subtitle: '${items.length} registradas',
                action: ElevatedButton.icon(
                  onPressed: isSyncing ? null : syncMonthly,
                  icon: isSyncing
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.sync),
                  label: Text(isSyncing ? 'Sincronizando...' : 'Sincronizar'),
                ),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const AppEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No hay obligaciones registradas para este mes',
                  subtitle: 'Sincroniza el mes o crea datos base para comenzar.',
                )
              else
                ...items.map(
                      (item) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Vence: ${AppFormatters.date(item.dueDate)}',
                                    ),
                                    const SizedBox(height: 8),
                                    AppStatusChip(
                                      label: AppFormatters.obligationStatus(item.status),
                                      color: statusColor(item.status),
                                      icon: statusIcon(item.status),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                AppFormatters.money(item.amountDue, item.currency),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          if (item.status != 'paid' && item.status != 'cancelled') ...[
                            const SizedBox(height: 14),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.icon(
                                onPressed: () => registerPayment(item),
                                icon: const Icon(Icons.payments_outlined),
                                label: const Text('Pagar'),
                              ),
                            ),
                          ],
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