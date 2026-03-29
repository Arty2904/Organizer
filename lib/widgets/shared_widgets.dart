import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

// ─── Category Dot ─────────────────────────────────────────
class CategoryDot extends StatelessWidget {
  final String category;
  final double size;
  const CategoryDot({super.key, required this.category, this.size = 7});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: AppColors.categoryColor(category),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ─── Category Badge ───────────────────────────────────────
class CategoryBadge extends StatelessWidget {
  final String label;
  const CategoryBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final isEmpty = label.isEmpty;
    final color = isEmpty ? AppColors.catNone : AppColors.categoryColor(label);
    final display = isEmpty ? '–' : label.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        display,
        style: GoogleFonts.dmSans(
          fontSize: 8, fontWeight: FontWeight.w800,
          color: color, letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── View Switcher (dropdown) ─────────────────────────────
class ViewSwitcher extends StatelessWidget {
  final int current;
  final ValueChanged<int> onChanged;
  const ViewSwitcher({super.key, required this.current, required this.onChanged});

  static const _labels = {
    1: 'Крупный список',
    2: 'Сетка',
    3: 'Мелкий список',
  };
  static const _icons = {
    1: Icons.view_agenda_rounded,
    2: Icons.grid_view_rounded,
    3: Icons.view_headline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCardAlt;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return GestureDetector(
      onTapDown: (details) async {
        final RenderBox button = context.findRenderObject() as RenderBox;
        final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
        final RelativeRect position = RelativeRect.fromRect(
          Rect.fromPoints(
            button.localToGlobal(Offset(0, button.size.height + 4), ancestor: overlay),
            button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
          ),
          Offset.zero & overlay.size,
        );
        final selected = await showMenu<int>(
          context: context,
          color: surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          position: position,
          items: [1, 2, 3].map((v) {
            final sel = current == v;
            return PopupMenuItem<int>(
              value: v,
              padding: EdgeInsets.zero,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: sel
                    ? AppColors.terracotta.withValues(alpha: 0.1)
                    : Colors.transparent,
                child: Row(
                  children: [
                    Icon(_icons[v], size: 16,
                        color: sel ? AppColors.terracotta : textSec),
                    const SizedBox(width: 10),
                    Text(_labels[v]!,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                        color: sel ? AppColors.terracotta : text,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
        if (selected != null) onChanged(selected);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(_icons[current]!, size: 16, color: AppColors.terracotta),
      ),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────
class AppSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String hint;
  const AppSearchBar({super.key, required this.onChanged, required this.hint});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? const Color(0x4DE6AF78) : const Color(0x73785028);
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSearchBg : AppColors.lightSearchBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkSearchBd : AppColors.lightSearchBd,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: GoogleFonts.dmSans(fontSize: 14, color: textColor),
              decoration: InputDecoration(
                border: InputBorder.none,
                filled: false,
                hintText: hint,
                hintStyle: GoogleFonts.dmSans(fontSize: 14, color: iconColor),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category Filter Row ──────────────────────────────────
class CategoryFilterRow extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;
  const CategoryFilterRow({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (ctx, i) {
          final cat = categories[i];
          final isAll = cat == 'Все';
          final active = selected == cat;
          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? (isAll ? AppColors.terracotta : AppColors.categoryColor(cat))
                    : (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkCard
                        : AppColors.lightCardAlt),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isAll && !active) ...[
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.categoryColor(cat),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    cat.isEmpty ? '–' : cat,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active
                          ? Colors.white
                          : (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Date formatting helpers ──────────────────────────────
String formatDate(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(dt.year, dt.month, dt.day);
  if (d == today) return 'Сегодня';
  if (d == today.subtract(const Duration(days: 1))) return 'Вчера';
  if (d == today.add(const Duration(days: 1))) return 'Завтра';
  // Show year only if not current year
  if (dt.year != now.year) {
    return DateFormat('d MMM yyyy', 'ru').format(dt);
  }
  return DateFormat('d MMM', 'ru').format(dt);
}

String formatDateTime(DateTime? dt) {
  if (dt == null) return '';
  return '${formatDate(dt)}, ${DateFormat('HH:mm').format(dt)}';
}

String repeatLabel(RepeatInterval r, int? days) {
  switch (r) {
    case RepeatInterval.none: return '';
    case RepeatInterval.daily: return 'Каждый день';
    case RepeatInterval.weekly: return 'Каждую неделю';
    case RepeatInterval.monthly: return 'Каждый месяц';
    case RepeatInterval.yearly: return 'Каждый год';
    case RepeatInterval.custom: return 'Каждые ${days ?? 1} дн.';
  }
}
