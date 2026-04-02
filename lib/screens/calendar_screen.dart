import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../theme/font_helper.dart';
import '../widgets/shared_widgets.dart';
import 'events_screen.dart';
import 'todos_screen.dart';

// ─── Helpers ──────────────────────────────────────────────
// Russian nominative month names for calendar headers (март 2026)
const _ruMonthsFull = [
  'январь','февраль','март','апрель','май','июнь',
  'июль','август','сентябрь','октябрь','ноябрь','декабрь',
];
// Abbreviated for mini-month labels in year view
const _ruMonthsShort = [
  'янв','фев','мар','апр','май','июнь',
  'июль','авг','сен','окт','ноя','дек',
];

// ─── CalendarScreen ───────────────────────────────────────
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const int _baseYear = 2000;

  // false = month view (default), true = year view
  bool _yearMode = false;

  late int _displayYear;
  late DateTime _displayMonth;
  DateTime? _selectedDay;

  late PageController _yearPageCtrl;
  late PageController _monthPageCtrl;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayYear  = now.year;
    _displayMonth = DateTime(now.year, now.month);
    _selectedDay  = DateTime(now.year, now.month, now.day);
    _yearPageCtrl  = PageController(initialPage: _displayYear - _baseYear);
    _monthPageCtrl = PageController(
      initialPage: (_displayYear - _baseYear) * 12 + (now.month - 1),
    );
  }

  @override
  void dispose() {
    _yearPageCtrl.dispose();
    _monthPageCtrl.dispose();
    super.dispose();
  }

  // Tap on day in year view → switch to month view for that month
  void _onYearDayTap(DateTime day) {
    setState(() {
      _selectedDay  = day;
      _displayMonth = DateTime(day.year, day.month);
      _yearMode     = false;
    });
    _monthPageCtrl.jumpToPage(
      (day.year - _baseYear) * 12 + (day.month - 1),
    );
  }

  // Tap on title → toggle year mode
  void _onTitleTap() => setState(() => _yearMode = !_yearMode);

  // Build the title string
  String get _titleText {
    if (_yearMode) return '$_displayYear';
    final m = _displayMonth;
    return '${_ruMonthsFull[m.month - 1]} ${m.year}';
  }

  @override
  Widget build(BuildContext context) {
    final state   = context.watch<AppState>();
    final isDark  = state.darkMode;
    final surface = isDark ? AppColors.darkBg  : AppColors.lightBg;
    final text    = isDark ? AppColors.darkText : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextDate : AppColors.lightTextDate;
    final divider = isDark ? AppColors.darkDivider  : AppColors.lightDivider;

    return Column(children: [
      // ── Header: tappable title only ──
      Container(
        color: surface,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
        child: GestureDetector(
          onTap: _onTitleTap,
          behavior: HitTestBehavior.opaque,
          child: Row(children: [
            Expanded(
              child: Text(
                _titleText,
                style: appTitleStyle(state.appFont,
                    size: 22, weight: FontWeight.w700, color: text),
              ),
            ),
            // small chevron hint
            AnimatedRotation(
              turns: _yearMode ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.expand_more_rounded,
                  size: 20, color: AppColors.terracotta),
            ),
          ]),
        ),
      ),
      Divider(color: divider, height: 1),

      // ── Content ──
      Expanded(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _yearMode
              ? KeyedSubtree(
                  key: const ValueKey('year'),
                  child: PageView.builder(
                    controller: _yearPageCtrl,
                    physics: const PageScrollPhysics(),
                    onPageChanged: (p) =>
                        setState(() => _displayYear = _baseYear + p),
                    itemBuilder: (_, p) => _YearGrid(
                      year: _baseYear + p,
                      isDark: isDark, text: text, textSec: textSec,
                      selectedDay: _selectedDay,
                      onDayTap: _onYearDayTap,
                    ),
                  ),
                )
              : KeyedSubtree(
                  key: const ValueKey('month'),
                  child: PageView.builder(
                    controller: _monthPageCtrl,
                    onPageChanged: (p) => setState(() {
                      _displayMonth =
                          DateTime(_baseYear + p ~/ 12, p % 12 + 1);
                      _displayYear = _displayMonth.year;
                    }),
                    itemBuilder: (_, p) {
                      final month =
                          DateTime(_baseYear + p ~/ 12, p % 12 + 1);
                      return _MonthDetail(
                        displayMonth: month,
                        isDark: isDark, text: text,
                        textSec: textSec, divider: divider,
                        selectedDay: _selDayFor(month),
                        onDayTap: (d) => setState(() => _selectedDay = d),
                        state: state,
                      );
                    },
                  ),
                ),
        ),
      ),
    ]);
  }

  DateTime? _selDayFor(DateTime month) {
    if (_selectedDay == null) return null;
    if (_selectedDay!.year == month.year &&
        _selectedDay!.month == month.month) return _selectedDay;
    return null;
  }
}

