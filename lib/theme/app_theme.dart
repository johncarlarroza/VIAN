import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF1F6D44);
  static const bg = Color(0xFFF5F7F8);

  static ThemeData light() {
    return ThemeData(
      scaffoldBackgroundColor: bg,
      primaryColor: primary,
      fontFamily: 'Inter', // optional

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
