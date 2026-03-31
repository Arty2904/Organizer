import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── UI / Title fonts (элементы интерфейса, названия) ─────
const kFontOptions = [
  ('fraunces',       'Fraunces',        'Выразительный serif'),
  ('playfair',       'Playfair Display','Как NYT — газетный'),
  ('lora',           'Lora',            'Мягкий книжный serif'),
  ('dm_sans',        'DM Sans',         'Чистый гротеск'),
  ('nunito',         'Nunito',          'Округлый дружелюбный'),
  ('sacramento',     'Sacramento',      'Каллиграфический'),
  ('dancing_script', 'Dancing Script',  'Игривый рукописный'),
];

// ─── Content fonts (то что пишет пользователь) ────────────
const kContentFontOptions = [
  ('dm_sans',    'DM Sans',    'Чистый гротеск'),
  ('nunito',     'Nunito',     'Округлый мягкий'),
  ('lora',       'Lora',       'Книжный serif'),
  ('merriweather','Merriweather','Газетный serif'),
  ('source_serif','Source Serif 4','Нейтральный serif'),
  ('jetbrains',  'JetBrains Mono','Моноширинный'),
];

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
  int? maxLines,
  TextOverflow? overflow,
}) {
  TextStyle base;
  switch (font) {
    case 'nunito':
      base = GoogleFonts.nunito(fontSize: size, fontWeight: weight, color: color, height: height);
      break;
    case 'lora':
      base = GoogleFonts.lora(fontSize: size, fontWeight: weight, color: color, height: height);
      break;
    case 'merriweather':
      base = GoogleFonts.merriweather(fontSize: size, fontWeight: weight, color: color, height: height);
      break;
    case 'source_serif':
      base = GoogleFonts.sourceSerif4(fontSize: size, fontWeight: weight, color: color, height: height);
      break;
    case 'jetbrains':
      base = GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: weight, color: color, height: height);
      break;
    default: // dm_sans
      base = GoogleFonts.dmSans(fontSize: size, fontWeight: weight, color: color, height: height);
  }
  return base;
}
