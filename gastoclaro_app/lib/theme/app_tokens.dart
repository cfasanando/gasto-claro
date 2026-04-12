import 'package:flutter/material.dart';

abstract final class AppTokens {
  static const Color primary = Color(0xFF5B5CE2);
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color secondary = Color(0xFF14B8A6);

  static const Color success = Color(0xFF10B981);
  static const Color info = Color(0xFF0EA5E9);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  static const Color ink900 = Color(0xFF0F172A);
  static const Color ink700 = Color(0xFF334155);
  static const Color ink500 = Color(0xFF64748B);

  static const Color background = Color(0xFFF4F7FB);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color outline = Color(0xFFE2E8F0);

  static const double radiusXs = 14;
  static const double radiusSm = 18;
  static const double radiusMd = 24;
  static const double radiusLg = 30;
  static const double radiusXl = 36;

  static const double spaceXs = 8;
  static const double spaceSm = 12;
  static const double spaceMd = 16;
  static const double spaceLg = 20;
  static const double spaceXl = 24;
  static const double space2xl = 32;

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF5B5CE2),
      Color(0xFF4338CA),
      Color(0xFF0F172A),
    ],
  );
}