import 'package:flutter/material.dart';

import 'pages/dashboard_page.dart';
import 'pages/debts_page.dart';
import 'pages/fixed_expenses_page.dart';
import 'pages/income_sources_page.dart';
import 'pages/payment_obligations_page.dart';
import 'pages/payment_records_page.dart';

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
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;

  late int year;
  late int month;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    year = now.year;
    month = now.month;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(year: year, month: month),
      PaymentObligationsPage(year: year, month: month),
      PaymentRecordsPage(year: year, month: month),
      const DebtsPage(),
      const FixedExpensesPage(),
      const IncomeSourcesPage(),
    ];

    final titles = [
      'Panel mensual',
      'Obligaciones',
      'Pagos',
      'Deudas',
      'Gastos fijos',
      'Ingresos',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[currentIndex]),
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
        ],
      ),
    );
  }
}