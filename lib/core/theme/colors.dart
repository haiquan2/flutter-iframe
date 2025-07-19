import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}

class AppColors {
  static const background = Color.fromARGB(91, 210, 220, 206); 
  static const sideNav = Color(0xFFF4F4F5); 
  static const searchBar = Color(0xFFF0F2FF); 
  static const searchBarBorder = Color(0xFFD1D9FF); 
  static const iconGrey = Color(0xFF6B7280); 
  static const textGrey = Color(0xFF4B5563); 
  static const footerGrey = Color(0xFF9CA3AF); 
  static const proButton = Color(0xFFEEF2FF); 
  static const cardColor = Color(0xFFFBFCFF); 
  static const submitButton = Color(0xFF6366F1); 
  static const whiteColor = Colors.white;
  
  
  static const primaryPurple = Color(0xFF8B5CF6); 
  static const lightPurple = Color(0xFFE5E7EB); 
  static const accentBlue = Color(0xFF3B82F6); 
  static const softLavender = Color(0xFFF3F4F6); 
}