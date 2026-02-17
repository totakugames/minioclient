import 'package:flutter/material.dart';

class AppTheme {
  static const _primaryColor = Color(0xFF6C63FF);
  static const _surfaceColor = Color(0xFF1E1E2E);
  static const _backgroundColor = Color(0xFF14141F);
  static const _cardColor = Color(0xFF252538);
  static const _borderColor = Color(0xFF2E2E42);

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: _primaryColor,
          secondary: Color(0xFF45D9A8),
          surface: _surfaceColor,
          error: Color(0xFFFF6B6B),
        ),
        scaffoldBackgroundColor: _backgroundColor,
        cardColor: _cardColor,
        dividerColor: _borderColor,
        fontFamily: 'Segoe UI',
        appBarTheme: const AppBarTheme(
          backgroundColor: _surfaceColor,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _primaryColor, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: _primaryColor),
        ),
        iconTheme: const IconThemeData(color: Colors.white70, size: 20),
        listTileTheme: const ListTileThemeData(
          dense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _borderColor),
          ),
        ),
      );
}
