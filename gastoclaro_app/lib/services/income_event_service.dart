import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/income_event.dart';
import 'api_headers.dart';

class IncomeEventService {
  Future<List<IncomeEvent>> getIncomeEvents({
    required int year,
    required int month,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/income-events?year=$year&month=$month',
    );

    final response = await http.get(
      uri,
      headers: await ApiHeaders.auth(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load income events. '
            'Status: ${response.statusCode}. '
            'Body: ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as List<dynamic>;

    return json
        .map((item) => IncomeEvent.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> createIncomeEvent({
    int? incomeSourceId,
    required String title,
    required double amount,
    required String currency,
    required String expectedDate,
    String? receivedDate,
    required String status,
    String? notes,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/income-events');

    final response = await http.post(
      uri,
      headers: await ApiHeaders.auth(includeJsonContentType: true),
      body: jsonEncode({
        'income_source_id': incomeSourceId,
        'title': title,
        'amount': amount,
        'currency': currency,
        'expected_date': expectedDate,
        'received_date': receivedDate,
        'status': status,
        'notes': notes,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Failed to create income event. '
            'Status: ${response.statusCode}. '
            'Body: ${response.body}',
      );
    }
  }

  Future<void> updateIncomeEvent({
    required int id,
    int? incomeSourceId,
    required String title,
    required double amount,
    required String currency,
    required String expectedDate,
    String? receivedDate,
    required String status,
    String? notes,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/income-events/$id');

    final response = await http.put(
      uri,
      headers: await ApiHeaders.auth(includeJsonContentType: true),
      body: jsonEncode({
        'income_source_id': incomeSourceId,
        'title': title,
        'amount': amount,
        'currency': currency,
        'expected_date': expectedDate,
        'received_date': receivedDate,
        'status': status,
        'notes': notes,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update income event. '
            'Status: ${response.statusCode}. '
            'Body: ${response.body}',
      );
    }
  }

  Future<void> deleteIncomeEvent(int id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/income-events/$id');

    final response = await http.delete(
      uri,
      headers: await ApiHeaders.auth(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to delete income event. '
            'Status: ${response.statusCode}. '
            'Body: ${response.body}',
      );
    }
  }
}