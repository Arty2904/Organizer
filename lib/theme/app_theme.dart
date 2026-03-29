import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── Акценты ───────────────────────────────────────────────
  static const terracotta      = Color(0xFFD07840); // dark accent
  static const terracottaLight = Color(0xFFC8805A); // light accent
  static const terracottaDark2 = Color(0xFF9A4E18); // dark gradient end
  static const terracottaLight2 = Color(0xFF8B5230); // light gradient end

  // ── Тёмная тема ───────────────────────────────────────────
  // Макет: --bg:#1E2028  --bg2:#1A1C24
  static const darkBg        = Color(0xFF1E2028);
  static const darkBg2       = Color(0xFF1A1C24);
  static const darkSurface   = Color(0xFF1E2028);
  // Макет: --text:#F0EAE0
  static const darkText      = Color(0xFFF0EAE0);
  // Макет: --body:rgba(230,200,165,0.52)
  static const darkTextBody  = Color(0x85E6C8A5);
  // Макет: --date:rgba(230,175,120,0.35)
  static const darkTextDate  = Color(0x59E6AF78);
  static const darkTextMuted = Color(0x59E6AF78);
  // Макет: --border:rgba(255,255,255,0.07)
  static const darkDivider   = Color(0x12FFFFFF);
  static const darkCardBorder = Color(0x12FFFFFF);
  // Макет: --srch-bg:rgba(255,255,255,0.06)
  static const darkSearchBg  = Color(0x0FFFFFFF);
  static const darkSearchBd  = Color(0x1AFFFFFF);
  // Макет: --nav-dim:rgba(230,175,120,0.32)
  static const darkNavDim    = Color(0x52E6AF78);
  static const darkNavBg     = Color(0x05FFFFFF); // rgba(255,255,255,0.02)
  // Макет: --hbtn-bg:rgba(255,255,255,0.07)
  static const darkHamBg     = Color(0x12FFFFFF);
  static const darkHamBd     = Color(0x21FFFFFF);
  // Макет: --hbtn-sp:rgba(255,255,255,0.7)
  static const darkHamSp     = Color(0xB3FFFFFF);

  // Цвета карточек по категории (тёмная тема, ~10% overlay)
  // nc1=green nc2=yellow nc3=blue nc4=red
  static const darkCard1 = Color(0x1A64AA46); // rgba(100,170,70,0.10)
  static const darkCard2 = Color(0x1ADCB43C); // rgba(220,180,60,0.10)
  static const darkCard3 = Color(0x1A468CDC); // rgba(70,140,220,0.10)
  static const darkCard4 = Color(0x1ADC5A46); // rgba(220,90,70,0.10)
  static const darkCard5 = Color(0x1AD07840); // терракота
  static const darkCardDefault = Color(0x0FFFFFFF);

  // ── Светлая тема ──────────────────────────────────────────
  // Макет: --bg:#EDE4D4  --bg2:#E5DAC8
  static const lightBg       = Color(0xFFEDE4D4);
  static const lightBg2      = Color(0xFFE5DAC8);
  static const lightSurface  = Color(0xFFEDE4D4);
  // Макет: --text:#241406
  static const lightText     = Color(0xFF241406);
  // Макет: --body:rgba(80,50,20,0.65)
  static const lightTextBody = Color(0xA6503214);
  // Макет: --date:rgba(120,80,40,0.52)
  static const lightTextDate = Color(0x85785028);
  static const lightTextMuted = Color(0x85785028);
  // Макет: --border:rgba(160,120,60,0.2)
  static const lightDivider  = Color(0x33A0783C);
  static const lightCardBorder = Color(0x24A0783C);
  // Макет: --srch-bg:rgba(255,255,255,0.55)
  static const lightSearchBg = Color(0x8CFFFFFF);
  static const lightSearchBd = Color(0x38A0783C);
  // Макет: --nav-dim:rgba(120,80,40,0.38)
  static const lightNavDim   = Color(0x61785028);
  // Макет: --hbtn-bg:rgba(160,120,60,0.13)
  static const lightHamBg    = Color(0x21A0783C);
  static const lightHamBd    = Color(0x47A0783C);
  // Макет: --hbtn-sp:#6B4120
  static const lightHamSp    = Color(0xFF6B4120);

  // Цвета карточек по категории (светлая тема, ~13% overlay)
  static const lightCard1 = Color(0x2150A050); // rgba(100,160,80,0.13) green
  static const lightCard2 = Color(0x21C8A028); // rgba(200,160,40,0.13) yellow
  static const lightCard3 = Color(0x1A3C78D2); // rgba(60,120,210,0.10) blue
  static const lightCard4 = Color(0x1AC8503C); // rgba(200,80,60,0.10) red
  static const lightCard5 = Color(0x21C8805A); // терракота
  static const lightCardDefault = Color(0x21FFFFFF);

  // ── Вспомогательные ──────────────────────────────────────
  static const darkTextSecondary  = darkTextDate;
  static const lightTextSecondary = lightTextDate;
  static const darkCard           = darkCardDefault;
  static const lightCard          = lightCardDefault;
  static const lightCardAlt       = lightBg2;
  static const darkCardAlt        = darkBg2;

  // ── Цвета категорий (точки и теги) ────────────────────────
  // '' = нет тега (прочерк)
  static const catNone = Color(0x80A09080); // neutral muted
  static const cat1 = Color(0xFF88CC55); // Работа   — green
  static const cat2 = Color(0xFFD07840); // Личное   — terracotta
  static const cat3 = Color(0xFF60A8F0); // Путешест — blue
  static const cat4 = Color(0xFFF07060); // Рецепты  — red
  static const cat5 = Color(0xFFDCB43C); // Идеи     — yellow
  static const cat6 = Color(0xFF88CC55); // Дом      — green

  static Color categoryColor(String category) {
    if (category.isEmpty) return catNone;
    const map = {
      'Работа':      cat1,
      'Личное':      cat2,
      'Путешествия': cat3,
      'Рецепты':     cat4,
      'Идеи':        cat5,
      'Дом':         cat6,
      'Финансы':     cat3,
      'Здоровье':    cat4,
      'Учёба':       cat5,
      'Проекты':     cat1,
      'Разное':      cat2,
      'Праздники':   cat4,
      'Спорт':       cat1,
    };
    return map[category] ?? cat2;
  }

  // Фон карточки по категории
  static Color cardBgDark(String category) {
    if (category.isEmpty) return const Color(0x0DFFFFFF);
    const map = {
      'Работа':      darkCard1,
      'Личное':      darkCard2,
      'Путешествия': darkCard3,
      'Рецепты':     darkCard4,
      'Идеи':        darkCard2,
      'Дом':         darkCard1,
      'Финансы':     darkCard3,
      'Здоровье':    darkCard4,
      'Учёба':       darkCard2,
      'Проекты':     darkCard1,
      'Разное':      darkCard5,
      'Праздники':   darkCard4,
      'Спорт':       darkCard1,
    };
    return map[category] ?? const Color(0x0DFFFFFF);
  }

  static Color cardBgLight(String category) {
    if (category.isEmpty) return const Color(0x40FFFFFF);
    const map = {
      'Работа':      lightCard1,
      'Личное':      lightCard2,
      'Путешествия': lightCard3,
      'Рецепты':     lightCard4,
      'Идеи':        lightCard2,
      'Дом':         lightCard1,
      'Финансы':     lightCard3,
      'Здоровье':    lightCard4,
      'Учёба':       lightCard2,
      'Проекты':     lightCard1,
      'Разное':      lightCard5,
      'Праздники':   lightCard4,
      'Спорт':       lightCard1,
    };
    return map[category] ?? const Color(0x40FFFFFF);
  }
}