// ─── Year Grid ────────────────────────────────────────────
class _YearGrid extends StatelessWidget {
  final int year;
  final bool isDark;
  final Color text, textSec;
  final DateTime? selectedDay;
  final void Function(DateTime) onDayTap;

  const _YearGrid({
    required this.year, required this.isDark,
    required this.text, required this.textSec,
    required this.selectedDay, required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final now    = DateTime.now();
    final bg     = isDark ? AppColors.darkBg2 : AppColors.lightBg2;
    final cardBg = isDark ? AppColors.darkBg  : AppColors.lightBg;

    return Container(
      color: bg,
      child: Column(
        children: List.generate(4, (row) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, row == 0 ? 8 : 4, 12, row == 3 ? 8 : 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(3, (col) {
                  final month = row * 3 + col + 1;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: col > 0 ? 6 : 0),
                      child: _MiniMonth(
                        year: year, month: month, now: now,
                        isDark: isDark, text: text, textSec: textSec,
                        cardBg: cardBg,
                        monthName: _ruMonthsShort[month - 1],
                        selectedDay: selectedDay,
                        onDayTap: onDayTap,
                      ),
                    ),
                  );
                }),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Mini Month (in year view) ────────────────────────────
class _MiniMonth extends StatelessWidget {
  final int year, month;
  final DateTime now;
  final bool isDark;
  final Color text, textSec, cardBg;
  final String monthName;
  final DateTime? selectedDay;
  final void Function(DateTime) onDayTap;

  const _MiniMonth({
    required this.year, required this.month, required this.now,
    required this.isDark, required this.text, required this.textSec,
    required this.cardBg, required this.monthName,
    required this.selectedDay, required this.onDayTap,
  });

  static const _wd = ['П','В','С','Ч','П','С','В'];

  @override
  Widget build(BuildContext context) {
    final firstDay    = DateTime(year, month, 1);
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final rows        = ((startOffset + daysInMonth) / 7).ceil();
    final isCurMonth  = now.year == year && now.month == month;

    return Container(
      padding: const EdgeInsets.fromLTRB(5, 7, 5, 5),
      decoration: BoxDecoration(
          color: cardBg, borderRadius: BorderRadius.circular(11)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 2),
            child: Text(monthName, style: GoogleFonts.dmSans(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: isCurMonth ? AppColors.terracotta : text,
            )),
          ),
          Row(children: List.generate(7, (i) => Expanded(
            child: Text(_wd[i], textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 7, fontWeight: FontWeight.w600,
                color: i >= 5
                    ? AppColors.terracotta.withValues(alpha: 0.55)
                    : textSec,
              )),
          ))),
          for (int row = 0; row < rows; row++)
            Row(children: List.generate(7, (col) {
              final dn = row * 7 + col - startOffset + 1;
              if (dn < 1 || dn > daysInMonth) {
                return const Expanded(child: SizedBox());
              }
              final isToday = now.year == year && now.month == month && now.day == dn;
              final isSel   = selectedDay?.year == year &&
                  selectedDay?.month == month && selectedDay?.day == dn;
              final isWknd  = col >= 5;

              return Expanded(child: GestureDetector(
                onTap: () => onDayTap(DateTime(year, month, dn)),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    margin: const EdgeInsets.all(0.8),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.terracotta
                          : isToday
                              ? AppColors.terracotta.withValues(alpha: 0.18)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text('$dn', style: GoogleFonts.dmSans(
                      fontSize: 8,
                      fontWeight: (isToday || isSel) ? FontWeight.w700 : FontWeight.w400,
                      color: isSel ? Colors.white
                          : isWknd
                              ? AppColors.terracotta.withValues(alpha: 0.75)
                              : text,
                    )),
                  ),
                ),
              ));
            })),
        ],
      ),
    );
  }
}

