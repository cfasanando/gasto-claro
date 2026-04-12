import 'package:flutter/material.dart';

import '../models/income_event.dart';
import '../models/income_source.dart';
import '../services/income_event_service.dart';
import '../services/income_source_service.dart';
import '../utils/app_formatters.dart';
import '../utils/app_validators.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_section_header.dart';
import '../widgets/app_status_chip.dart';

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

  InputDecoration dialogInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );
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

  Color statusColor(String value) {
    switch (value) {
      case 'planned':
        return Colors.blueGrey;
      case 'received':
        return Colors.green;
      case 'missed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData statusIcon(String value) {
    switch (value) {
      case 'planned':
        return Icons.schedule_outlined;
      case 'received':
        return Icons.check_circle_outline;
      case 'missed':
        return Icons.warning_amber_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String defaultExpectedDate() {
    final month = widget.month.toString().padLeft(2, '0');
    return '${widget.year}-$month-01';
  }

  Future<void> openCreateIncomeEventDialog() async {
    await openIncomeEventDialog();
  }

  Future<void> openEditIncomeEventDialog(IncomeEvent event) async {
    await openIncomeEventDialog(existingEvent: event);
  }

  Future<void> openIncomeEventDialog({IncomeEvent? existingEvent}) async {
    final formKey = GlobalKey<FormState>();

    final titleController = TextEditingController(
      text: existingEvent?.title ?? '',
    );
    final amountController = TextEditingController(
      text: existingEvent?.amount.toStringAsFixed(2) ?? '',
    );
    final expectedDateController = TextEditingController(
      text: existingEvent != null
          ? AppFormatters.date(existingEvent.expectedDate)
          : defaultExpectedDate(),
    );
    final receivedDateController = TextEditingController(
      text: existingEvent?.receivedDate != null
          ? AppFormatters.date(existingEvent!.receivedDate)
          : '',
    );
    final notesController = TextEditingController(
      text: existingEvent?.notes ?? '',
    );

    String currency = existingEvent?.currency ?? 'PEN';
    String status = existingEvent?.status ?? 'planned';
    int? selectedIncomeSourceId = existingEvent?.incomeSourceId;

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
              title: Text(
                existingEvent == null
                    ? 'Nuevo evento de ingreso'
                    : 'Editar evento de ingreso',
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (sources.isNotEmpty)
                        DropdownButtonFormField<int?>(
                          value: selectedIncomeSourceId,
                          decoration: dialogInputDecoration('Fuente de ingreso'),
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
                      TextFormField(
                        controller: titleController,
                        decoration: dialogInputDecoration('Título'),
                        validator: (value) => AppValidators.requiredText(
                          value,
                          label: 'El título',
                        ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: dialogInputDecoration('Monto'),
                        validator: (value) =>
                            AppValidators.requiredPositiveNumber(
                              value,
                              label: 'El monto',
                              allowZero: false,
                            ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: currency,
                        decoration: dialogInputDecoration('Moneda'),
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
                      TextFormField(
                        controller: expectedDateController,
                        decoration: dialogInputDecoration('Fecha esperada (YYYY-MM-DD)'),
                        validator: (value) => AppValidators.requiredDateYmd(
                          value,
                          label: 'La fecha esperada',
                        ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: dialogInputDecoration('Estado'),
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
                      TextFormField(
                        controller: receivedDateController,
                        decoration: dialogInputDecoration('Fecha recibida (YYYY-MM-DD)'),
                        validator: (value) => AppValidators.optionalDateYmd(
                          value,
                          label: 'La fecha recibida',
                        ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesController,
                        decoration: dialogInputDecoration('Notas'),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final isValid = formKey.currentState?.validate() ?? false;

                    if (!isValid) {
                      return;
                    }

                    Navigator.of(context).pop(true);
                  },
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

    try {
      if (existingEvent == null) {
        await incomeEventService.createIncomeEvent(
          incomeSourceId: selectedIncomeSourceId,
          title: titleController.text.trim(),
          amount: amount ?? 0,
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
      } else {
        await incomeEventService.updateIncomeEvent(
          id: existingEvent.id,
          incomeSourceId: selectedIncomeSourceId,
          title: titleController.text.trim(),
          amount: amount ?? 0,
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
      }

      await reload();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existingEvent == null
                ? 'Evento de ingreso creado correctamente'
                : 'Evento de ingreso actualizado correctamente',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existingEvent == null
                ? 'No se pudo crear el evento de ingreso: $e'
                : 'No se pudo actualizar el evento de ingreso: $e',
          ),
        ),
      );
    }
  }

  Future<void> confirmDeleteIncomeEvent(IncomeEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar evento de ingreso'),
          content: Text('¿Deseas eliminar "${event.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await incomeEventService.deleteIncomeEvent(event.id);
      await reload();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evento de ingreso eliminado correctamente'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo eliminar el evento de ingreso: $e'),
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
              AppSectionHeader(
                title: 'Eventos de ingreso',
                subtitle: '${items.length} registrados en este mes',
                action: ElevatedButton.icon(
                  onPressed: openCreateIncomeEventDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo'),
                ),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const AppEmptyState(
                  icon: Icons.event_note_outlined,
                  title: 'No hay eventos de ingreso para este mes',
                  subtitle: 'Agrega un evento para reflejar ingresos esperados o recibidos.',
                )
              else
                ...items.map(
                      (item) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('Fuente: ${item.incomeSourceName ?? 'Sin fuente'}'),
                                const SizedBox(height: 6),
                                Text('Esperado: ${AppFormatters.date(item.expectedDate)}'),
                                if (item.receivedDate != null) ...[
                                  const SizedBox(height: 6),
                                  Text('Recibido: ${AppFormatters.date(item.receivedDate)}'),
                                ],
                                const SizedBox(height: 10),
                                AppStatusChip(
                                  label: translateStatus(item.status),
                                  color: statusColor(item.status),
                                  icon: statusIcon(item.status),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                AppFormatters.money(item.amount, item.currency),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              PopupMenuButton<String>(
                                tooltip: 'Acciones',
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    openEditIncomeEventDialog(item);
                                  } else if (value == 'delete') {
                                    confirmDeleteIncomeEvent(item);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 18),
                                        SizedBox(width: 8),
                                        Text('Editar'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline, size: 18),
                                        SizedBox(width: 8),
                                        Text('Eliminar'),
                                      ],
                                    ),
                                  ),
                                ],
                                icon: const Icon(Icons.more_vert),
                              ),
                            ],
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