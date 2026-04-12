class Debt {
  final int id;
  final String debtType;
  final String name;
  final String? creditorName;
  final String currency;
  final double? originalAmount;
  final double currentBalance;
  final double? monthlyDueAmount;
  final double? minimumPayment;
  final double? interestRateMonthly;
  final int? dueDay;
  final String status;
  final bool hasFixedPayment;
  final String? notes;

  Debt({
    required this.id,
    required this.debtType,
    required this.name,
    required this.creditorName,
    required this.currency,
    required this.originalAmount,
    required this.currentBalance,
    required this.monthlyDueAmount,
    required this.minimumPayment,
    required this.interestRateMonthly,
    required this.dueDay,
    required this.status,
    required this.hasFixedPayment,
    required this.notes,
  });

  factory Debt.fromJson(Map<String, dynamic> json) {
    double? toNullableDouble(dynamic value) {
      if (value == null) {
        return null;
      }

      if (value is int) {
        return value.toDouble();
      }

      if (value is double) {
        return value;
      }

      return double.tryParse(value.toString());
    }

    int? toNullableInt(dynamic value) {
      if (value == null) {
        return null;
      }

      if (value is int) {
        return value;
      }

      return int.tryParse(value.toString());
    }

    return Debt(
      id: toNullableInt(json['id']) ?? 0,
      debtType: json['debt_type']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      creditorName: json['creditor_name']?.toString(),
      currency: json['currency']?.toString() ?? 'PEN',
      originalAmount: toNullableDouble(json['original_amount']),
      currentBalance: toNullableDouble(json['current_balance']) ?? 0,
      monthlyDueAmount: toNullableDouble(json['monthly_due_amount']),
      minimumPayment: toNullableDouble(json['minimum_payment']),
      interestRateMonthly: toNullableDouble(json['interest_rate_monthly']),
      dueDay: toNullableInt(json['due_day']),
      status: json['status']?.toString() ?? 'active',
      hasFixedPayment: json['has_fixed_payment'] == true,
      notes: json['notes']?.toString(),
    );
  }
}