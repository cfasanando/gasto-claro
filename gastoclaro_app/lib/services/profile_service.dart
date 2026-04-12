import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/app_user.dart';
import '../utils/api_error_parser.dart';
import 'api_headers.dart';

class ProfileService {
  Future<AppUser> getMe() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/me');

    final response = await http.get(
      uri,
      headers: await ApiHeaders.auth(),
    );

    if (response.statusCode != 200) {
      throw ApiErrorParser.fromResponse(
        statusCode: response.statusCode,
        body: response.body,
        fallbackMessage: 'No se pudo cargar el perfil',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    return AppUser.fromJson(json);
  }
}