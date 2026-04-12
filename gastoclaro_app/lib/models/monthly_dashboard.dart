class MonthlyDashboard {
  final String selectedMonth;
  final double expectedIncomeTotal;
  final double receivedIncomeTotal;
  final double fixedExpenseTotal;
  final double debtDueTotal;
  final double obligationTotal;
  final double projectedBalance;
  final int fixedExpensesCount;
  final int debtsCount;
  final int incomeEventsCount;
  final List<Map<String, dynamic>> upcomingItems;
  final List<Map<String, dynamic>> attentionItems;
  final String dashboardNote;

  MonthlyDashboard({
    required this.selectedMonth,
    required this.expectedIncomeTotal,
    required this.receivedIncomeTotal,
    required this.fixedExpenseTotal,
    required this.debtDueTotal,
    required this.obligationTotal,
    required this.projectedBalance,
    required this.fixedExpensesCount,
    required this.debtsCount,
    required this.incomeEventsCount,
    required this.upcomingItems,
    required this.attentionItems,
    required this.dashboardNote,
  });

  factory MonthlyDashboard.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) {
      if (value is int) {
        return value.toDouble();
      }

      if (value is double) {
        return value;
      }

      return double.tryParse(value.toString()) ?? 0;
    }

    int toInt(dynamic value) {
      if (value is int) {
        return value;
      }

      return int.tryParse(value.toString()) ?? 0;
    }

    List<Map<String, dynamic>> toItemList(dynamic value) {
      if (value is List) {
        return value
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }

      return [];
    }

    return MonthlyDashboard(
      selectedMonth: json['selected_month']?.toString() ?? '',
      expectedIncomeTotal: toDouble(json['expected_income_total']),
      receivedIncomeTotal: toDouble(json['received_income_total']),
      fixedExpenseTotal: toDouble(json['fixed_expense_total']),
      debtDueTotal: toDouble(json['debt_due_total']),
      obligationTotal: toDouble(json['obligation_total']),
      projectedBalance: toDouble(json['projected_balance']),
      fixedExpensesCount: toInt(json['fixed_expenses_count']),
      debtsCount: toInt(json['debts_count']),
      incomeEventsCount: toInt(json['income_events_count']),
      upcomingItems: toItemList(json['upcoming_items']),
      attentionItems: toItemList(json['attention_items']),
      dashboardNote: json['dashboard_note']?.toString() ?? '',
    );
  }
}