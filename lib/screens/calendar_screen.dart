import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'events_screen.dart';
import 'todos_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _displayMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  void _prevMonth() => setState(() => _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1));
  void _nextMonth() => setState(() => _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1));

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.darkMode;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextDate : AppColors.lightTextDate;
    final surface = isDark ? AppColors.darkBg : AppColors.lightBg;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    final eventsMonth = state.eventsInMonth(_displayMonth);
    final todosMonth = state.todosInMonth(_displayMonth);

    // Filter by selected day if set
    final selEvents = _selectedDay == null
        ? eventsMonth
        : eventsMonth.where((e) {
            if (e.reminderDate == null) return false;
            return e.reminderDate!.year == _selectedDay!.year &&
                e.reminderDate!.month == _selectedDay!.month &&
                e.reminderDate!.day == _selectedDay!.day;
          }).toList();

    final selTodos = _selectedDay == null
        ? todosMonth
        : todosMonth.where((t) {
            return t.createdAt.year == _selectedDay!.year &&
                t.createdAt.month == _selectedDay!.month &&
                t.createdAt.day == _selectedDay!.day;
          }).toList();

    return Column(
      children: [
        // Calendar header
        Container(
          color: surface,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left_rounded, color: text),
                      onPressed: _prevMonth,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    Expanded(
                      child: Text(
                        DateFormat('MMMM yyyy', 'ru').format(_displayMonth),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fraunces(
                          fontSize: 18, fontWeight: FontWeight.w600,
                          color: text,
                         fontStyle: FontStyle.normal,),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right_rounded, color: text),
                      onPressed: _nextMonth,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
              ),
              // Weekday headers
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'].map((d) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: d == 'Сб' || d == 'Вс' ? AppColors.terracotta.withValues(alpha: 0.6) : textSec,
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ),
              // Day grid
              _buildDayGrid(context, state, eventsMonth, isDark),
              const SizedBox(height: 8),
            ],
          ),
        ),
        Divider(color: divider, height: 1),
        // List below
        Expanded(
          child: (selEvents.isEmpty && selTodos.isEmpty)
              ? Center(
                  child: Text(
                    'Нет событий',
                    style: GoogleFonts.dmSans(fontSize: 13, color: textSec),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  children: [
                    if (selEvents.isNotEmpty) ...[
                      _ListHeader('СОБЫТИЯ', isDark),
                      ...selEvents.map((e) => _CalEventTile(event: e, isDark: isDark, onTap: () {
                        showDialog(
                          context: context,
                          barrierColor: Colors.black.withValues(alpha: 0.4),
                          builder: (_) => EventEditorDialog(event: e),
                        );
                      })),
                    ],
                    if (selTodos.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _ListHeader('ДЕЛА', isDark),
                      ...selTodos.map((t) => _CalTodoTile(group: t, isDark: isDark, onTap: () {
                        showDialog(
                          context: context,
                          barrierColor: Colors.black.withValues(alpha: 0.4),
                          builder: (_) => TodoEditorDialog(group: t),
                        );
                      })),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildDayGrid(BuildContext context, AppState state, List<AppEvent> events, bool isDark) {
    final now = DateTime.now();
    final firstDay = DateTime(_displayMonth.year, _displayMonth.month, 1);
    // Monday=1, so weekday-1 gives offset (Mon=0)
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateUtils.getDaysInMonth(_displayMonth.year, _displayMonth.month);
    final total = startOffset + daysInMonth;
    final rows = (total / 7).ceil();

    // days with events
    final eventDays = events
        .where((e) => e.reminderDate != null)
        .map((e) => e.reminderDate!.day)
        .toSet();

    final text = isDark ? AppColors.darkText : AppColors.lightText;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: List.generate(rows, (row) {
          return Row(
            children: List.generate(7, (col) {
              final dayNum = row * 7 + col - startOffset + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const Expanded(child: SizedBox(height: 36));
              }
              final isToday = now.year == _displayMonth.year && now.month == _displayMonth.month && now.day == dayNum;
              final isSel = _selectedDay?.year == _displayMonth.year && _selectedDay?.month == _displayMonth.month && _selectedDay?.day == dayNum;
              final hasEvent = eventDays.contains(dayNum);
              final isWeekend = col >= 5; // Sat/Sun

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDay = DateTime(_displayMonth.year, _displayMonth.month, dayNum)),
                  child: Container(
                    height: 36,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.terracotta : (isToday ? AppColors.terracotta.withValues(alpha: 0.12) : Colors.transparent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '$dayNum',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: (isToday || isSel) ? FontWeight.w700 : FontWeight.w400,
                            color: isSel ? Colors.white : isWeekend ? AppColors.terracotta.withValues(alpha: 0.7) : text,
                          ),
                        ),
                        if (hasEvent && !isSel)
                          Positioned(
                            bottom: 4,
                            child: Container(
                              width: 4, height: 4,
                              decoration: BoxDecoration(color: AppColors.terracotta, shape: BoxShape.circle),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  final String label;
  final bool isDark;
  const _ListHeader(this.label, this.isDark);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.5,
        color: AppColors.terracotta,
      ),
    ),
  );
}

class _CalEventTile extends StatelessWidget {
  final AppEvent event;
  final bool isDark;
  final VoidCallback onTap;
  const _CalEventTile({required this.event, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextDate : AppColors.lightTextDate;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightBg;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final catColor = AppColors.categoryColor(event.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: divider, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 3, height: 40,
              decoration: BoxDecoration(color: catColor, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: GoogleFonts.fraunces(fontSize: 14, fontWeight: FontWeight.w600, color: text, fontStyle: FontStyle.normal,)),
                  if (event.reminderDate != null)
                    Text(
                      DateFormat('HH:mm').format(event.reminderDate!),
                      style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.terracotta),
                    ),
                ],
              ),
            ),
            if (repeatLabel(event.repeat, event.customDays).isNotEmpty)
              Icon(Icons.repeat_rounded, size: 14, color: textSec),
          ],
        ),
      ),
    );
  }
}

class _CalTodoTile extends StatelessWidget {
  final TodoGroup group;
  final bool isDark;
  final VoidCallback onTap;
  const _CalTodoTile({required this.group, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextDate : AppColors.lightTextDate;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightBg;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final catColor = AppColors.categoryColor(group.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: divider, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 3, height: 40,
              decoration: BoxDecoration(color: catColor, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name, style: GoogleFonts.fraunces(fontSize: 14, fontWeight: FontWeight.w600, color: text, fontStyle: FontStyle.normal,)),
                  Text('${group.doneCount}/${group.total} выполнено', style: GoogleFonts.dmSans(fontSize: 11, color: textSec)),
                ],
              ),
            ),
            SizedBox(
              width: 32, height: 32,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: group.total > 0 ? group.doneCount / group.total : 0,
                    strokeWidth: 2.5,
                    color: AppColors.terracotta,
                    backgroundColor: AppColors.terracotta.withValues(alpha: 0.15),
                  ),
                  Text(
                    '${group.doneCount}',
                    style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.terracotta),
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
