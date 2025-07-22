import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF31572C);
  static const Color lightGreen = Color(0xFF4ADE80);
  static const Color beigeBackground = Color(0xFFFEFAE0);
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    primaryColor: primaryGreen,
    colorScheme: const ColorScheme.light(
      primary: primaryGreen,
      secondary: lightGreen,
      surface: Colors.white,
      background: Colors.white,
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      color: Color(0xFFF8F9FA), // A very light grey for cards
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: primaryGreen,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    primaryColor: lightGreen,
    colorScheme: const ColorScheme.dark(
      primary: lightGreen,
      secondary: primaryGreen,
      surface: darkCard,
      background: darkBackground,
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      color: darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: lightGreen,
      unselectedItemColor: Colors.grey,
      backgroundColor: darkCard,
      type: BottomNavigationBarType.fixed,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkCard,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
  );
}
