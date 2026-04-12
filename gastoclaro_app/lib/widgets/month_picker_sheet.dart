import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'app_modal_sheet.dart';

Future<Map<String, int>?> showMonthPickerSheet({
  required BuildContext context,
  required int initialYear,
  required int initialMonth,
  required int minYear,
  required int maxYear,
}) {
  return showAppModalSheet<Map<String, int>>(
    context: context,
    builder: (_) => _MonthPickerSheet(
      initialYear: initialYear,
      initialMonth: initialMonth,
      minYear: minYear,
      maxYear: maxYear,
    ),
  );
}

class _MonthPickerSheet extends StatefulWidget {
  final int initialYear;
  final int initialMonth;
  final int minYear;
  final int maxYear;

  const _MonthPickerSheet({
    required this.initialYear,
    required this.initialMonth,
    required this.minYear,
    required this.maxYear,
  });

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  static const List<String> _monthNames = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  late int selectedYear;
  late int selectedMonth;

  @override
  void initState() {
    super.initState();
    selectedYear = widget.initialYear;
    selectedMonth = widget.initialMonth;
  }

  @override
  Widget build(BuildContext context) {
    final years = [
      for (int year = widget.minYear; year <= widget.maxYear; year++) year,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seleccionar mes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Cambia rápidamente el periodo visible del dashboard y tus movimientos.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTokens.ink500,
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<int>(
            value: selectedYear,
            decoration: const InputDecoration(
              labelText: 'Año',
            ),
            items: years
                .map(
                  (year) => DropdownMenuItem<int>(
                value: year,
                child: Text(year.toString()),
              ),
            )
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedYear = value ?? selectedYear;
              });
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Mes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(
              _monthNames.length,
                  (index) {
                final month = index + 1;
                final isSelected = selectedMonth == month;

                return ChoiceChip(
                  label: Text(_monthNames[index]),
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
                      selectedMonth = month;
                    });
                  },
                );
              },
            ),
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
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop({
                      'year': selectedYear,
                      'month': selectedMonth,
                    });
                  },
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}