import 'package:flutter/material.dart';

import 'models/app_user.dart';
import 'pages/dashboard_page.dart';
import 'pages/debts_page.dart';
import 'pages/fixed_expenses_page.dart';
import 'pages/income_events_page.dart';
import 'pages/income_sources_page.dart';
import 'pages/login_page.dart';
import 'pages/payment_obligations_page.dart';
import 'pages/payment_records_page.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const GastoClaroApp());
}

class GastoClaroApp extends StatelessWidget {
  const GastoClaroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GastoClaro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const SessionGate(),
    );
  }
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  final AuthService authService = AuthService();
  late Future<bool> futureSession;

  @override
  void initState() {
    super.initState();
    loadSession();
  }

  void loadSession() {
    futureSession = authService.restoreSession();
  }

  Future<void> refreshSession() async {
    setState(() {
      loadSession();
    });
  }

  Future<void> handleLogout() async {
    await authService.logout();

    if (!mounted) {
      return;
    }

    setState(() {
      loadSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: futureSession,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final isAuthenticated = snapshot.data == true;

        if (!isAuthenticated) {
          return LoginPage(
            onLoginSuccess: () {
              refreshSession();
            },
          );
        }

        return HomePage(
          onLogout: handleLogout,
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  final Future<void> Function() onLogout;

  const HomePage({
    super.key,
    required this.onLogout,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;

  late int year;
  late int month;

  final ProfileService profileService = ProfileService();

  AppUser? currentUser;
  bool isLoadingUser = false;

  static const List<String> monthNames = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Setiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    year = now.year;
    month = now.month;

    loadCurrentUser();
  }

  Future<void> loadCurrentUser() async {
    setState(() {
      isLoadingUser = true;
    });

    try {
      final user = await profileService.getMe();

      if (!mounted) {
        return;
      }

      setState(() {
        currentUser = user;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        currentUser = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoadingUser = false;
        });
      }
    }
  }

  bool get pageUsesMonth {
    return currentIndex == 0 ||
        currentIndex == 1 ||
        currentIndex == 2 ||
        currentIndex == 6;
  }

  void goToPreviousMonth() {
    setState(() {
      if (month == 1) {
        month = 12;
        year--;
      } else {
        month--;
      }
    });
  }

  void goToNextMonth() {
    setState(() {
      if (month == 12) {
        month = 1;
        year++;
      } else {
        month++;
      }
    });
  }

  Future<void> openMonthPickerDialog() async {
    int tempYear = year;
    int tempMonth = month;

    final selected = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Seleccionar mes'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: tempMonth,
                    decoration: const InputDecoration(
                      labelText: 'Mes',
                    ),
                    items: List.generate(
                      12,
                          (index) => DropdownMenuItem<int>(
                        value: index + 1,
                        child: Text(monthNames[index]),
                      ),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        tempMonth = value ?? tempMonth;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: tempYear,
                    decoration: const InputDecoration(
                      labelText: 'Año',
                    ),
                    items: List.generate(
                      11,
                          (index) {
                        final value = DateTime.now().year - 5 + index;

                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(value.toString()),
                        );
                      },
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        tempYear = value ?? tempYear;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop({
                      'year': tempYear,
                      'month': tempMonth,
                    });
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected == null) {
      return;
    }

    setState(() {
      year = selected['year'] ?? year;
      month = selected['month'] ?? month;
    });
  }

  String get currentMonthLabel {
    return '${monthNames[month - 1]} $year';
  }

  void openTab(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  String get userInitial {
    final name = currentUser?.name.trim() ?? '';

    if (name.isEmpty) {
      return '?';
    }

    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
        year: year,
        month: month,
        onOpenObligations: () => openTab(1),
        onOpenPayments: () => openTab(2),
        onOpenIncomeEvents: () => openTab(6),
      ),
      PaymentObligationsPage(year: year, month: month),
      PaymentRecordsPage(year: year, month: month),
      const DebtsPage(),
      const FixedExpensesPage(),
      const IncomeSourcesPage(),
      IncomeEventsPage(year: year, month: month),
    ];

    final titles = [
      'Resumen',
      'Obligaciones',
      'Pagos',
      'Deudas',
      'Gastos',
      'Ingresos',
      'Eventos',
    ];

    final width = MediaQuery.of(context).size.width;
    final useRail = width >= 1080;

    final destinations = const [
      _AppDestination(
        label: 'Panel',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard_rounded,
      ),
      _AppDestination(
        label: 'Obligaciones',
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
      ),
      _AppDestination(
        label: 'Pagos',
        icon: Icons.payments_outlined,
        selectedIcon: Icons.payments,
      ),
      _AppDestination(
        label: 'Deudas',
        icon: Icons.account_balance_wallet_outlined,
        selectedIcon: Icons.account_balance_wallet,
      ),
      _AppDestination(
        label: 'Gastos',
        icon: Icons.home_work_outlined,
        selectedIcon: Icons.home_work,
      ),
      _AppDestination(
        label: 'Ingresos',
        icon: Icons.attach_money_outlined,
        selectedIcon: Icons.attach_money,
      ),
      _AppDestination(
        label: 'Eventos',
        icon: Icons.event_note_outlined,
        selectedIcon: Icons.event_note,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[currentIndex],
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          if (pageUsesMonth) ...[
            IconButton(
              onPressed: goToPreviousMonth,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Mes anterior',
            ),
            Center(
              child: InkWell(
                onTap: openMonthPickerDialog,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    currentMonthLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: goToNextMonth,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Mes siguiente',
            ),
            const SizedBox(width: 6),
          ],
          PopupMenuButton<String>(
            tooltip: currentUser?.email.isNotEmpty == true
                ? currentUser!.email
                : 'Cuenta',
            onSelected: (value) async {
              if (value == 'refresh_profile') {
                await loadCurrentUser();
              } else if (value == 'logout') {
                await widget.onLogout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: SizedBox(
                  width: 240,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser?.name.isNotEmpty == true
                            ? currentUser!.name
                            : 'Usuario',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentUser?.email.isNotEmpty == true
                            ? currentUser!.email
                            : 'Sin correo disponible',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (isLoadingUser) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Cargando perfil...',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'refresh_profile',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 18),
                    SizedBox(width: 8),
                    Text('Recargar perfil'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18),
                    SizedBox(width: 8),
                    Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.12),
                    child: Text(
                      userInitial,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (useRail) ...[
                    const SizedBox(width: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        currentUser?.name.isNotEmpty == true
                            ? currentUser!.name
                            : 'Cuenta',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          if (useRail)
            Container(
              width: 100,
              margin: const EdgeInsets.fromLTRB(16, 8, 0, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: NavigationRail(
                selectedIndex: currentIndex,
                onDestinationSelected: openTab,
                labelType: NavigationRailLabelType.all,
                useIndicator: true,
                leading: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 12),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF4F46E5),
                          Color(0xFF14B8A6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.auto_graph_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
                destinations: destinations
                    .map(
                      (item) => NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: Text(item.label),
                  ),
                )
                    .toList(),
              ),
            ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                useRail ? 16 : 0,
                8,
                16,
                useRail ? 16 : 0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(useRail ? 34 : 0),
                child: Material(
                  color: Colors.transparent,
                  child: IndexedStack(
                    index: currentIndex,
                    children: pages,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: useRail
          ? null
          : SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: openTab,
            destinations: destinations
                .map(
                  (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
              ),
            )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _AppDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _AppDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}