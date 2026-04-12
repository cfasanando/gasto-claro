import 'package:flutter/material.dart';

import '../models/payment_record.dart';
import '../services/payment_record_service.dart';

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

  String formatMoney(double value) {
    return 'S/ ${value.toStringAsFixed(2)}';
  }

  String formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }

    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
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
              Text(
                'Pagos del mes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const Text('No hay pagos registrados para este mes.')
              else
                ...items.map(
                      (item) => Card(
                    child: ListTile(
                      title: Text(item.obligationTitle ?? 'Pago'),
                      subtitle: Text(
                        'Fecha: ${formatDate(item.paidAt)}\n'
                            'Método: ${translatePaymentMethod(item.paymentMethod)}',
                      ),
                      trailing: Text(
                        formatMoney(item.paidAmount),
                        style: const TextStyle(fontWeight: FontWeight.bold),
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