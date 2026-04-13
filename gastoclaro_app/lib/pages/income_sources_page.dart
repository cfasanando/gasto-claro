import 'package:flutter/material.dart';

import '../models/income_source.dart';
import '../services/income_source_service.dart';
import '../utils/app_formatters.dart';
import '../utils/app_validators.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_section_header.dart';
import '../widgets/app_status_chip.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_entity_card.dart';
import '../widgets/income_source_form_sheet.dart';

class IncomeSourcesPage extends StatefulWidget {
  const IncomeSourcesPage({super.key});

  @override
  State<IncomeSourcesPage> createState() => _IncomeSourcesPageState();
}

class _IncomeSourcesPageState extends State<IncomeSourcesPage> {
  late Future<List<IncomeSource>> futureItems;
  final IncomeSourceService incomeSourceService = IncomeSourceService();

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  void loadItems() {
    futureItems = incomeSourceService.getIncomeSources();
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

  String translateType(String value) {
    switch (value) {
      case 'salary':
        return 'Sueldo';
      case 'bonus':
        return 'Bono / gratificación';
      case 'cts':
        return 'CTS';
      case 'vacation':
        return 'Vacaciones';
      case 'freelance':
        return 'Freelance';
      case 'business':
        return 'Negocio';
      case 'other':
        return 'Otro';
      default:
        return value;
    }
  }

  Color typeColor(String value) {
    switch (value) {
      case 'salary':
        return Colors.green;
      case 'bonus':
        return Colors.orange;
      case 'cts':
        return Colors.blue;
      case 'vacation':
        return Colors.teal;
      case 'freelance':
        return Colors.deepPurple;
      case 'business':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  Future<void> openCreateIncomeSourceDialog() async {
    await openIncomeSourceDialog();
  }

  Future<void> openEditIncomeSourceDialog(IncomeSource source) async {
    await openIncomeSourceDialog(existingSource: source);
  }

  Future<void> openIncomeSourceDialog({IncomeSource? existingSource}) async {
    final draft = await showIncomeSourceFormSheet(
      context: context,
      existingSource: existingSource,
    );

    if (draft == null) {
      return;
    }

    try {
      if (existingSource == null) {
        await incomeSourceService.createIncomeSource(
          name: draft.name,
          type: draft.type,
          defaultAmount: draft.defaultAmount,
          currency: draft.currency,
          isActive: draft.isActive,
          notes: draft.notes,
        );
      } else {
        await incomeSourceService.updateIncomeSource(
          id: existingSource.id,
          name: draft.name,
          type: draft.type,
          defaultAmount: draft.defaultAmount,
          currency: draft.currency,
          isActive: draft.isActive,
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
            existingSource == null
                ? 'Fuente de ingreso creada correctamente'
                : 'Fuente de ingreso actualizada correctamente',
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
            existingSource == null
                ? 'No se pudo crear la fuente de ingreso: $e'
                : 'No se pudo actualizar la fuente de ingreso: $e',
          ),
        ),
      );
    }
  }

  Future<void> confirmDeleteIncomeSource(IncomeSource source) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar fuente de ingreso'),
          content: Text('¿Deseas eliminar "${source.name}"?'),
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
      await incomeSourceService.deleteIncomeSource(source.id);
      await reload();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fuente de ingreso eliminada correctamente'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo eliminar la fuente de ingreso: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<IncomeSource>>(
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
                    'No se pudieron cargar las fuentes de ingreso',
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
                title: 'Fuentes de ingreso',
                subtitle: '${items.length} registradas',
                action: ElevatedButton.icon(
                  onPressed: openCreateIncomeSourceDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva'),
                ),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const AppEmptyState(
                  icon: Icons.attach_money_outlined,
                  title: 'No hay fuentes de ingreso registradas',
                  subtitle: 'Agrega una fuente para planificar ingresos del mes.',
                )
              else
                ...items.map(
                      (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppEntityCard(
                      icon: Icons.attach_money_outlined,
                      accentColor: item.isActive ? typeColor(item.type) : AppTokens.ink500,
                      eyebrow: 'Fuente de ingreso',
                      title: item.name,
                      subtitle: item.notes?.trim().isNotEmpty == true
                          ? item.notes!
                          : translateType(item.type),
                      trailing: item.defaultAmount != null
                          ? AppFormatters.money(item.defaultAmount!, item.currency)
                          : 'Variable',
                      statusChip: AppStatusChip(
                        label: item.isActive ? 'Activa' : 'Inactiva',
                        color: item.isActive ? AppTokens.success : Colors.grey,
                        icon: item.isActive
                            ? Icons.check_circle_outline
                            : Icons.pause_circle_outline,
                      ),
                      metadata: [
                        AppEntityMeta(
                          icon: Icons.label_outline,
                          label: translateType(item.type),
                        ),
                        AppEntityMeta(
                          icon: Icons.currency_exchange_outlined,
                          label: item.currency,
                        ),
                        AppEntityMeta(
                          icon: item.defaultAmount != null
                              ? Icons.tune_outlined
                              : Icons.auto_awesome_motion_outlined,
                          label: item.defaultAmount != null
                              ? 'Monto base definido'
                              : 'Monto variable',
                        ),
                      ],
                      actions: [
                        OutlinedButton.icon(
                          onPressed: () => openEditIncomeSourceDialog(item),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Editar'),
                        ),
                        TextButton.icon(
                          onPressed: () => confirmDeleteIncomeSource(item),
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