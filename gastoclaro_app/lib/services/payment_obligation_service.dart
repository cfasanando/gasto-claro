import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/payment_obligation.dart';
import '../utils/api_error_parser.dart';
import 'api_headers.dart';

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
      headers: await ApiHeaders.auth(),
    );

    if (response.statusCode != 200) {
      throw ApiErrorParser.fromResponse(
        statusCode: response.statusCode,
        body: response.body,
        fallbackMessage: 'No se pudieron cargar las obligaciones',
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
      '${ApiConfig.baseUrl}/sync-monthly-obligations?year=$year&month=$month',
    );

    final response = await http.post(
      uri,
      headers: await ApiHeaders.auth(),
    );

    if (response.statusCode != 200) {
      throw ApiErrorParser.fromResponse(
        statusCode: response.statusCode,
        body: response.body,
        fallbackMessage: 'No se pudieron sincronizar las obligaciones',
      );
    }
  }
}