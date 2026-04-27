import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFB5C0D0), // Pastel Blue/Grey
      primary: const Color(0xFF8E9AAF), // Pastel Navy
      secondary: const Color(0xFFCBC0D3), // Pastel Purple
      tertiary: const Color(0xFFEFD3D7), // Pastel Pink
      surface: const Color(0xFFFEEAFA), // Very light pastel background
      background: const Color(0xFFF8F9FA),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurface.withOpacity(0.6)),
        selectedLabelTextStyle: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
        unselectedLabelTextStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
      ),
    );
  }
}
