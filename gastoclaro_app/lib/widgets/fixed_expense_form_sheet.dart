import 'package:flutter/material.dart';

import '../models/fixed_expense.dart';
import '../theme/app_tokens.dart';
import '../utils/app_validators.dart';
import 'app_modal_sheet.dart';

class FixedExpenseFormDraft {
  final String name;
  final String? category;
  final double amount;
  final String currency;
  final int? dueDay;
  final String frequency;
  final bool isMandatory;
  final bool isActive;
  final String? notes;

  const FixedExpenseFormDraft({
    required this.name,
    required this.category,
    required this.amount,
    required this.currency,
    required this.dueDay,
    required this.frequency,
    required this.isMandatory,
    required this.isActive,
    required this.notes,
  });
}

Future<FixedExpenseFormDraft?> showFixedExpenseFormSheet({
  required BuildContext context,
  FixedExpense? existingExpense,
}) {
  return showAppModalSheet<FixedExpenseFormDraft>(
    context: context,
    builder: (_) => _FixedExpenseFormSheet(existingExpense: existingExpense),
  );
}

class _FixedExpenseFormSheet extends StatefulWidget {
  final FixedExpense? existingExpense;

  const _FixedExpenseFormSheet({
    required this.existingExpense,
  });

  @override
  State<_FixedExpenseFormSheet> createState() => _FixedExpenseFormSheetState();
}

class _FixedExpenseFormSheetState extends State<_FixedExpenseFormSheet> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController categoryController;
  late final TextEditingController amountController;
  late final TextEditingController dueDayController;
  late final TextEditingController notesController;

  late String currency;
  late String frequency;
  late bool isMandatory;
  late bool isActive;

  @override
  void initState() {
    super.initState();

    final existingExpense = widget.existingExpense;

    nameController = TextEditingController(
      text: existingExpense?.name ?? '',
    );
    categoryController = TextEditingController(
      text: existingExpense?.category ?? '',
    );
    amountController = TextEditingController(
      text: existingExpense?.amount.toStringAsFixed(2) ?? '',
    );
    dueDayController = TextEditingController(
      text: existingExpense?.dueDay?.toString() ?? '',
    );
    notesController = TextEditingController(
      text: existingExpense?.notes ?? '',
    );

    currency = existingExpense?.currency ?? 'PEN';
    frequency = existingExpense?.frequency ?? 'monthly';
    isMandatory = existingExpense?.isMandatory ?? true;
    isActive = existingExpense?.isActive ?? true;
  }

  @override
  void dispose() {
    nameController.dispose();
    categoryController.dispose();
    amountController.dispose();
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

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null) {
      return;
    }

    Navigator.of(context).pop(
      FixedExpenseFormDraft(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingExpense != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Editar gasto fijo' : 'Nuevo gasto fijo',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Organiza tus gastos recurrentes con más contexto y menos fricción.',
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
              controller: categoryController,
              decoration: inputDecoration('Categoría'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: inputDecoration('Monto'),
              validator: (value) => AppValidators.requiredPositiveNumber(
                value,
                label: 'El monto',
                allowZero: true,
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
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
              value: frequency,
              decoration: inputDecoration('Frecuencia'),
              items: const [
                DropdownMenuItem(
                  value: 'monthly',
                  child: Text('Mensual'),
                ),
                DropdownMenuItem(
                  value: 'weekly',
                  child: Text('Semanal'),
                ),
                DropdownMenuItem(
                  value: 'yearly',
                  child: Text('Anual'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  frequency = value ?? 'monthly';
                });
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Es obligatorio'),
              value: isMandatory,
              onChanged: (value) {
                setState(() {
                  isMandatory = value;
                });
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Está activo'),
              value: isActive,
              onChanged: (value) {
                setState(() {
                  isActive = value;
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