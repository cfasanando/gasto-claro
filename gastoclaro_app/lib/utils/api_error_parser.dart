import 'dart:convert';

import '../models/api_exception.dart';

class ApiErrorParser {
  static ApiException fromResponse({
    required int statusCode,
    required String body,
    required String fallbackMessage,
  }) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        final message = decoded['message']?.toString().trim();

        final errors = decoded['errors'];
        if (errors is Map<String, dynamic> && errors.isNotEmpty) {
          final buffer = <String>[];

          for (final entry in errors.entries) {
            final value = entry.value;
            if (value is List) {
              for (final item in value) {
                final text = item?.toString().trim();
                if (text != null && text.isNotEmpty) {
                  buffer.add(text);
                }
              }
            } else {
              final text = value?.toString().trim();
              if (text != null && text.isNotEmpty) {
                buffer.add(text);
              }
            }
          }

          if (buffer.isNotEmpty) {
            return ApiException(
              buffer.join('\n'),
              statusCode: statusCode,
            );
          }
        }

        if (message != null && message.isNotEmpty) {
          return ApiException(
            message,
            statusCode: statusCode,
          );
        }
      }
    } catch (_) {
      // Ignore JSON parsing errors and fall back to generic message.
    }

    return ApiException(
      fallbackMessage,
      statusCode: statusCode,
    );
  }
}