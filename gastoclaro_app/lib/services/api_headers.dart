import 'auth_storage_service.dart';

class ApiHeaders {
  static Future<Map<String, String>> auth({
    bool includeJsonContentType = false,
  }) async {
    final token = await AuthStorageService().getToken();

    return {
      'Accept': 'application/json',
      if (includeJsonContentType) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, String> jsonWithoutAuth() {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }
}