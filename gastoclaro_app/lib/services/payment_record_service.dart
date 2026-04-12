import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/payment_record.dart';
import 'api_headers.dart';

class PaymentRecordService {
  Future<List<PaymentRecord>> getMonthlyRecords({
    required int year,
    required int month,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/payment-records?year=$year&month=$month',
    );

    final response = await http.get(
      uri,
      headers: await ApiHeaders.auth(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load payment records. '
            'Status: ${response.statusCode}. '
            'Body: ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as List<dynamic>;

    return json
        .map((item) => PaymentRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> createPaymentRecord({
    required int paymentObligationId,
    required double paidAmount,
    required String currency,
    required String paidAt,
    required String paymentMethod,
    String? note,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/payment-records');

    final response = await http.post(
      uri,
      headers: await ApiHeaders.auth(includeJsonContentType: true),
      body: jsonEncode({
        'payment_obligation_id': paymentObligationId,
        'paid_amount': paidAmount,
        'currency': currency,
        'paid_at': paidAt,
        'payment_method': paymentMethod,
        'note': note,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Failed to create payment record. '
            'Status: ${response.statusCode}. '
            'Body: ${response.body}',
      );
    }
  }
}