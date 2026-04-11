import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class PingService {
  Future<Map<String, dynamic>> ping() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/ping'),
      headers: const {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load API ping. Status: ${response.statusCode}. Body: ${response.body}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}