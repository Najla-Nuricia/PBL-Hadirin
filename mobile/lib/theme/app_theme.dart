import 'package:flutter/material.dart';

abstract final class AppTheme {
  static final ThemeData light = ThemeData(
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF0066FF),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE5F0FF),
      onPrimaryContainer: Color(0xFF003399),
      secondary: Color(0xFF10B981),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFD1FAE5),
      onSecondaryContainer: Color(0xFF065F46),
      tertiary: Color(0xFFF5A623),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFFEF3C7),
      onTertiaryContainer: Color(0xFF92400E),
      surface: Colors.white,
      surfaceContainerHighest: Color(0xFFF4F6F9),
      onSurface: Color(0xFF1A1A1A),
      onSurfaceVariant: Color(0xFF9E9E9E),
      outline: Color(0xFFE0E0E0),
      outlineVariant: Color(0xFFF0F0F0),
      error: Color(0xFFEF4444),
      onError: Colors.white,
      errorContainer: Color(0xFFFEE2E2),
      onErrorContainer: Color(0xFF991B1B),
    ),
  );
}
