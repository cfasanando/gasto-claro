import 'package:flutter/material.dart';

import 'pages/dashboard_page.dart';
import 'pages/debts_page.dart';
import 'pages/fixed_expenses_page.dart';
import 'pages/income_events_page.dart';
import 'pages/income_sources_page.dart';
import 'pages/login_page.dart';
import 'pages/payment_obligations_page.dart';
import 'pages/payment_records_page.dart';
import 'services/auth_service.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
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
      'Panel mensual',
      'Obligaciones',
      'Pagos',
      'Deudas',
      'Gastos fijos',
      'Ingresos',
      'Eventos',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[currentIndex]),
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
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    currentMonthLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: openMonthPickerDialog,
              icon: const Icon(Icons.calendar_month_outlined),
              tooltip: 'Elegir mes',
            ),
            IconButton(
              onPressed: goToNextMonth,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Mes siguiente',
            ),
          ],
          PopupMenuButton<String>(
            tooltip: 'Cuenta',
            onSelected: (value) async {
              if (value == 'logout') {
                await widget.onLogout();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
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
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (value) {
          setState(() {
            currentIndex = value;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Panel',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Obligaciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            label: 'Pagos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Deudas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_work_outlined),
            label: 'Gastos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money_outlined),
            label: 'Ingresos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            label: 'Eventos',
          ),
        ],
      ),
    );
  }
}