import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Font options (единый набор для интерфейса и контента) ──
const kFontOptions = [
  ('fraunces',       'Fraunces',        'Выразительный serif'),
  ('playfair',       'Playfair Display', 'Как NYT — газетный'),
  ('lora',           'Lora',            'Мягкий книжный serif'),
  ('dm_sans',        'DM Sans',         'Чистый гротеск'),
  ('nunito',         'Nunito',          'Округлый дружелюбный'),
  ('sacramento',     'Sacramento',      'Каллиграфический'),
  ('dancing_script', 'Dancing Script',  'Игривый рукописный'),
];

// Псевдоним — используется в пикере контентного шрифта
const kContentFontOptions = kFontOptions;

/// Шрифт для UI-заголовков и названий элементов приложения.
TextStyle appTitleStyle(String font, {
  double size = 15,
  FontWeight weight = FontWeight.w600,
  Color? color,
  FontStyle? fontStyle,
}) {
  final effectiveWeight = (font == 'sacramento' || font == 'dancing_script')
      ? FontWeight.w400
      : weight;

  switch (font) {
    case 'playfair':
      return GoogleFonts.playfairDisplay(
          fontSize: size, fontWeight: effectiveWeight, color: color,
          fontStyle: fontStyle ?? FontStyle.normal);
    case 'lora':
      return GoogleFonts.lora(
          fontSize: size, fontWeight: effectiveWeight, color: color,
          fontStyle: fontStyle ?? FontStyle.normal);
    case 'dm_sans':
      return GoogleFonts.dmSans(
          fontSize: size, fontWeight: effectiveWeight, color: color);
    case 'nunito':
      return GoogleFonts.nunito(
          fontSize: size, fontWeight: effectiveWeight, color: color);
    case 'sacramento':
      return GoogleFonts.sacramento(
          fontSize: size, fontWeight: effectiveWeight, color: color);
    case 'dancing_script':
      return GoogleFonts.dancingScript(
          fontSize: size, fontWeight: effectiveWeight, color: color);
    default: // fraunces
      return GoogleFonts.fraunces(
          fontSize: size, fontWeight: effectiveWeight, color: color,
          fontStyle: fontStyle ?? FontStyle.normal);
  }
}

/// Шрифт для контента пользователя (тело заметок, задачи, описания событий).
TextStyle contentStyle(String font, {
  double size = 14,
  FontWeight weight = FontWeight.w400,
  Color? color,
  double height = 1.6,
}) {
  final effectiveWeight = (font == 'sacramento' || font == 'dancing_script')
      ? FontWeight.w400
      : weight;

  switch (font) {
    case 'playfair':
      return GoogleFonts.playfairDisplay(
          fontSize: size, fontWeight: effectiveWeight, color: color, height: height);
    case 'lora':
      return GoogleFonts.lora(
          fontSize: size, fontWeight: effectiveWeight, color: color, height: height);
    case 'nunito':
      return GoogleFonts.nunito(
          fontSize: size, fontWeight: effectiveWeight, color: color, height: height);
    case 'sacramento':
      return GoogleFonts.sacramento(
          fontSize: size, fontWeight: effectiveWeight, color: color, height: height);
    case 'dancing_script':
      return GoogleFonts.dancingScript(
          fontSize: size, fontWeight: effectiveWeight, color: color, height: height);
    case 'dm_sans':
      return GoogleFonts.dmSans(
          fontSize: size, fontWeight: effectiveWeight, color: color, height: height);
    default: // fraunces
      return GoogleFonts.fraunces(
          fontSize: size, fontWeight: effectiveWeight, color: color, height: height);
  }
}
