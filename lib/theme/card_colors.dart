import 'package:flutter/material.dart';

/// Единая палитра из 21 приглушённого тёплого оттенка.
/// Используется для карточек заметок, событий, задач,
/// папок и bulk-color в home_shell.
///
/// colorIndex 0 = без цвета, 1-21 = kCardColors[index - 1].
const List<Color> kCardColors = [
  // Reds / Pinks
  Color(0xFFB85C5C), Color(0xFFB5607A), Color(0xFF7A5490),
  // Purples / Blues
  Color(0xFF5C5490), Color(0xFF4A5880), Color(0xFF4878A8),
  // Cyan / Teal
  Color(0xFF3A8898), Color(0xFF3A8880), Color(0xFF3A7870),
  // Greens
  Color(0xFF5A8C50), Color(0xFF6E8C50), Color(0xFF8A9048),
  // Yellows / Oranges
  Color(0xFFB89840), Color(0xFFB88030), Color(0xFFB87030),
  // Warm oranges / Browns
  Color(0xFFB06040), Color(0xFFA06840), Color(0xFF7A5840),
  // Greys
  Color(0xFF5A6870), Color(0xFF787870), Color(0xFF404850),
];

// Backward-compat aliases so existing references compile without change.
// TODO: migrate call-sites to kCardColors and remove these.
const List<Color> kNoteColors  = kCardColors;
const List<Color> kTodoColors  = kCardColors;
const List<Color> kEventColors = kCardColors;

/// Returns the card background [Color] for [colorIndex].
/// [colorIndex] == 0 returns null (caller should use their default bg).
Color? cardColorFor(int colorIndex) {
  if (colorIndex < 1 || colorIndex > kCardColors.length) return null;
  return kCardColors[colorIndex - 1];
}
