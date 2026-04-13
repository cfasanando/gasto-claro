import 'package:flutter/material.dart';

import '../models/payment_obligation.dart';
import '../services/payment_obligation_service.dart';
import '../services/payment_record_service.dart';
import '../utils/app_formatters.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_section_header.dart';
import '../widgets/app_status_chip.dart';
import '../widgets/payment_record_sheet.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_entity_card.dart';

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
    final draft = await showPaymentRecordSheet(
      context: context,
      title: item.title,
      amountDue: item.amountDue,
      currency: item.currency,
    );

    if (draft == null) {
      return;
    }

    try {
      await paymentRecordService.createPaymentRecord(
        paymentObligationId: item.id,
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
                      (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppEntityCard(
                      icon: Icons.receipt_long_outlined,
                      accentColor: item.status == 'overdue'
                          ? AppTokens.danger
                          : item.status == 'paid'
                          ? AppTokens.success
                          : Theme.of(context).colorScheme.primary,
                      eyebrow: 'Obligación mensual',
                      title: item.title,
                      subtitle: 'Vence: ${AppFormatters.date(item.dueDate)}',
                      trailing: AppFormatters.money(item.amountDue, item.currency),
                      statusChip: AppStatusChip(
                        label: AppFormatters.obligationStatus(item.status),
                        color: statusColor(item.status),
                        icon: statusIcon(item.status),
                      ),
                      metadata: [
                        AppEntityMeta(
                          icon: Icons.event_outlined,
                          label: 'Periodo ${widget.month.toString().padLeft(2, '0')}/${widget.year}',
                        ),
                        AppEntityMeta(
                          icon: Icons.payments_outlined,
                          label: item.status == 'paid'
                              ? 'Pago completo'
                              : item.status == 'partial'
                              ? 'Pago parcial'
                              : 'Pendiente',
                        ),
                      ],
                      actions: [
                        if (item.status != 'paid' && item.status != 'cancelled')
                          FilledButton.icon(
                            onPressed: () => registerPayment(item),
                            icon: const Icon(Icons.payments_outlined),
                            label: const Text('Registrar pago'),
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