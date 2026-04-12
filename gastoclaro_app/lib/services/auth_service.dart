import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_headers.dart';
import 'auth_storage_service.dart';

class AuthService {
  final AuthStorageService authStorageService = AuthStorageService();

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/login');

    final response = await http.post(
      uri,
      headers: ApiHeaders.jsonWithoutAuth(),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to login. '
            'Status: ${response.statusCode}. '
            'Body: ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final token = json['token']?.toString();

    if (token == null || token.isEmpty) {
      throw Exception('Token not found in login response.');
    }

    await authStorageService.saveToken(token);
  }

  Future<bool> restoreSession() async {
    final token = await authStorageService.getToken();

    if (token == null || token.isEmpty) {
      return false;
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/me');

    final response = await http.get(
      uri,
      headers: await ApiHeaders.auth(),
    );

    if (response.statusCode == 200) {
      return true;
    }

    await authStorageService.clearToken();

    return false;
  }

  Future<void> logout() async {
    final token = await authStorageService.getToken();

    if (token != null && token.isNotEmpty) {
      final uri = Uri.parse('${ApiConfig.baseUrl}/logout');

      try {
        await http.post(
          uri,
          headers: await ApiHeaders.auth(),
        );
      } catch (_) {
      }
    }

    await authStorageService.clearToken();
  }
}