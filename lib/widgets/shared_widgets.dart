import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/font_helper.dart';
import '../models/models.dart';
import '../providers/app_state.dart';

// ─── Page Fold Corner ─────────────────────────────────────
/// Загнутый угол карточки — визуальный триггер разворачивания.
/// При [expanded]=false размер 28px, при true — 44px, с анимацией.
class PageFoldCorner extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;
  final bool isDark;
  final double cardRadius;

  const PageFoldCorner({
    super.key,
    required this.expanded,
    required this.onTap,
    required this.isDark,
    this.cardRadius = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: expanded ? 44.0 : 28.0,
        height: expanded ? 44.0 : 28.0,
        child: CustomPaint(
          painter: _FoldPainter(isDark: isDark, cardRadius: cardRadius),
          child: Align(
            // centroid of the right-triangle ≈ (2/3·W, 2/3·H)
            // Alignment maps 0..size → -1..1, so 2/3 → 1/3
            alignment: const Alignment(0.35, 0.35),
            child: AnimatedRotation(
              turns: expanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: expanded ? 13.0 : 10.0,
                color: AppColors.terracotta.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FoldPainter extends CustomPainter {
  final bool isDark;
  final double cardRadius;
  const _FoldPainter({required this.isDark, this.cardRadius = 18.0});

  @override
  void paint(Canvas canvas, Size size) {
    final r = cardRadius.clamp(0.0, size.shortestSide);
    final foldPath = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height - r)
      ..arcToPoint(
        Offset(size.width - r, size.height),
        radius: Radius.circular(r),
        clockwise: true,
      )
      ..lineTo(0, size.height)
      ..close();

    // Тень под загибом
    canvas.drawPath(
      foldPath,
      Paint()
        ..color = Colors.black.withValues(alpha: isDark ? 0.30 : 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0)
        ..style = PaintingStyle.fill,
    );

    // Лицевая сторона загиба
    canvas.drawPath(
      foldPath,
      Paint()
        ..color = isDark
            // Dark: warm terracotta glow — subtle but visible on dark cards
            ? AppColors.terracotta.withValues(alpha: 0.22)
            // Light: warm parchment — matches the app background palette
            : AppColors.lightBg2.withValues(alpha: 0.95)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_FoldPainter old) => old.isDark != isDark || old.cardRadius != cardRadius;
}

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
    final appFont = context.watch<AppState>().appFont;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        display,
        style: appTitleStyle(appFont, size: 8, weight: FontWeight.w800, color: color),
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
    final appFont = context.watch<AppState>().appFont;

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
                      style: appTitleStyle(
                        appFont,
                        size: 13,
                        weight: sel ? FontWeight.w700 : FontWeight.w400,
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
    final appFont = context.watch<AppState>().appFont;
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
              style: appTitleStyle(appFont, size: 14, color: textColor),
              decoration: InputDecoration(
                border: InputBorder.none,
                filled: false,
                hintText: hint,
                hintStyle: appTitleStyle(appFont, size: 14, color: iconColor),
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
  /// Optional color resolver — defaults to [AppColors.categoryColor].
  /// Pass [AppState.folderColor] to use per-folder colors from settings.
  final Color Function(String)? colorResolver;
  const CategoryFilterRow({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelect,
    this.colorResolver,
  });

  @override
  Widget build(BuildContext context) {
    final resolveColor = colorResolver ?? AppColors.categoryColor;
    final appFont = context.watch<AppState>().appFont;
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
          final folderCol = isAll ? AppColors.terracotta : resolveColor(cat);
          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? folderCol
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
                        color: folderCol,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    cat.isEmpty ? '–' : cat,
                    style: appTitleStyle(
                      appFont,
                      size: 11,
                      weight: active ? FontWeight.w700 : FontWeight.w500,
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
    return DateFormat('d MMMM yyyy', 'ru').format(dt);
  }
  return DateFormat('d MMMM', 'ru').format(dt);
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

// ─── Drum DateTime Picker ─────────────────────────────────
class CustomDateTimePicker extends StatefulWidget {
  final DateTime initial;
  final bool isDark;
  const CustomDateTimePicker({super.key, required this.initial, required this.isDark});

  @override
  State<CustomDateTimePicker> createState() => _CustomDateTimePickerState();
}

class _CustomDateTimePickerState extends State<CustomDateTimePicker> {
  late int _day, _month, _year, _hour, _minute;

  late FixedExtentScrollController _dayCtrl;
  late FixedExtentScrollController _monthCtrl;
  late FixedExtentScrollController _yearCtrl;
  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minuteCtrl;

  static const _months = [
    'Январь','Февраль','Март','Апрель','Май','Июнь',
    'Июль','Август','Сентябрь','Октябрь','Ноябрь','Декабрь',
  ];

  final int _startYear = DateTime.now().year;
  final int _endYear   = DateTime.now().year + 10;

  int _daysInMonth(int m, int y) => DateTime(y, m + 1, 0).day;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    _day    = d.day;
    _month  = d.month;
    _year   = d.year;
    _hour   = d.hour;
    _minute = d.minute;

    _dayCtrl    = FixedExtentScrollController(initialItem: _day - 1);
    _monthCtrl  = FixedExtentScrollController(initialItem: _month - 1);
    _yearCtrl   = FixedExtentScrollController(
        initialItem: (_year - _startYear).clamp(0, _endYear - _startYear));
    _hourCtrl   = FixedExtentScrollController(initialItem: _hour);
    _minuteCtrl = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _dayCtrl.dispose(); _monthCtrl.dispose(); _yearCtrl.dispose();
    _hourCtrl.dispose(); _minuteCtrl.dispose();
    super.dispose();
  }

  void _onDayChanged(int i) => setState(() {
    _day = i + 1;
    final max = _daysInMonth(_month, _year);
    if (_day > max) { _day = max; _dayCtrl.jumpToItem(_day - 1); }
  });

  void _onMonthChanged(int i) => setState(() {
    _month = i + 1;
    final max = _daysInMonth(_month, _year);
    if (_day > max) { _day = max; _dayCtrl.jumpToItem(_day - 1); }
  });

  void _onYearChanged(int i) => setState(() {
    _year = _startYear + i;
    final max = _daysInMonth(_month, _year);
    if (_day > max) { _day = max; _dayCtrl.jumpToItem(_day - 1); }
  });

  Widget _drum({
    required FixedExtentScrollController ctrl,
    required int itemCount,
    required int selectedIndex,
    required String Function(int) label,
    required ValueChanged<int> onChanged,
    required bool isDark,
    required String appFont,
    double width = 64,
  }) {
    final text      = isDark ? AppColors.darkText    : AppColors.lightText;
    final textSec   = isDark ? AppColors.darkTextDate : AppColors.lightTextDate;
    final selBg     = isDark ? AppColors.darkBg2     : AppColors.lightBg2;
    final surfaceBg = isDark ? AppColors.darkSurface  : AppColors.lightSurface;

    return SizedBox(
      width: width,
      height: 140,
      child: Stack(
        children: [
          Center(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: selBg,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: ctrl,
            itemExtent: 36,
            perspective: 0.003,
            diameterRatio: 1.6,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: itemCount,
              builder: (ctx, i) => Center(
                child: Text(
                  label(i),
                  style: appTitleStyle(
                    appFont, size: 14, weight: FontWeight.w600,
                    color: i == selectedIndex ? text : textSec,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: IgnorePointer(
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [surfaceBg, surfaceBg.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: IgnorePointer(
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    colors: [surfaceBg, surfaceBg.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appFont = context.watch<AppState>().appFont;
    final isDark  = widget.isDark;
    final bg      = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final text    = isDark ? AppColors.darkText     : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextDate : AppColors.lightTextDate;
    final divider = isDark ? AppColors.darkDivider  : AppColors.lightDivider;

    return Dialog(
      backgroundColor: bg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Дата и время',
                style: appTitleStyle(appFont, size: 16, weight: FontWeight.w600, color: text)),
            const SizedBox(height: 12),

            // Барабаны даты
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _drum(
                  ctrl: _dayCtrl, itemCount: _daysInMonth(_month, _year),
                  selectedIndex: _day - 1, label: (i) => '${i + 1}',
                  onChanged: _onDayChanged, isDark: isDark, appFont: appFont, width: 56,
                ),
                const SizedBox(width: 4),
                _drum(
                  ctrl: _monthCtrl, itemCount: 12,
                  selectedIndex: _month - 1, label: (i) => _months[i],
                  onChanged: _onMonthChanged, isDark: isDark, appFont: appFont, width: 120,
                ),
                const SizedBox(width: 4),
                _drum(
                  ctrl: _yearCtrl, itemCount: _endYear - _startYear + 1,
                  selectedIndex: (_year - _startYear).clamp(0, _endYear - _startYear),
                  label: (i) => '${_startYear + i}',
                  onChanged: _onYearChanged, isDark: isDark, appFont: appFont, width: 72,
                ),
              ],
            ),

            const SizedBox(height: 6),
            Divider(color: divider, height: 1),
            const SizedBox(height: 6),

            // Барабаны времени
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _drum(
                  ctrl: _hourCtrl, itemCount: 24,
                  selectedIndex: _hour, label: (i) => i.toString().padLeft(2, '0'),
                  onChanged: (i) => setState(() => _hour = i),
                  isDark: isDark, appFont: appFont, width: 64,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(' : ',
                      style: appTitleStyle(appFont, size: 22, weight: FontWeight.w600, color: text)),
                ),
                _drum(
                  ctrl: _minuteCtrl, itemCount: 60,
                  selectedIndex: _minute, label: (i) => i.toString().padLeft(2, '0'),
                  onChanged: (i) => setState(() => _minute = i),
                  isDark: isDark, appFont: appFont, width: 64,
                ),
              ],
            ),

            const SizedBox(height: 8),
            Divider(color: divider, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(
                        context, DateTime(_year, _month, _day, _hour, _minute)),
                    child: Text('Готово', style: appTitleStyle(appFont,
                        size: 14, weight: FontWeight.w600,
                        color: AppColors.terracotta)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
