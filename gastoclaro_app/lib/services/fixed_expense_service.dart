import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_auth.dart';
import '../config/api_config.dart';
import '../models/fixed_expense.dart';

class FixedExpenseService {
  Future<List<FixedExpense>> getFixedExpenses() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/fixed-expenses');

    final response = await http.get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${ApiAuth.bearerToken}',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load fixed expenses. '
            'Status: ${response.statusCode}. '
            'Body: ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as List<dynamic>;

    return json
        .map((item) => FixedExpense.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> createFixedExpense({
    required String name,
    String? category,
    required double amount,
    required String currency,
    int? dueDay,
    required String frequency,
    required bool isMandatory,
    required bool isActive,
    String? notes,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/fixed-expenses');

    final response = await http.post(
      uri,
      headers: const {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${ApiAuth.bearerToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'category': category,
        'amount': amount,
        'currency': currency,
        'due_day': dueDay,
        'frequency': frequency,
        'is_mandatory': isMandatory,
        'is_active': isActive,
        'notes': notes,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Failed to create fixed expense. '
            'Status: ${response.statusCode}. '
            'Body: ${response.body}',
      );
    }
  }
}