import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_auth.dart';
import '../config/api_config.dart';
import '../models/monthly_dashboard.dart';

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
      headers: const {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${ApiAuth.bearerToken}',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load monthly dashboard. '
            'Status: ${response.statusCode}. '
            'Body: ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    return MonthlyDashboard.fromJson(json);
  }
}