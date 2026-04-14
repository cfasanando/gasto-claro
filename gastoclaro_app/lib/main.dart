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
import 'widgets/month_picker_sheet.dart';

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

  static const List<String> pageTitles = [
    'Resumen',
    'Obligaciones',
    'Pagos',
    'Deudas',
    'Gastos',
    'Ingresos',
    'Eventos',
  ];

  static const List<String> pageSubtitles = [
    'Tu balance mensual y la lectura rápida del periodo.',
    'Lo que vence y necesita atención este mes.',
    'Tus pagos registrados durante el periodo.',
    'Tus compromisos y saldos pendientes.',
    'Tus gastos fijos y recurrentes.',
    'Tus fuentes base de ingreso.',
    'Tus ingresos planificados o recibidos.',
  ];

  static const List<_AppDestination> appDestinations = [
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
    final currentYear = DateTime.now().year;

    final selected = await showMonthPickerSheet(
      context: context,
      initialYear: year,
      initialMonth: month,
      minYear: currentYear - 3,
      maxYear: currentYear + 6,
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

  int get mobileSelectedIndex {
    if (currentIndex >= 0 && currentIndex <= 2) {
      return currentIndex;
    }

    return 3;
  }

  void handleMobileDestinationSelected(int index) {
    if (index == 3) {
      openMobileSectionsSheet();
      return;
    }

    openTab(index);
  }

  Future<void> openMobileSectionsSheet() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _MobileSectionsSheet(
          currentIndex: currentIndex,
          items: [
            for (int index = 3; index < appDestinations.length; index++)
              _MobileSectionItem(
                index: index,
                title: appDestinations[index].label,
                subtitle: pageSubtitles[index],
                icon: appDestinations[index].selectedIcon,
              ),
          ],
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    openTab(selected);
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

    final width = MediaQuery.of(context).size.width;
    final useRail = width >= 1080;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          pageTitles[currentIndex],
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
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
              PopupMenuItem(
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
                    backgroundColor:
                    Theme.of(context).colorScheme.primary.withValues(
                      alpha: 0.12,
                    ),
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
                destinations: appDestinations
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
            selectedIndex: mobileSelectedIndex,
            onDestinationSelected: handleMobileDestinationSelected,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Panel',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Obligaciones',
              ),
              NavigationDestination(
                icon: Icon(Icons.payments_outlined),
                selectedIcon: Icon(Icons.payments),
                label: 'Pagos',
              ),
              NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view_rounded),
                label: 'Más',
              ),
            ],
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

class _MobileSectionItem {
  final int index;
  final String title;
  final String subtitle;
  final IconData icon;

  const _MobileSectionItem({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _MobileSectionsSheet extends StatelessWidget {
  final int currentIndex;
  final List<_MobileSectionItem> items;

  const _MobileSectionsSheet({
    required this.currentIndex,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final outlineColor = Theme.of(context).dividerColor;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(32),
        ),
        border: Border.all(
          color: outlineColor,
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: outlineColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Más secciones',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Accede rápido a los módulos secundarios sin saturar la barra inferior.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 18),
              ...items.map(
                    (item) {
                  final isSelected = item.index == currentIndex;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () => Navigator.of(context).pop(item.index),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor.withValues(alpha: 0.08)
                                : surfaceColor,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isSelected
                                  ? primaryColor.withValues(alpha: 0.18)
                                  : outlineColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryColor.withValues(alpha: 0.14)
                                      : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  item.icon,
                                  color: isSelected
                                      ? primaryColor
                                      : Theme.of(context).iconTheme.color,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.subtitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.chevron_right,
                                color: isSelected
                                    ? primaryColor
                                    : Theme.of(context).iconTheme.color,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}