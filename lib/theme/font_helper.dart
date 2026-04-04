import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Font options (единый набор для интерфейса и контента) ──
const kFontOptions = [
  ('fraunces',      'Fraunces',        'Выразительный serif'),
  ('playfair',      'Playfair Display', 'Как NYT — газетный'),
  ('lora',          'Lora',            'Мягкий книжный serif'),
  ('dm_sans',       'DM Sans',         'Чистый гротеск'),
  ('nunito',        'Nunito',          'Округлый дружелюбный'),
  ('lobster',       'Lobster',         'Декоративный ретро'),
  ('caveat',        'Caveat',          'Быстрый почерк'),
  ('bad_script',    'Bad Script',      'Школьная пропись'),
  ('shantell_sans', 'Shantell Sans',   'Маркер-рукопись'),
  ('marck_script',  'Marck Script',    'Каллиграфический'),
];

// Псевдоним — используется в пикере контентного шрифта
const kContentFontOptions = kFontOptions;

// Шрифты с фиксированным w400 (не поддерживают bold)
bool _fixedWeight(String font) =>
    font == 'lobster' || font == 'bad_script' || font == 'marck_script';

/// Шрифт для UI-заголовков и названий элементов приложения.
TextStyle appTitleStyle(String font, {
  double size = 15,
  FontWeight weight = FontWeight.w600,
  Color? color,
  FontStyle? fontStyle,
}) {
  final effectiveWeight = _fixedWeight(font) ? FontWeight.w400 : weight;

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
    case 'lobster':
      return GoogleFonts.lobster(
          fontSize: size, fontWeight: effectiveWeight, color: color);
    case 'caveat':
      return GoogleFonts.caveat(
          fontSize: size, fontWeight: effectiveWeight, color: color);
    case 'bad_script':
      return GoogleFonts.badScript(
          fontSize: size, fontWeight: effectiveWeight, color: color);
    case 'shantell_sans':
      return GoogleFonts.shantellSans(
          fontSize: size, fontWeight: effectiveWeight, color: color);
    case 'marck_script':
      return GoogleFonts.marckScript(
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
  final effectiveWeight = _fixedWeight(font) ? FontWeight.w400 : weight;

  switch (font) {
    case 'playfair':
      return GoogleFonts.playfairDisplay(
          fontSize: size, fontWeight: effectiveWeight, color: color, height: height);
    case 'lora':
      return GoogleFonts.lora(
          fontSize: size, fontWeight: effectiveWeight, color: color, height: height);
    case 'dm_sans':
      return GoogleFonts.dmSans(
          fontSize: size, fontWeight: effectiveWeight, color: color, height: height);
    case 'nunito':
      return GoogleFonts.nunito(
          fontSize: size, fontWeight: effectiveWeight, color: color, height: height);
    case 'lobster':
      return GoogleFonts.lobster(
          fontSize: size, fontWeight: effectiveWeight, color: color, height: height);
    case 'caveat':
      return GoogleFonts.caveat(
          fontSize: size, fontWeight: effectiveWeight, color: color, height: height);
    case 'bad_script':
      return GoogleFonts.badScript(
          fontSize: size, fontWeight: effectiveWeight, color: color, height: height);
    case 'shantell_sans':
      return GoogleFonts.shantellSans(
          fontSize: size, fontWeight: effectiveWeight, color: color, height: height);
    case 'marck_script':
      return GoogleFonts.marckScript(
          fontSize: size, fontWeight: effectiveWeight, color: color, height: height);
    default: // fraunces
      return GoogleFonts.fraunces(
          fontSize: size, fontWeight: effectiveWeight, color: color, height: height);
  }
}
