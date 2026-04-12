import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_auth.dart';
import '../config/api_config.dart';
import '../models/payment_obligation.dart';

class PaymentObligationService {
  Future<List<PaymentObligation>> getMonthlyObligations({
    required int year,
    required int month,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/payment-obligations?year=$year&month=$month',
    );

    final response = await http.get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${ApiAuth.bearerToken}',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load payment obligations. '
            'Status: ${response.statusCode}. '
            'Body: ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as List<dynamic>;

    return json
        .map((item) => PaymentObligation.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> syncMonthly({
    required int year,
    required int month,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/payment-obligations/sync-monthly?year=$year&month=$month',
    );

    final response = await http.post(
      uri,
      headers: const {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${ApiAuth.bearerToken}',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to sync monthly obligations. '
            'Status: ${response.statusCode}. '
            'Body: ${response.body}',
      );
    }
  }
}