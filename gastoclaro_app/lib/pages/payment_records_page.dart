import 'package:flutter/material.dart';

import '../models/payment_record.dart';
import '../services/payment_record_service.dart';
import '../utils/app_formatters.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_section_header.dart';
import '../widgets/app_status_chip.dart';

class PaymentRecordsPage extends StatefulWidget {
  final int year;
  final int month;

  const PaymentRecordsPage({
    super.key,
    required this.year,
    required this.month,
  });

  @override
  State<PaymentRecordsPage> createState() => _PaymentRecordsPageState();
}

class _PaymentRecordsPageState extends State<PaymentRecordsPage> {
  late Future<List<PaymentRecord>> futureItems;
  final PaymentRecordService paymentRecordService = PaymentRecordService();

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  @override
  void didUpdateWidget(covariant PaymentRecordsPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.year != widget.year || oldWidget.month != widget.month) {
      loadItems();
    }
  }

  void loadItems() {
    futureItems = paymentRecordService.getMonthlyRecords(
      year: widget.year,
      month: widget.month,
    );
  }

  Future<void> reload() async {
    setState(() {
      loadItems();
    });
  }

  String translatePaymentMethod(String value) {
    switch (value) {
      case 'cash':
        return 'Efectivo';
      case 'bank_transfer':
        return 'Transferencia';
      case 'credit_card':
        return 'Tarjeta de crédito';
      case 'debit_card':
        return 'Tarjeta de débito';
      case 'yape':
        return 'Yape';
      case 'plin':
        return 'Plin';
      case 'other':
        return 'Otro';
      default:
        return value;
    }
  }

  Color methodColor(String value) {
    switch (value) {
      case 'cash':
        return Colors.green;
      case 'bank_transfer':
        return Colors.blue;
      case 'credit_card':
        return Colors.deepPurple;
      case 'debit_card':
        return Colors.indigo;
      case 'yape':
        return Colors.purple;
      case 'plin':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData methodIcon(String value) {
    switch (value) {
      case 'cash':
        return Icons.payments_outlined;
      case 'bank_transfer':
        return Icons.account_balance_outlined;
      case 'credit_card':
        return Icons.credit_card_outlined;
      case 'debit_card':
        return Icons.wallet_outlined;
      case 'yape':
      case 'plin':
        return Icons.phone_android_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PaymentRecord>>(
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
                    'No se pudieron cargar los pagos',
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
                title: 'Pagos del mes',
                subtitle: '${items.length} registrados',
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const AppEmptyState(
                  icon: Icons.payments_outlined,
                  title: 'No hay pagos registrados para este mes',
                  subtitle: 'Registra pagos desde el panel o desde obligaciones.',
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
                                      item.obligationTitle ?? 'Pago',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Fecha: ${AppFormatters.date(item.paidAt)}',
                                    ),
                                    const SizedBox(height: 8),
                                    AppStatusChip(
                                      label: translatePaymentMethod(item.paymentMethod),
                                      color: methodColor(item.paymentMethod),
                                      icon: methodIcon(item.paymentMethod),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                AppFormatters.money(item.paidAmount, item.currency),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          if (item.note != null && item.note!.trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                item.note!,
                                style: Theme.of(context).textTheme.bodySmall,
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