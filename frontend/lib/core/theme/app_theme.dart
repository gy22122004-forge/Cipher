import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg        = Color(0xFFF5F5F7);
  static const white     = Color(0xFFFFFFFF);
  static const blue      = Color(0xFF2563EB);
  static const blueLight = Color(0xFFEFF6FF);
  static const blueMid   = Color(0xFFDBEAFE);
  static const green     = Color(0xFF059669);
  static const greenLight= Color(0xFFECFDF5);
  static const amber     = Color(0xFFD97706);
  static const amberLight= Color(0xFFFFFBEB);
  static const red       = Color(0xFFDC2626);
  static const redLight  = Color(0xFFFEF2F2);
  static const purple    = Color(0xFF7C3AED);
  static const purpleLight= Color(0xFFF5F3FF);
  static const text      = Color(0xFF09090B);
  static const text2     = Color(0xFF3F3F46);
  static const text3     = Color(0xFF71717A);
  static const text4     = Color(0xFFA1A1AA);
  static const border    = Color(0xFFE4E4E7);
  static const borderLight = Color(0xFFF4F4F5);
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      surface: AppColors.bg,
    ),
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    cardTheme: CardThemeData(
      color: AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: AppColors.border,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
        letterSpacing: -0.3,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.blue, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.red)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.red, width: 2)),
      labelStyle: GoogleFonts.inter(color: AppColors.text3, fontSize: 14),
      hintStyle: GoogleFonts.inter(color: AppColors.text4, fontSize: 14),
      prefixIconColor: AppColors.text3,
      suffixIconColor: AppColors.text3,
      errorStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.red),
    ),
    chipTheme: ChipThemeData(
      labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
    listTileTheme: ListTileThemeData(
      titleTextStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
      subtitleTextStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.text3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentTextStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.blue,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
  );
}
