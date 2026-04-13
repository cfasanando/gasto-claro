import 'package:flutter/material.dart';

import '../models/debt.dart';
import '../theme/app_tokens.dart';
import '../utils/app_validators.dart';
import 'app_modal_sheet.dart';

class DebtFormDraft {
  final String debtType;
  final String name;
  final String? creditorName;
  final String currency;
  final double? originalAmount;
  final double currentBalance;
  final double? monthlyDueAmount;
  final double? minimumPayment;
  final double? interestRateMonthly;
  final int? dueDay;
  final String status;
  final bool hasFixedPayment;
  final String? notes;

  const DebtFormDraft({
    required this.debtType,
    required this.name,
    required this.creditorName,
    required this.currency,
    required this.originalAmount,
    required this.currentBalance,
    required this.monthlyDueAmount,
    required this.minimumPayment,
    required this.interestRateMonthly,
    required this.dueDay,
    required this.status,
    required this.hasFixedPayment,
    required this.notes,
  });
}

Future<DebtFormDraft?> showDebtFormSheet({
  required BuildContext context,
  Debt? existingDebt,
}) {
  return showAppModalSheet<DebtFormDraft>(
    context: context,
    builder: (_) => _DebtFormSheet(existingDebt: existingDebt),
  );
}

class _DebtFormSheet extends StatefulWidget {
  final Debt? existingDebt;

  const _DebtFormSheet({
    required this.existingDebt,
  });

  @override
  State<_DebtFormSheet> createState() => _DebtFormSheetState();
}

class _DebtFormSheetState extends State<_DebtFormSheet> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController creditorController;
  late final TextEditingController originalAmountController;
  late final TextEditingController currentBalanceController;
  late final TextEditingController monthlyDueController;
  late final TextEditingController minimumPaymentController;
  late final TextEditingController interestRateController;
  late final TextEditingController dueDayController;
  late final TextEditingController notesController;

  late String debtType;
  late String currency;
  late String status;
  late bool hasFixedPayment;

  @override
  void initState() {
    super.initState();

    final existingDebt = widget.existingDebt;

    nameController = TextEditingController(text: existingDebt?.name ?? '');
    creditorController = TextEditingController(
      text: existingDebt?.creditorName ?? '',
    );
    originalAmountController = TextEditingController(
      text: existingDebt?.originalAmount?.toStringAsFixed(2) ?? '',
    );
    currentBalanceController = TextEditingController(
      text: existingDebt?.currentBalance.toStringAsFixed(2) ?? '',
    );
    monthlyDueController = TextEditingController(
      text: existingDebt?.monthlyDueAmount?.toStringAsFixed(2) ?? '',
    );
    minimumPaymentController = TextEditingController(
      text: existingDebt?.minimumPayment?.toStringAsFixed(2) ?? '',
    );
    interestRateController = TextEditingController(
      text: existingDebt?.interestRateMonthly?.toStringAsFixed(2) ?? '',
    );
    dueDayController = TextEditingController(
      text: existingDebt?.dueDay?.toString() ?? '',
    );
    notesController = TextEditingController(
      text: existingDebt?.notes ?? '',
    );

    debtType = existingDebt?.debtType ?? 'credit_card';
    currency = existingDebt?.currency ?? 'PEN';
    status = existingDebt?.status ?? 'active';
    hasFixedPayment = existingDebt?.hasFixedPayment ?? true;
  }

  @override
  void dispose() {
    nameController.dispose();
    creditorController.dispose();
    originalAmountController.dispose();
    currentBalanceController.dispose();
    monthlyDueController.dispose();
    minimumPaymentController.dispose();
    interestRateController.dispose();
    dueDayController.dispose();
    notesController.dispose();
    super.dispose();
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(labelText: label);
  }

  void submit() {
    final isValid = formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final currentBalance = double.tryParse(currentBalanceController.text.trim());
    if (currentBalance == null) {
      return;
    }

    Navigator.of(context).pop(
      DebtFormDraft(
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
        interestRateMonthly:
        double.tryParse(interestRateController.text.trim()),
        dueDay: int.tryParse(dueDayController.text.trim()),
        status: status,
        hasFixedPayment: hasFixedPayment,
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingDebt != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Editar deuda' : 'Nueva deuda',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Mantén clara tu deuda, su estado y el compromiso mensual.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTokens.ink500,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: nameController,
              decoration: inputDecoration('Nombre'),
              validator: (value) => AppValidators.requiredText(
                value,
                label: 'El nombre',
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: creditorController,
              decoration: inputDecoration('Entidad o acreedor'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: debtType,
              decoration: inputDecoration('Tipo de deuda'),
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
                setState(() {
                  debtType = value ?? 'credit_card';
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: currency,
              decoration: inputDecoration('Moneda'),
              items: const [
                DropdownMenuItem(value: 'PEN', child: Text('PEN')),
                DropdownMenuItem(value: 'USD', child: Text('USD')),
              ],
              onChanged: (value) {
                setState(() {
                  currency = value ?? 'PEN';
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: originalAmountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: inputDecoration('Monto original'),
              validator: (value) => AppValidators.optionalNumber(
                value,
                label: 'El monto original',
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: currentBalanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: inputDecoration('Saldo actual'),
              validator: (value) => AppValidators.requiredPositiveNumber(
                value,
                label: 'El saldo actual',
                allowZero: true,
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: monthlyDueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: inputDecoration('Cuota mensual'),
              validator: (value) => AppValidators.optionalNumber(
                value,
                label: 'La cuota mensual',
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: minimumPaymentController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: inputDecoration('Pago mínimo'),
              validator: (value) => AppValidators.optionalNumber(
                value,
                label: 'El pago mínimo',
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: interestRateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: inputDecoration('Interés mensual (%)'),
              validator: (value) => AppValidators.optionalNumber(
                value,
                label: 'El interés mensual',
                allowZero: true,
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: dueDayController,
              keyboardType: TextInputType.number,
              decoration: inputDecoration('Día de vencimiento'),
              validator: (value) => AppValidators.optionalIntegerRange(
                value,
                label: 'El día de vencimiento',
                min: 1,
                max: 31,
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: status,
              decoration: inputDecoration('Estado'),
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
                setState(() {
                  status = value ?? 'active';
                });
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tiene pago fijo'),
              value: hasFixedPayment,
              onChanged: (value) {
                setState(() {
                  hasFixedPayment = value;
                });
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: notesController,
              decoration: inputDecoration('Notas'),
              maxLines: 2,
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
                    onPressed: submit,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}