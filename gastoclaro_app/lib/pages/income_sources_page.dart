import 'package:flutter/material.dart';

import '../models/income_source.dart';
import '../services/income_source_service.dart';

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

  String formatMoney(double value, String currency) {
    final symbol = currency == 'USD' ? r'$' : 'S/';
    return '$symbol ${value.toStringAsFixed(2)}';
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

  String translateState(bool isActive) {
    return isActive ? 'Activa' : 'Inactiva';
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Fuentes de ingreso',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: openCreateIncomeSourceDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const Text('No hay fuentes de ingreso registradas.')
              else
                ...items.map(
                      (item) => Card(
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                        '${translateType(item.type)}\n'
                            'Estado: ${translateState(item.isActive)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (item.defaultAmount != null)
                                Text(
                                  formatMoney(
                                    item.defaultAmount!,
                                    item.currency,
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              Text(
                                item.currency,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
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