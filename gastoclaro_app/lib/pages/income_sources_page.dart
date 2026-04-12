import 'package:flutter/material.dart';

import '../models/income_source.dart';
import '../services/income_source_service.dart';
import '../utils/app_formatters.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_section_header.dart';
import '../widgets/app_status_chip.dart';

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
    final nameController = TextEditingController(
      text: existingSource?.name ?? '',
    );
    final defaultAmountController = TextEditingController(
      text: existingSource?.defaultAmount?.toStringAsFixed(2) ?? '',
    );
    final notesController = TextEditingController(
      text: existingSource?.notes ?? '',
    );

    String type = existingSource?.type ?? 'salary';
    String currency = existingSource?.currency ?? 'PEN';
    bool isActive = existingSource?.isActive ?? true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                existingSource == null
                    ? 'Nueva fuente de ingreso'
                    : 'Editar fuente de ingreso',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                      ),
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
                          value: 'cts',
                          child: Text('CTS'),
                        ),
                        DropdownMenuItem(
                          value: 'vacation',
                          child: Text('Vacaciones'),
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
                          value: 'other',
                          child: Text('Otro'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          type = value ?? 'salary';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: defaultAmountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Monto por defecto',
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
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Está activa'),
                      value: isActive,
                      onChanged: (value) {
                        setDialogState(() {
                          isActive = value;
                        });
                      },
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

    if (nameController.text.trim().isEmpty) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa al menos el nombre'),
        ),
      );

      return;
    }

    try {
      if (existingSource == null) {
        await incomeSourceService.createIncomeSource(
          name: nameController.text.trim(),
          type: type,
          defaultAmount: double.tryParse(defaultAmountController.text.trim()),
          currency: currency,
          isActive: isActive,
          notes: notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
        );
      } else {
        await incomeSourceService.updateIncomeSource(
          id: existingSource.id,
          name: nameController.text.trim(),
          type: type,
          defaultAmount: double.tryParse(defaultAmountController.text.trim()),
          currency: currency,
          isActive: isActive,
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
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    AppStatusChip(
                                      label: translateType(item.type),
                                      color: typeColor(item.type),
                                      icon: Icons.label_outline,
                                    ),
                                    AppStatusChip(
                                      label: item.isActive ? 'Activa' : 'Inactiva',
                                      color: item.isActive ? Colors.green : Colors.grey,
                                      icon: item.isActive
                                          ? Icons.check_circle_outline
                                          : Icons.pause_circle_outline,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (item.defaultAmount != null)
                                Text(
                                  AppFormatters.money(item.defaultAmount!, item.currency),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                item.currency,
                                style: const TextStyle(fontSize: 12),
                              ),
                              PopupMenuButton<String>(
                                tooltip: 'Acciones',
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    openEditIncomeSourceDialog(item);
                                  } else if (value == 'delete') {
                                    confirmDeleteIncomeSource(item);
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