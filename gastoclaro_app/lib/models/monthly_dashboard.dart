class MonthlyDashboard {
  final String selectedMonth;
  final double expectedIncomeTotal;
  final double receivedIncomeTotal;
  final double obligationTotal;
  final double paidTotal;
  final double remainingObligationTotal;
  final double projectedBalance;
  final double actualBalance;
  final int paymentObligationsCount;
  final int paymentRecordsCount;
  final int incomeEventsCount;
  final List<Map<String, dynamic>> upcomingItems;
  final List<Map<String, dynamic>> attentionItems;
  final List<Map<String, dynamic>> paidItems;
  final List<Map<String, dynamic>> pendingItems;
  final String dashboardNote;

  MonthlyDashboard({
    required this.selectedMonth,
    required this.expectedIncomeTotal,
    required this.receivedIncomeTotal,
    required this.obligationTotal,
    required this.paidTotal,
    required this.remainingObligationTotal,
    required this.projectedBalance,
    required this.actualBalance,
    required this.paymentObligationsCount,
    required this.paymentRecordsCount,
    required this.incomeEventsCount,
    required this.upcomingItems,
    required this.attentionItems,
    required this.paidItems,
    required this.pendingItems,
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
      obligationTotal: toDouble(json['obligation_total']),
      paidTotal: toDouble(json['paid_total']),
      remainingObligationTotal: toDouble(json['remaining_obligation_total']),
      projectedBalance: toDouble(json['projected_balance']),
      actualBalance: toDouble(json['actual_balance']),
      paymentObligationsCount: toInt(json['payment_obligations_count']),
      paymentRecordsCount: toInt(json['payment_records_count']),
      incomeEventsCount: toInt(json['income_events_count']),
      upcomingItems: toItemList(json['upcoming_items']),
      attentionItems: toItemList(json['attention_items']),
      paidItems: toItemList(json['paid_items']),
      pendingItems: toItemList(json['pending_items']),
      dashboardNote: json['dashboard_note']?.toString() ?? '',
    );
  }
}