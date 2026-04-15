import 'package:shared_preferences/shared_preferences.dart';

class DebtFocusService {
  static const String _focusDebtIdKey = 'dashboard_focus_debt_id';

  Future<int?> getFocusDebtId() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt(_focusDebtIdKey);
  }

  Future<void> setFocusDebtId(int debtId) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_focusDebtIdKey, debtId);
  }

  Future<void> clearFocusDebtId() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_focusDebtIdKey);
  }
}