// ─── Month Detail ─────────────────────────────────────────
class _MonthDetail extends StatelessWidget {
  final DateTime displayMonth;
  final bool isDark;
  final Color text, textSec, divider;
  final DateTime? selectedDay;
  final void Function(DateTime) onDayTap;
  final AppState state;

  const _MonthDetail({
    required this.displayMonth, required this.isDark,
    required this.text, required this.textSec, required this.divider,
    required this.selectedDay, required this.onDayTap, required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final now     = DateTime.now();
    final surface = isDark ? AppColors.darkBg  : AppColors.lightBg;
    final bg      = isDark ? AppColors.darkBg2 : AppColors.lightBg2;

    final eventsMonth = state.eventsInMonth(displayMonth);

    final today = DateTime(now.year, now.month, now.day);
    final selDay = selectedDay != null
        ? DateTime(selectedDay!.year, selectedDay!.month, selectedDay!.day)
        : null;
    final isSelToday = selDay == null || selDay == today;

    bool _sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    // ── Режим "выбранный день" (не сегодня) ──
    final dayEvents = selDay != null && !isSelToday
        ? (state.events
            .where((e) => e.reminderDate != null && _sameDay(e.reminderDate!, selDay))
            .toList()
          ..sort((a, b) => a.reminderDate!.compareTo(b.reminderDate!)))
        : <AppEvent>[];

    final dayTodos = selDay != null && !isSelToday
        ? state.todos
            .where((t) => t.reminderDate != null && _sameDay(t.reminderDate!, selDay))
            .toList()
        : <TodoGroup>[];

    // ── Режим "сегодня/нет выбора" ──
    final allUpcoming = state.events
        .where((e) => e.reminderDate != null && !e.reminderDate!.isBefore(today))
        .toList()
      ..sort((a, b) => a.reminderDate!.compareTo(b.reminderDate!));

    final todayEvents = isSelToday
        ? allUpcoming.where((e) => _sameDay(e.reminderDate!, today)).toList()
        : <AppEvent>[];

    final upcomingEvents = isSelToday
        ? allUpcoming.where((e) {
            final d = DateTime(e.reminderDate!.year, e.reminderDate!.month, e.reminderDate!.day);
            return d.isAfter(today) && d.difference(today).inDays <= 70;
          }).toList()
        : <AppEvent>[];

    // Дни с событиями или задачами для точек на сетке
    final eventDays = eventsMonth
        .where((e) => e.reminderDate != null)
        .map((e) => e.reminderDate!.day)
        .toSet();
    final todoDays = state.todos
        .where((t) =>
            t.reminderDate != null &&
            t.reminderDate!.year == displayMonth.year &&
            t.reminderDate!.month == displayMonth.month)
        .map((t) => t.reminderDate!.day)
        .toSet();
    final markedDays = {...eventDays, ...todoDays};

    final firstDay    = DateTime(displayMonth.year, displayMonth.month, 1);
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateUtils.getDaysInMonth(displayMonth.year, displayMonth.month);
    final rows        = ((startOffset + daysInMonth) / 7).ceil();

    return Container(
      color: bg,
      child: Column(children: [
        // Full grid
        Container(
          color: surface,
          child: Column(children: [
            // Weekday headers
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Row(
                children: ['Пн','Вт','Ср','Чт','Пт','Сб','Вс'].map((d) =>
                  Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Text(d, textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: d == 'Сб' || d == 'Вс'
                            ? AppColors.terracotta.withValues(alpha: 0.6)
                            : textSec,
                      )),
                  )),
                ).toList(),
              ),
            ),
            // Day grid
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Column(
                children: List.generate(rows, (row) => Row(
                  children: List.generate(7, (col) {
                    final dn = row * 7 + col - startOffset + 1;
                    if (dn < 1 || dn > daysInMonth) {
                      return const Expanded(child: SizedBox(height: 38));
                    }
                    final isToday = now.year  == displayMonth.year &&
                        now.month == displayMonth.month && now.day == dn;
                    final isSel = selectedDay?.year  == displayMonth.year &&
                        selectedDay?.month == displayMonth.month &&
                        selectedDay?.day   == dn;
                    final hasEvent = markedDays.contains(dn);
                    final isWknd   = col >= 5;

                    return Expanded(child: GestureDetector(
                      onTap: () => onDayTap(
                          DateTime(displayMonth.year, displayMonth.month, dn)),
                      child: Container(
                        height: 38,
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.terracotta
                              : isToday
                                  ? AppColors.terracotta.withValues(alpha: 0.12)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Stack(alignment: Alignment.center, children: [
                          Text('$dn', style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: (isToday || isSel)
                                ? FontWeight.w700 : FontWeight.w400,
                            color: isSel ? Colors.white
                                : isWknd
                                    ? AppColors.terracotta.withValues(alpha: 0.75)
                                    : text,
                          )),
                          if (hasEvent && !isSel)
                            Positioned(bottom: 4, child: Container(
                              width: 4, height: 4,
                              decoration: const BoxDecoration(
                                  color: AppColors.terracotta,
                                  shape: BoxShape.circle),
                            )),
                        ]),
                      ),
                    ));
                  }),
                )),
              ),
            ),
          ]),
        ),
        Divider(color: divider, height: 1),
        // Events list
        Expanded(
          child: Stack(
            children: [
              () {
                // Режим выбранного прошедшего/будущего дня
                if (!isSelToday) {
                  if (dayEvents.isEmpty && dayTodos.isEmpty) {
                    return Center(child: Text(
                      'Нет событий',
                      style: GoogleFonts.dmSans(fontSize: 13, color: textSec),
                    ));
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    children: [
                      if (dayEvents.isNotEmpty) ...[
                        _ListHeader('СОБЫТИЯ', isDark),
                        ...dayEvents.map((e) => _CalEventTile(
                          event: e, isDark: isDark, showDate: false,
                          onTap: () => showDialog(
                            context: context,
                            barrierColor: Colors.black.withValues(alpha: 0.4),
                            builder: (_) => EventEditorDialog(event: e),
                          ),
                        )),
                      ],
                      if (dayTodos.isNotEmpty) ...[
                        if (dayEvents.isNotEmpty) const SizedBox(height: 12),
                        _ListHeader('ЗАДАЧИ', isDark),
                        ...dayTodos.map((t) => _CalTodoTile(
                          group: t, isDark: isDark,
                          onTap: () => showDialog(
                            context: context,
                            barrierColor: Colors.black.withValues(alpha: 0.4),
                            builder: (_) => TodoEditorDialog(group: t),
                          ),
                        )),
                      ],
                    ],
                  );
                }
                // Режим сегодня/нет выбора — Сегодня + Ближайшие
                if (todayEvents.isEmpty && upcomingEvents.isEmpty) {
                  return Center(child: Text(
                    'Нет событий',
                    style: GoogleFonts.dmSans(fontSize: 13, color: textSec),
                  ));
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  children: [
                    if (todayEvents.isNotEmpty) ...[
                      _ListHeader('СЕГОДНЯ', isDark),
                      ...todayEvents.map((e) => _CalEventTile(
                        event: e, isDark: isDark, showDate: false,
                        onTap: () => showDialog(
                          context: context,
                          barrierColor: Colors.black.withValues(alpha: 0.4),
                          builder: (_) => EventEditorDialog(event: e),
                        ),
                      )),
                    ],
                    if (upcomingEvents.isNotEmpty) ...[
                      if (todayEvents.isNotEmpty) const SizedBox(height: 12),
                      _ListHeader('БЛИЖАЙШИЕ', isDark),
                      ...upcomingEvents.map((e) => _CalEventTile(
                        event: e, isDark: isDark, showDate: true,
                        onTap: () => showDialog(
                          context: context,
                          barrierColor: Colors.black.withValues(alpha: 0.4),
                          builder: (_) => EventEditorDialog(event: e),
                        ),
                      )),
                    ],
                  ],
                );
              }(),
              // ── FAB ──
              Positioned(
                bottom: 20, right: 0,
                child: SizedBox(
                  width: 44, height: 44,
                  child: FloatingActionButton(
                    heroTag: 'cal_fab',
                    onPressed: () => showDialog(
                      context: context,
                      barrierColor: Colors.black.withValues(alpha: 0.4),
                      builder: (_) => const EventEditorDialog(),
                    ),
                    backgroundColor: isDark ? AppColors.terracotta : AppColors.terracottaLight,
                    elevation: 6,
                    shape: const CircleBorder(),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────
class _ListHeader extends StatelessWidget {
  final String label; final bool isDark;
  const _ListHeader(this.label, this.isDark);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(label, style: GoogleFonts.dmSans(
      fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.5,
      color: AppColors.terracotta,
    )),
  );
}

class _CalEventTile extends StatelessWidget {
  final AppEvent event;
  final bool isDark;
  final bool showDate;
  final VoidCallback onTap;
  const _CalEventTile(
      {required this.event, required this.isDark, required this.onTap, this.showDate = false});

  @override
  Widget build(BuildContext context) {
    final text     = isDark ? AppColors.darkText     : AppColors.lightText;
    final textSec  = isDark ? AppColors.darkTextDate : AppColors.lightTextDate;
    final cardBg   = isDark ? AppColors.darkCard     : AppColors.lightBg;
    final divider  = isDark ? AppColors.darkDivider  : AppColors.lightDivider;
    final catColor = AppColors.categoryColor(event.category);
    final appFont  = context.watch<AppState>().appFont;

    String? timeLabel;
    if (event.reminderDate != null) {
      timeLabel = showDate
          ? DateFormat('d MMM, HH:mm', 'ru').format(event.reminderDate!)
          : DateFormat('HH:mm').format(event.reminderDate!);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: divider, width: 0.5),
        ),
        child: Row(children: [
          Container(width: 3, height: 40,
            decoration: BoxDecoration(
                color: catColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(event.title, style: appTitleStyle(appFont,
                size: 14, weight: FontWeight.w600, color: text)),
            if (timeLabel != null)
              Text(timeLabel,
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppColors.terracotta)),
          ])),
          if (repeatLabel(event.repeat, event.customDays).isNotEmpty)
            Icon(Icons.repeat_rounded, size: 14, color: textSec),
        ]),
      ),
    );
  }
}

