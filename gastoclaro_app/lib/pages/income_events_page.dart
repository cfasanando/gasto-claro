import 'package:flutter/material.dart';

import '../models/income_event.dart';
import '../models/income_source.dart';
import '../services/income_event_service.dart';
import '../services/income_source_service.dart';

class IncomeEventsPage extends StatefulWidget {
  final int year;
  final int month;

  const IncomeEventsPage({
    super.key,
    required this.year,
    required this.month,
  });

  @override
  State<IncomeEventsPage> createState() => _IncomeEventsPageState();
}

class _IncomeEventsPageState extends State<IncomeEventsPage> {
  late Future<List<IncomeEvent>> futureItems;
  final IncomeEventService incomeEventService = IncomeEventService();
  final IncomeSourceService incomeSourceService = IncomeSourceService();

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  @override
  void didUpdateWidget(covariant IncomeEventsPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.year != widget.year || oldWidget.month != widget.month) {
      loadItems();
    }
  }

  void loadItems() {
    futureItems = incomeEventService.getIncomeEvents(
      year: widget.year,
      month: widget.month,
    );
  }

  Future<void> reload() async {
    setState(() {
      loadItems();
    });
  }

  String formatMoney(double value, String currency) {
    final symbol = currency == 'USD' ? r'$' : 'S/';
    return '$symbol ${value.toStringAsFixed(2)}';
  }

  String translateStatus(String value) {
    switch (value) {
      case 'planned':
        return 'Planificado';
      case 'received':
        return 'Recibido';
      case 'missed':
        return 'No recibido';
      default:
        return value;
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }

    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String defaultExpectedDate() {
    final month = widget.month.toString().padLeft(2, '0');
    return '${widget.year}-$month-01';
  }

  Future<void> openCreateIncomeEventDialog() async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final expectedDateController = TextEditingController(
      text: defaultExpectedDate(),
    );
    final receivedDateController = TextEditingController();
    final notesController = TextEditingController();

    String currency = 'PEN';
    String status = 'planned';
    int? selectedIncomeSourceId;

    List<IncomeSource> sources = [];

    try {
      sources = await incomeSourceService.getIncomeSources();
    } catch (_) {}

    if (!mounted) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nuevo evento de ingreso'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (sources.isNotEmpty)
                      DropdownButtonFormField<int?>(
                        value: selectedIncomeSourceId,
                        decoration: const InputDecoration(
                          labelText: 'Fuente de ingreso',
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Sin fuente'),
                          ),
                          ...sources.map(
                                (source) => DropdownMenuItem<int?>(
                              value: source.id,
                              child: Text(source.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedIncomeSourceId = value;
                          });
                        },
                      ),
                    if (sources.isNotEmpty) const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Monto',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: currency,
                      decoration: const InputDecoration(
                        labelText: 'Moneda',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'PEN', child: Text('PEN')),
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          currency = value ?? 'PEN';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: expectedDateController,
                      decoration: const InputDecoration(
                        labelText: 'Fecha esperada (YYYY-MM-DD)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                      ),
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
                        setDialogState(() {
                          status = value ?? 'planned';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: receivedDateController,
                      decoration: const InputDecoration(
                        labelText: 'Fecha recibida (YYYY-MM-DD)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notas',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final amount = double.tryParse(amountController.text.trim());

    if (titleController.text.trim().isEmpty ||
        amount == null ||
        amount < 0 ||
        expectedDateController.text.trim().isEmpty) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa título, monto y fecha esperada válidos'),
        ),
      );

      return;
    }

    try {
      await incomeEventService.createIncomeEvent(
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
      );

      await reload();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evento de ingreso creado correctamente'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo crear el evento de ingreso: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<IncomeEvent>>(
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
                    'No se pudieron cargar los eventos de ingreso',
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Eventos de ingreso',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: openCreateIncomeEventDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const Text('No hay eventos de ingreso para este mes.')
              else
                ...items.map(
                      (item) => Card(
                    child: ListTile(
                      title: Text(item.title),
                      subtitle: Text(
                        'Fuente: ${item.incomeSourceName ?? 'Sin fuente'}\n'
                            'Esperado: ${formatDate(item.expectedDate)}\n'
                            'Estado: ${translateStatus(item.status)}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatMoney(item.amount, item.currency),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (item.receivedDate != null)
                            Text(
                              'Recibido: ${formatDate(item.receivedDate)}',
                              style: const TextStyle(fontSize: 12),
                            ),
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