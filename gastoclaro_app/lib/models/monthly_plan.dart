import '../models/debt.dart';

class MonthlyPlan {
  final double availableNow;
  final double projectedBalance;
  final String pressureLevel;
  final String summary;
  final List<Map<String, dynamic>> mustPay;
  final List<Map<String, dynamic>> payIfExtraIncome;
  final List<Map<String, dynamic>> canPause;
  final Debt? focusDebt;

  const MonthlyPlan({
    required this.availableNow,
    required this.projectedBalance,
    required this.pressureLevel,
    required this.summary,
    required this.mustPay,
    required this.payIfExtraIncome,
    required this.canPause,
    required this.focusDebt,
  });
}