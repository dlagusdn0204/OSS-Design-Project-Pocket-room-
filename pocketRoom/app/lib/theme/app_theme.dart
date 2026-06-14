// 앱 전체 색상·폰트·테마 정의

import 'package:flutter/material.dart';

class AppTheme {
  // 주요 색상
  static const Color primary = Color(0xFF3B5BDB);       // 인디고 블루 (메인)
  static const Color primaryLight = Color(0xFFEDF2FF);  // 연한 인디고
  static const Color secondary = Color(0xFF20C997);     // 틸 그린 (강조)
  static const Color background = Color(0xFFF8F9FA);    // 배경 회색
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFFA5252);
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);

  // 카드별 색상
  static const Color contractColor = Color(0xFF74C0FC);   // 연파랑 — 계약 카드
  static const Color electricityColor = Color(0xFFFFD43B); // 노랑 — 전기 카드
  static const Color gasColor = Color(0xFFFF8787);         // 연빨강 — 가스 카드

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          surface: surface,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: textPrimary,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: primaryLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
}