ThemeData buildTheme(bool dark) {
  final base = dark ? ThemeData.dark() : ThemeData.light();
  final bg      = dark ? AppColors.darkBg      : AppColors.lightBg;
  final surface = dark ? AppColors.darkSurface  : AppColors.lightSurface;
  final text    = dark ? AppColors.darkText     : AppColors.lightText;
  final textSec = dark ? AppColors.darkTextDate : AppColors.lightTextDate;
  final divider = dark ? AppColors.darkDivider  : AppColors.lightDivider;
  final accent  = dark ? AppColors.terracotta   : AppColors.terracottaLight;

  return base.copyWith(
    useMaterial3: true,
    scaffoldBackgroundColor: dark ? AppColors.darkBg2 : AppColors.lightBg2,
    colorScheme: (dark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
      primary: accent,
      secondary: accent,
      surface: surface,
      onSurface: text,
    ),
    cardColor: dark ? AppColors.darkCardDefault : AppColors.lightCardDefault,
    dividerColor: divider,
    textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
      bodyMedium: GoogleFonts.dmSans(color: text, fontSize: 13, height: 1.5),
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
        fontSize: 15,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
      ),
      iconTheme: IconThemeData(color: text),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: dark ? AppColors.darkBg : AppColors.lightBg,
      selectedColor: accent,
      labelStyle: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accent,
      foregroundColor: Colors.white,
      elevation: 6,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: surface,
    ),
  );
}
