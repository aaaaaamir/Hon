import 'package:flutter/material.dart';

/// پالت رنگی الهام‌گرفته از نسخه‌ی وب، با کمی بهبود کنتراست برای Material 3.
class AppColors {
  AppColors._();
  static const bg = Color(0xFF0B0D12);
  static const bgElev = Color(0xFF12151D);
  static const card = Color(0xFF171B25);
  static const card2 = Color(0xFF1E2330);
  static const line = Color(0xFF262C3A);
  static const accent = Color(0xFF5B8CFF);
  static const accent2 = Color(0xFF7C5CFF);
  static const text = Color(0xFFEEF1F7);
  static const muted = Color(0xFF8A91A3);
  static const green = Color(0xFF34D399);
  static const red = Color(0xFFF87171);
  static const orange = Color(0xFFFBBF24);
  static const bubbleThem = Color(0xFF1E2330);

  static const bubbleMe = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F7DF3), Color(0xFF6B5CF0)],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accent2],
  );
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);

  // به‌جای دانلود فونت وزیرمتن از اینترنت (که در شبکه‌های فیلترشده ممکنه
  // گیر کنه و باعث کرش/جعبه‌ی خاکستری بشه)، از فونت پیش‌فرض سیستم استفاده
  // می‌کنیم که همیشه در دسترسه و از فارسی هم به‌خوبی پشتیبانی می‌کنه.
  final textTheme = base.textTheme.apply(
    bodyColor: AppColors.text,
    displayColor: AppColors.text,
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.accent,
      secondary: AppColors.accent2,
      surface: AppColors.card,
      error: AppColors.red,
    ),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      iconTheme: const IconThemeData(color: AppColors.text),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgElev,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
      ),
      hintStyle: const TextStyle(color: AppColors.muted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.accent),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.bgElev,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.muted,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.card2,
      contentTextStyle: textTheme.bodyMedium,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
