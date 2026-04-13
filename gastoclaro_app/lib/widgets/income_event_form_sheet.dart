import 'package:flutter/material.dart';

import '../models/income_event.dart';
import '../models/income_source.dart';
import '../theme/app_tokens.dart';
import '../utils/app_formatters.dart';
import '../utils/app_validators.dart';
import 'app_modal_sheet.dart';

class IncomeEventFormDraft {
  final int? incomeSourceId;
  final String title;
  final double amount;
  final String currency;
  final String expectedDate;
  final String? receivedDate;
  final String status;
  final String? notes;

  const IncomeEventFormDraft({
    required this.incomeSourceId,
    required this.title,
    required this.amount,
    required this.currency,
    required this.expectedDate,
    required this.receivedDate,
    required this.status,
    required this.notes,
  });
}

Future<IncomeEventFormDraft?> showIncomeEventFormSheet({
  required BuildContext context,
  required List<IncomeSource> sources,
  required int year,
  required int month,
  IncomeEvent? existingEvent,
}) {
  return showAppModalSheet<IncomeEventFormDraft>(
    context: context,
    builder: (_) => _IncomeEventFormSheet(
      sources: sources,
      year: year,
      month: month,
      existingEvent: existingEvent,
    ),
  );
}

class _IncomeEventFormSheet extends StatefulWidget {
  final List<IncomeSource> sources;
  final int year;
  final int month;
  final IncomeEvent? existingEvent;

  const _IncomeEventFormSheet({
    required this.sources,
    required this.year,
    required this.month,
    required this.existingEvent,
  });

  @override
  State<_IncomeEventFormSheet> createState() => _IncomeEventFormSheetState();
}

class _IncomeEventFormSheetState extends State<_IncomeEventFormSheet> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController titleController;
  late final TextEditingController amountController;
  late final TextEditingController expectedDateController;
  late final TextEditingController receivedDateController;
  late final TextEditingController notesController;

  late String currency;
  late String status;
  int? selectedIncomeSourceId;

  String defaultExpectedDate() {
    final month = widget.month.toString().padLeft(2, '0');
    return '${widget.year}-$month-01';
  }

  @override
  void initState() {
    super.initState();

    final existingEvent = widget.existingEvent;

    titleController = TextEditingController(
      text: existingEvent?.title ?? '',
    );
    amountController = TextEditingController(
      text: existingEvent?.amount.toStringAsFixed(2) ?? '',
    );
    expectedDateController = TextEditingController(
      text: existingEvent?.expectedDate != null
          ? AppFormatters.date(existingEvent!.expectedDate)
          : defaultExpectedDate(),
    );
    receivedDateController = TextEditingController(
      text: existingEvent?.receivedDate != null
          ? AppFormatters.date(existingEvent!.receivedDate)
          : '',
    );
    notesController = TextEditingController(
      text: existingEvent?.notes ?? '',
    );

    currency = existingEvent?.currency ?? 'PEN';
    status = existingEvent?.status ?? 'planned';
    selectedIncomeSourceId = existingEvent?.incomeSourceId;
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    expectedDateController.dispose();
    receivedDateController.dispose();
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
      IncomeEventFormDraft(
        incomeSourceId: selectedIncomeSourceId,
        title: titleController.text.trim(),
        amount: amount,
        currency: currency,
        expectedDate: expectedDateController.text.trim(),
        receivedDate: receivedDateController.text.trim().isEmpty
            ? null
            : receivedDateController.text.trim(),
        status: status,
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingEvent != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Editar evento de ingreso' : 'Nuevo evento de ingreso',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Registra ingresos esperados y recibidos sin salir del flujo mensual.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTokens.ink500,
              ),
            ),
            const SizedBox(height: 20),
            if (widget.sources.isNotEmpty) ...[
              DropdownButtonFormField<int?>(
                value: selectedIncomeSourceId,
                decoration: inputDecoration('Fuente de ingreso'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Sin fuente'),
                  ),
                  ...widget.sources.map(
                        (source) => DropdownMenuItem<int?>(
                      value: source.id,
                      child: Text(source.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedIncomeSourceId = value;
                  });
                },
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: titleController,
              decoration: inputDecoration('Título'),
              validator: (value) => AppValidators.requiredText(
                value,
                label: 'El título',
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: inputDecoration('Monto'),
              validator: (value) => AppValidators.requiredPositiveNumber(
                value,
                label: 'El monto',
                allowZero: false,
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
              controller: expectedDateController,
              decoration: inputDecoration('Fecha esperada (YYYY-MM-DD)'),
              validator: (value) => AppValidators.requiredDateYmd(
                value,
                label: 'La fecha esperada',
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: status,
              decoration: inputDecoration('Estado'),
              items: const [
                DropdownMenuItem(
                  value: 'planned',
                  child: Text('Planificado'),
                ),
                DropdownMenuItem(
                  value: 'received',
                  child: Text('Recibido'),
                ),
                DropdownMenuItem(
                  value: 'missed',
                  child: Text('No recibido'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  status = value ?? 'planned';
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: receivedDateController,
              decoration: inputDecoration('Fecha recibida (YYYY-MM-DD)'),
              validator: (value) => AppValidators.optionalDateYmd(
                value,
                label: 'La fecha recibida',
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 12),
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