class _CalTodoTile extends StatelessWidget {
  final TodoGroup group; final bool isDark; final VoidCallback onTap;
  const _CalTodoTile(
      {required this.group, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text     = isDark ? AppColors.darkText     : AppColors.lightText;
    final textSec  = isDark ? AppColors.darkTextDate : AppColors.lightTextDate;
    final cardBg   = isDark ? AppColors.darkCard     : AppColors.lightBg;
    final divider  = isDark ? AppColors.darkDivider  : AppColors.lightDivider;
    final catColor = AppColors.categoryColor(group.category);
    final appFont  = context.watch<AppState>().appFont;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: divider, width: 0.5),
        ),
        child: Row(children: [
          Container(width: 3, height: 40,
            decoration: BoxDecoration(
                color: catColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(group.name, style: appTitleStyle(appFont,
                size: 14, weight: FontWeight.w600, color: text)),
            Text('${group.doneCount}/${group.total} выполнено',
                style: GoogleFonts.dmSans(fontSize: 11, color: textSec)),
          ])),
          SizedBox(width: 32, height: 32,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                value: group.total > 0 ? group.doneCount / group.total : 0,
                strokeWidth: 2.5, color: AppColors.terracotta,
                backgroundColor:
                    AppColors.terracotta.withValues(alpha: 0.15),
              ),
              Text('${group.doneCount}', style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.terracotta)),
            ]),
          ),
        ]),
      ),
    );
  }
}
