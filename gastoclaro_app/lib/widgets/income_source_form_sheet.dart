import 'package:flutter/material.dart';

import '../models/income_source.dart';
import '../theme/app_tokens.dart';
import '../utils/app_validators.dart';
import 'app_modal_sheet.dart';

class IncomeSourceFormDraft {
  final String name;
  final String type;
  final double? defaultAmount;
  final String currency;
  final bool isActive;
  final String? notes;

  const IncomeSourceFormDraft({
    required this.name,
    required this.type,
    required this.defaultAmount,
    required this.currency,
    required this.isActive,
    required this.notes,
  });
}

Future<IncomeSourceFormDraft?> showIncomeSourceFormSheet({
  required BuildContext context,
  IncomeSource? existingSource,
}) {
  return showAppModalSheet<IncomeSourceFormDraft>(
    context: context,
    builder: (_) => _IncomeSourceFormSheet(existingSource: existingSource),
  );
}

class _IncomeSourceFormSheet extends StatefulWidget {
  final IncomeSource? existingSource;

  const _IncomeSourceFormSheet({
    required this.existingSource,
  });

  @override
  State<_IncomeSourceFormSheet> createState() => _IncomeSourceFormSheetState();
}

class _IncomeSourceFormSheetState extends State<_IncomeSourceFormSheet> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController defaultAmountController;
  late final TextEditingController notesController;

  late String type;
  late String currency;
  late bool isActive;

  @override
  void initState() {
    super.initState();

    final existingSource = widget.existingSource;

    nameController = TextEditingController(
      text: existingSource?.name ?? '',
    );
    defaultAmountController = TextEditingController(
      text: existingSource?.defaultAmount?.toStringAsFixed(2) ?? '',
    );
    notesController = TextEditingController(
      text: existingSource?.notes ?? '',
    );

    type = existingSource?.type ?? 'salary';
    currency = existingSource?.currency ?? 'PEN';
    isActive = existingSource?.isActive ?? true;
  }

  @override
  void dispose() {
    nameController.dispose();
    defaultAmountController.dispose();
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

    Navigator.of(context).pop(
      IncomeSourceFormDraft(
        name: nameController.text.trim(),
        type: type,
        defaultAmount: double.tryParse(defaultAmountController.text.trim()),
        currency: currency,
        isActive: isActive,
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingSource != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Editar fuente de ingreso' : 'Nueva fuente de ingreso',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Mantén ordenadas tus entradas de dinero y su comportamiento base.',
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
            DropdownButtonFormField<String>(
              value: type,
              decoration: inputDecoration('Tipo'),
              items: const [
                DropdownMenuItem(
                  value: 'salary',
                  child: Text('Sueldo'),
                ),
                DropdownMenuItem(
                  value: 'bonus',
                  child: Text('Bono / gratificación'),
                ),
                DropdownMenuItem(
                  value: 'freelance',
                  child: Text('Freelance'),
                ),
                DropdownMenuItem(
                  value: 'business',
                  child: Text('Negocio'),
                ),
                DropdownMenuItem(
                  value: 'investment',
                  child: Text('Inversión'),
                ),
                DropdownMenuItem(
                  value: 'family_support',
                  child: Text('Apoyo familiar'),
                ),
                DropdownMenuItem(
                  value: 'other',
                  child: Text('Otro'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  type = value ?? 'salary';
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: defaultAmountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: inputDecoration('Monto por defecto'),
              validator: (value) => AppValidators.optionalNumber(
                value,
                label: 'El monto por defecto',
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
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Está activa'),
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