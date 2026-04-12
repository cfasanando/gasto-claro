import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/fixed_expense.dart';
import '../utils/api_error_parser.dart';
import 'api_headers.dart';

class FixedExpenseService {
  Future<List<FixedExpense>> getFixedExpenses() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/fixed-expenses');

    final response = await http.get(
      uri,
      headers: await ApiHeaders.auth(),
    );

    if (response.statusCode != 200) {
      throw ApiErrorParser.fromResponse(
        statusCode: response.statusCode,
        body: response.body,
        fallbackMessage: 'No se pudieron cargar los gastos fijos',
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
      headers: await ApiHeaders.auth(includeJsonContentType: true),
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
      throw ApiErrorParser.fromResponse(
        statusCode: response.statusCode,
        body: response.body,
        fallbackMessage: 'No se pudo crear el gasto fijo',
      );
    }
  }

  Future<void> updateFixedExpense({
    required int id,
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
    final uri = Uri.parse('${ApiConfig.baseUrl}/fixed-expenses/$id');

    final response = await http.put(
      uri,
      headers: await ApiHeaders.auth(includeJsonContentType: true),
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

    if (response.statusCode != 200) {
      throw ApiErrorParser.fromResponse(
        statusCode: response.statusCode,
        body: response.body,
        fallbackMessage: 'No se pudo actualizar el gasto fijo',
      );
    }
  }

  Future<void> deleteFixedExpense(int id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/fixed-expenses/$id');

    final response = await http.delete(
      uri,
      headers: await ApiHeaders.auth(),
    );

    if (response.statusCode != 200) {
      throw ApiErrorParser.fromResponse(
        statusCode: response.statusCode,
        body: response.body,
        fallbackMessage: 'No se pudo eliminar el gasto fijo',
      );
    }
  }
}