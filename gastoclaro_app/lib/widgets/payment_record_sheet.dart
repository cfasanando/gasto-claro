import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../utils/app_formatters.dart';
import 'app_modal_sheet.dart';

class PaymentRecordDraft {
  final double paidAmount;
  final String currency;
  final String paidAt;
  final String paymentMethod;
  final String? note;

  const PaymentRecordDraft({
    required this.paidAmount,
    required this.currency,
    required this.paidAt,
    required this.paymentMethod,
    required this.note,
  });
}

Future<PaymentRecordDraft?> showPaymentRecordSheet({
  required BuildContext context,
  required String title,
  required double amountDue,
  required String currency,
}) {
  return showAppModalSheet<PaymentRecordDraft>(
    context: context,
    builder: (_) => _PaymentRecordSheet(
      title: title,
      amountDue: amountDue,
      currency: currency,
    ),
  );
}

class _PaymentRecordSheet extends StatefulWidget {
  final String title;
  final double amountDue;
  final String currency;

  const _PaymentRecordSheet({
    required this.title,
    required this.amountDue,
    required this.currency,
  });

  @override
  State<_PaymentRecordSheet> createState() => _PaymentRecordSheetState();
}

class _PaymentRecordSheetState extends State<_PaymentRecordSheet> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  String paymentMethod = 'bank_transfer';
  String? amountError;

  static const List<_PaymentMethodOption> paymentOptions = [
    _PaymentMethodOption(
      value: 'cash',
      label: 'Efectivo',
      icon: Icons.payments_outlined,
    ),
    _PaymentMethodOption(
      value: 'bank_transfer',
      label: 'Transferencia',
      icon: Icons.account_balance_outlined,
    ),
    _PaymentMethodOption(
      value: 'credit_card',
      label: 'Crédito',
      icon: Icons.credit_card_outlined,
    ),
    _PaymentMethodOption(
      value: 'debit_card',
      label: 'Débito',
      icon: Icons.credit_score_outlined,
    ),
    _PaymentMethodOption(
      value: 'yape',
      label: 'Yape',
      icon: Icons.phone_android_outlined,
    ),
    _PaymentMethodOption(
      value: 'plin',
      label: 'Plin',
      icon: Icons.qr_code_2_outlined,
    ),
    _PaymentMethodOption(
      value: 'other',
      label: 'Otro',
      icon: Icons.more_horiz,
    ),
  ];

  @override
  void initState() {
    super.initState();
    amountController.text = widget.amountDue.toStringAsFixed(2);
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  String _todayYmd() {
    final now = DateTime.now();

    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _submit() {
    final amount = double.tryParse(amountController.text.trim());

    setState(() {
      amountError = null;
    });

    if (amount == null || amount <= 0) {
      setState(() {
        amountError = 'Ingresa un monto válido';
      });

      return;
    }

    Navigator.of(context).pop(
      PaymentRecordDraft(
        paidAmount: amount,
        currency: widget.currency,
        paidAt: _todayYmd(),
        paymentMethod: paymentMethod,
        note: noteController.text.trim().isEmpty
            ? null
            : noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mutedTextStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: AppTokens.ink500,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Registrar pago',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Monto pendiente: ${AppFormatters.money(widget.amountDue, widget.currency)}',
            style: mutedTextStyle,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Monto pagado',
              errorText: amountError,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Método de pago',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: paymentOptions.map((option) {
              final isSelected = paymentMethod == option.value;

              return ChoiceChip(
                avatar: Icon(
                  option.icon,
                  size: 18,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : AppTokens.ink500,
                ),
                label: Text(option.label),
                selected: isSelected,
                selectedColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.14),
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.26)
                      : Theme.of(context).dividerColor,
                ),
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : AppTokens.ink700,
                  fontWeight: FontWeight.w700,
                ),
                onSelected: (_) {
                  setState(() {
                    paymentMethod = option.value;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: noteController,
            minLines: 3,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Nota',
              hintText: 'Agrega un detalle opcional',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Se registrará con la fecha de hoy.',
            style: mutedTextStyle,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Guardar pago'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodOption {
  final String value;
  final String label;
  final IconData icon;

  const _PaymentMethodOption({
    required this.value,
    required this.label,
    required this.icon,
  });
}