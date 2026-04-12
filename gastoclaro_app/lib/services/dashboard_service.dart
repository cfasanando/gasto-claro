import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/monthly_dashboard.dart';
import '../utils/api_error_parser.dart';
import 'api_headers.dart';

class DashboardService {
  Future<MonthlyDashboard> getMonthlyDashboard({
    required int year,
    required int month,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/dashboard/monthly?year=$year&month=$month',
    );

    final response = await http.get(
      uri,
      headers: await ApiHeaders.auth(),
    );

    if (response.statusCode != 200) {
      throw ApiErrorParser.fromResponse(
        statusCode: response.statusCode,
        body: response.body,
        fallbackMessage: 'No se pudo cargar el panel mensual',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    return MonthlyDashboard.fromJson(json);
  }
}