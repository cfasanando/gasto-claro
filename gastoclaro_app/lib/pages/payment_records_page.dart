import 'package:flutter/material.dart';

import '../models/payment_record.dart';
import '../services/payment_record_service.dart';
import '../utils/app_formatters.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_section_header.dart';
import '../widgets/app_status_chip.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_entity_card.dart';
import '../widgets/app_page_state.dart';

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
          return const AppPageLoadingState(
            title: 'Cargando pagos',
            subtitle: 'Estamos trayendo los movimientos registrados del mes.',
          );
        }

        if (snapshot.hasError) {
          return AppPageErrorState(
            title: 'No se pudieron cargar los pagos',
            subtitle: snapshot.error.toString(),
            onRetry: reload,
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
                      (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppEntityCard(
                      icon: methodIcon(item.paymentMethod),
                      accentColor: methodColor(item.paymentMethod),
                      eyebrow: 'Pago registrado',
                      title: item.obligationTitle ?? 'Pago',
                      subtitle: item.note != null && item.note!.trim().isNotEmpty
                          ? item.note!
                          : 'Movimiento registrado correctamente.',
                      trailing: AppFormatters.money(item.paidAmount, item.currency),
                      statusChip: AppStatusChip(
                        label: translatePaymentMethod(item.paymentMethod),
                        color: methodColor(item.paymentMethod),
                        icon: methodIcon(item.paymentMethod),
                      ),
                      metadata: [
                        AppEntityMeta(
                          icon: Icons.event_outlined,
                          label: AppFormatters.date(item.paidAt),
                        ),
                        AppEntityMeta(
                          icon: Icons.currency_exchange_outlined,
                          label: item.currency,
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