import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/app_user.dart';
import 'api_headers.dart';

class ProfileService {
  Future<AppUser> getMe() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/me');

    final response = await http.get(
      uri,
      headers: await ApiHeaders.auth(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load profile. '
            'Status: ${response.statusCode}. '
            'Body: ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    return AppUser.fromJson(json);
  }
}