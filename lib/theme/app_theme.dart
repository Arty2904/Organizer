import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Terracotta accent (from mockup)
  static const terracotta = Color(0xFFD07840);
  static const terracottaLight = Color(0xFFE8A870);
  static const terracottaDim = Color(0x3FD07840);

  // Dark theme
  static const darkBg = Color(0xFF1A1A1A);
  static const darkSurface = Color(0xFF252525);
  static const darkCard = Color(0xFF2E2E2E);
  static const darkCardAlt = Color(0xFF333333);
  static const darkDivider = Color(0xFF383838);
  static const darkText = Color(0xFFEEEEEE);
  static const darkTextSecondary = Color(0xFF999999);
  static const darkTextMuted = Color(0xFF666666);

  // Light theme
  static const lightBg = Color(0xFFF5F0EB);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightCardAlt = Color(0xFFF8F3EE);
  static const lightDivider = Color(0xFFE8E0D8);
  static const lightText = Color(0xFF1A1A1A);
  static const lightTextSecondary = Color(0xFF666666);
  static const lightTextMuted = Color(0xFF999999);

  // Category colors (dot indicators)
  static const cat1 = Color(0xFFD07840); // terracotta
  static const cat2 = Color(0xFF6B8F71); // sage
  static const cat3 = Color(0xFF7A8FA6); // steel blue
  static const cat4 = Color(0xFFB57BA6); // mauve
  static const cat5 = Color(0xFFD4A96A); // gold

  static Color categoryColor(String category) {
    final map = {
      'Работа': cat1,
      'Личное': cat2,
      'Путешествия': cat3,
      'Рецепты': cat4,
      'Идеи': cat5,
      'Дом': cat2,
    };
    return map[category] ?? cat1;
  }
}

ThemeData buildTheme(bool dark) {
  final base = dark ? ThemeData.dark() : ThemeData.light();
  final bg = dark ? AppColors.darkBg : AppColors.lightBg;
  final surface = dark ? AppColors.darkSurface : AppColors.lightSurface;
  final card = dark ? AppColors.darkCard : AppColors.lightCard;
  final text = dark ? AppColors.darkText : AppColors.lightText;
  final textSec = dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  final divider = dark ? AppColors.darkDivider : AppColors.lightDivider;

  return base.copyWith(
    useMaterial3: true,
    scaffoldBackgroundColor: bg,
    colorScheme: (dark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
      primary: AppColors.terracotta,
      secondary: AppColors.terracotta,
      surface: surface,
      onSurface: text,
    ),
    cardColor: card,
    dividerColor: divider,
    textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
      bodyMedium: GoogleFonts.dmSans(color: text, fontSize: 13),
      bodySmall: GoogleFonts.dmSans(color: textSec, fontSize: 11),
      titleMedium: GoogleFonts.fraunces(color: text, fontSize: 15, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.fraunces(color: text, fontSize: 22, fontWeight: FontWeight.w600),
      headlineMedium: GoogleFonts.fraunces(color: text, fontSize: 26, fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.fraunces(
        color: text,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
      ),
      iconTheme: IconThemeData(color: text),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? AppColors.darkCard : AppColors.lightCardAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      hintStyle: TextStyle(color: textSec, fontSize: 13),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: AppColors.terracotta,
      unselectedItemColor: textSec,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 10),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: dark ? AppColors.darkCard : AppColors.lightCardAlt,
      selectedColor: AppColors.terracotta,
      labelStyle: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.terracotta,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
  );
}
