import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/income_source.dart';
import 'api_headers.dart';

class IncomeSourceService {
  Future<List<IncomeSource>> getIncomeSources() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/income-sources');

    final response = await http.get(
      uri,
      headers: await ApiHeaders.auth(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load income sources. '
            'Status: ${response.statusCode}. '
            'Body: ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as List<dynamic>;

    return json
        .map((item) => IncomeSource.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> createIncomeSource({
    required String name,
    required String type,
    double? defaultAmount,
    required String currency,
    required bool isActive,
    String? notes,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/income-sources');

    final response = await http.post(
      uri,
      headers: await ApiHeaders.auth(includeJsonContentType: true),
      body: jsonEncode({
        'name': name,
        'type': type,
        'default_amount': defaultAmount,
        'currency': currency,
        'is_active': isActive,
        'notes': notes,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Failed to create income source. '
            'Status: ${response.statusCode}. '
            'Body: ${response.body}',
      );
    }
  }

  Future<void> updateIncomeSource({
    required int id,
    required String name,
    required String type,
    double? defaultAmount,
    required String currency,
    required bool isActive,
    String? notes,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/income-sources/$id');

    final response = await http.put(
      uri,
      headers: await ApiHeaders.auth(includeJsonContentType: true),
      body: jsonEncode({
        'name': name,
        'type': type,
        'default_amount': defaultAmount,
        'currency': currency,
        'is_active': isActive,
        'notes': notes,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update income source. '
            'Status: ${response.statusCode}. '
            'Body: ${response.body}',
      );
    }
  }

  Future<void> deleteIncomeSource(int id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/income-sources/$id');

    final response = await http.delete(
      uri,
      headers: await ApiHeaders.auth(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to delete income source. '
            'Status: ${response.statusCode}. '
            'Body: ${response.body}',
      );
    }
  }
}