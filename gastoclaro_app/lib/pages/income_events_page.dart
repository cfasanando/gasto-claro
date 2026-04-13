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
import '../widgets/income_event_form_sheet.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_entity_card.dart';
import '../widgets/app_page_state.dart';
import '../widgets/app_destructive_action_sheet.dart';

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
    List<IncomeSource> sources = [];

    try {
      sources = await incomeSourceService.getIncomeSources();
    } catch (_) {}

    if (!mounted) {
      return;
    }

    final draft = await showIncomeEventFormSheet(
      context: context,
      sources: sources,
      year: widget.year,
      month: widget.month,
      existingEvent: existingEvent,
    );

    if (draft == null) {
      return;
    }

    try {
      if (existingEvent == null) {
        await incomeEventService.createIncomeEvent(
          incomeSourceId: draft.incomeSourceId,
          title: draft.title,
          amount: draft.amount,
          currency: draft.currency,
          expectedDate: draft.expectedDate,
          receivedDate: draft.receivedDate,
          status: draft.status,
          notes: draft.notes,
        );
      } else {
        await incomeEventService.updateIncomeEvent(
          id: existingEvent.id,
          incomeSourceId: draft.incomeSourceId,
          title: draft.title,
          amount: draft.amount,
          currency: draft.currency,
          expectedDate: draft.expectedDate,
          receivedDate: draft.receivedDate,
          status: draft.status,
          notes: draft.notes,
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
    final confirmed = await showDestructiveActionSheet(
      context: context,
      title: 'Eliminar evento de ingreso',
      message: '¿Deseas eliminar "${event.title}"?',
      confirmLabel: 'Eliminar',
      icon: Icons.event_note_outlined,
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
          return const AppPageLoadingState(
            title: 'Cargando eventos de ingreso',
            subtitle: 'Estamos reuniendo lo esperado y lo recibido del mes.',
          );
        }

        if (snapshot.hasError) {
          return AppPageErrorState(
            title: 'No se pudieron cargar los eventos de ingreso',
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
                      (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppEntityCard(
                      icon: item.status == 'received'
                          ? Icons.trending_up_outlined
                          : item.status == 'missed'
                          ? Icons.event_busy_outlined
                          : Icons.event_note_outlined,
                      accentColor: statusColor(item.status),
                      eyebrow: 'Evento de ingreso',
                      title: item.title,
                      subtitle: item.incomeSourceName?.trim().isNotEmpty == true
                          ? item.incomeSourceName!
                          : 'Sin fuente asignada',
                      trailing: AppFormatters.money(item.amount, item.currency),
                      statusChip: AppStatusChip(
                        label: translateStatus(item.status),
                        color: statusColor(item.status),
                        icon: statusIcon(item.status),
                      ),
                      metadata: [
                        AppEntityMeta(
                          icon: Icons.schedule_outlined,
                          label: 'Esperado ${AppFormatters.date(item.expectedDate)}',
                        ),
                        if (item.receivedDate != null)
                          AppEntityMeta(
                            icon: Icons.check_circle_outline,
                            label: 'Recibido ${AppFormatters.date(item.receivedDate)}',
                          ),
                        AppEntityMeta(
                          icon: Icons.currency_exchange_outlined,
                          label: item.currency,
                        ),
                      ],
                      actions: [
                        OutlinedButton.icon(
                          onPressed: () => openEditIncomeEventDialog(item),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Editar'),
                        ),
                        TextButton.icon(
                          onPressed: () => confirmDeleteIncomeEvent(item),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Eliminar'),
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