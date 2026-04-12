import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_auth.dart';
import '../config/api_config.dart';
import '../models/debt.dart';

class DebtService {
  Future<List<Debt>> getDebts() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/debts');

    final response = await http.get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${ApiAuth.bearerToken}',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load debts. '
            'Status: ${response.statusCode}. '
            'Body: ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as List<dynamic>;

    return json
        .map((item) => Debt.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> createDebt({
    required String debtType,
    required String name,
    String? creditorName,
    required String currency,
    double? originalAmount,
    required double currentBalance,
    double? monthlyDueAmount,
    double? minimumPayment,
    double? interestRateMonthly,
    int? dueDay,
    required String status,
    required bool hasFixedPayment,
    String? notes,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/debts');

    final response = await http.post(
      uri,
      headers: const {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${ApiAuth.bearerToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'debt_type': debtType,
        'name': name,
        'creditor_name': creditorName,
        'currency': currency,
        'original_amount': originalAmount,
        'current_balance': currentBalance,
        'monthly_due_amount': monthlyDueAmount,
        'minimum_payment': minimumPayment,
        'interest_rate_monthly': interestRateMonthly,
        'due_day': dueDay,
        'status': status,
        'has_fixed_payment': hasFixedPayment,
        'notes': notes,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Failed to create debt. '
            'Status: ${response.statusCode}. '
            'Body: ${response.body}',
      );
    }
  }
}