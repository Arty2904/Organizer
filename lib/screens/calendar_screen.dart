import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../l10n/app_strings.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../theme/font_helper.dart';
import '../widgets/shared_widgets.dart';
import 'events_screen.dart';
import 'todos_screen.dart';

// ─── Helpers ──────────────────────────────────────────────

// ─── Repeat helpers ───────────────────────────────────────

/// Returns all days-of-month in [month] where [event] occurs (considering repeat).
Set<int> eventOccurrenceDaysInMonth(AppEvent event, DateTime month) {
  if (event.reminderDate == null) return {};
  final base = event.reminderDate!;
  final monthStart = DateTime(month.year, month.month, 1);
  final monthEnd   = DateTime(month.year, month.month,
      DateUtils.getDaysInMonth(month.year, month.month));

  if (event.repeat == RepeatInterval.none) {
    if (base.year == month.year && base.month == month.month) return {base.day};
    return {};
  }

  final days = <int>{};
  // Walk forward from base, collecting hits inside this month.
  // Cap iterations to avoid infinite loop on tiny custom intervals.
  const maxIter = 400;
  int iter = 0;
  DateTime cur = DateTime(base.year, base.month, base.day,
      base.hour, base.minute);

  // If base is after the month, no occurrences.
  if (cur.isAfter(monthEnd)) return {};

  // Advance cur to at least monthStart in large steps first (perf).
  if (cur.isBefore(monthStart)) {
    cur = _advanceTo(event, cur, monthStart);
  }

  while (!cur.isAfter(monthEnd) && iter < maxIter) {
    if (cur.year == month.year && cur.month == month.month) {
      days.add(cur.day);
    }
    cur = _nextOccurrenceAfter(event, cur);
    iter++;
  }
  return days;
}

/// Returns the next occurrence of [event] strictly after [after],
/// or null if repeat is none / no future date.
DateTime? nextOccurrence(AppEvent event, DateTime after) {
  if (event.reminderDate == null) return null;
  if (event.repeat == RepeatInterval.none) {
    final d = event.reminderDate!;
    return d.isAfter(after) ? d : null;
  }
  final base = event.reminderDate!;
  DateTime cur = DateTime(base.year, base.month, base.day,
      base.hour, base.minute);
  if (cur.isAfter(after)) return cur;
  // Advance to first occurrence after [after]
  cur = _advanceTo(event, cur, after);
  if (!cur.isAfter(after)) cur = _nextOccurrenceAfter(event, cur);
  return cur.isAfter(after) ? cur : null;
}

/// Advance [cur] to approx [target] in large steps (for perf).
DateTime _advanceTo(AppEvent event, DateTime cur, DateTime target) {
  final diff = target.difference(cur).inDays;
  if (diff <= 0) return cur;
  switch (event.repeat) {
    case RepeatInterval.daily:
      return cur.add(Duration(days: diff));
    case RepeatInterval.weekly:
      final weeks = diff ~/ 7;
      return cur.add(Duration(days: weeks * 7));
    case RepeatInterval.monthly:
      final months = diff ~/ 28;
      if (months <= 0) return cur;
      return DateTime(cur.year + (cur.month + months - 1) ~/ 12,
          (cur.month + months - 1) % 12 + 1, cur.day,
          cur.hour, cur.minute);
    case RepeatInterval.yearly:
      final years = diff ~/ 365;
      if (years <= 0) return cur;
      return DateTime(cur.year + years, cur.month, cur.day, cur.hour, cur.minute);
    case RepeatInterval.custom:
      final n = (event.customDays ?? 1).clamp(1, 9999);
      final steps = diff ~/ n;
      if (steps <= 0) return cur;
      return cur.add(Duration(days: steps * n));
    case RepeatInterval.none:
      return cur;
  }
}

/// One step forward from [cur] according to event repeat rule.
DateTime _nextOccurrenceAfter(AppEvent event, DateTime cur) {
  switch (event.repeat) {
    case RepeatInterval.daily:
      return cur.add(const Duration(days: 1));
    case RepeatInterval.weekly:
      return cur.add(const Duration(days: 7));
    case RepeatInterval.monthly:
      final m = cur.month + 1;
      final y = cur.year + (m - 1) ~/ 12;
      final mo = (m - 1) % 12 + 1;
      final maxDay = DateUtils.getDaysInMonth(y, mo);
      return DateTime(y, mo, cur.day.clamp(1, maxDay), cur.hour, cur.minute);
    case RepeatInterval.yearly:
      return DateTime(cur.year + 1, cur.month, cur.day, cur.hour, cur.minute);
    case RepeatInterval.custom:
      final n = (event.customDays ?? 1).clamp(1, 9999);
      return cur.add(Duration(days: n));
    case RepeatInterval.none:
      return cur.add(const Duration(days: 1)); // shouldn't be called
  }
}

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

  final LayerLink _menuLayerLink = LayerLink();
  OverlayEntry? _menuOverlay;

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
    _menuOverlay?.remove();
    _yearPageCtrl.dispose();
    _monthPageCtrl.dispose();
    super.dispose();
  }

  void _hideMenu() {
    _menuOverlay?.remove();
    _menuOverlay = null;
  }

  void _showMenu(BuildContext context, bool isDark) {
    _hideMenu();
    final bg      = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final text    = isDark ? AppColors.darkText    : AppColors.lightText;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    _menuOverlay = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _hideMenu,
        child: Stack(children: [
          Positioned.fill(child: Container(color: Colors.transparent)),
          CompositedTransformFollower(
            link: _menuLayerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(8, 4),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 180,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: divider, width: 0.5),
                  boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                    blurRadius: 16, offset: const Offset(0, 6),
                  )],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  GestureDetector(
                    onTap: () {
                      _hideMenu();
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const CalendarSearchScreen(),
                      ));
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      child: Row(children: [
                        Icon(Icons.search_rounded, size: 16, color: AppColors.terracotta),
                        const SizedBox(width: 10),
                        Text(context.read<AppState>().s.search, style: appTitleStyle(context.read<AppState>().appFont, size: 13, color: text)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
    Overlay.of(context).insert(_menuOverlay!);
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
  String _titleText(S s) {
    if (_yearMode) return '$_displayYear';
    final m = _displayMonth;
    return '${s.monthsCapital[m.month - 1]} ${m.year}';
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
        child: Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: _onTitleTap,
              behavior: HitTestBehavior.opaque,
              child: Text(
                _titleText(state.s),
                style: GoogleFonts.dmSans(
                    fontSize: 22, fontWeight: FontWeight.w700, color: text),
              ),
            ),
          ),
          CompositedTransformTarget(
            link: _menuLayerLink,
            child: GestureDetector(
              onTap: () => _showMenu(context, isDark),
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.more_vert_rounded, size: 22, color: textSec),
              ),
            ),
          ),
        ]),
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
    final s      = context.watch<AppState>().s;

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
                        monthName: s.monthsCapital[month - 1],
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


  @override
  Widget build(BuildContext context) {
    final s           = context.watch<AppState>().s;
    final wd          = s.weekdays1;
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
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(monthName, style: GoogleFonts.dmSans(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: isCurMonth ? AppColors.terracotta : text,
              )),
            ),
          ),
          Row(children: List.generate(7, (i) => Expanded(
            child: Text(wd[i], textAlign: TextAlign.center,
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

// ─── Effective Event (event + computed occurrence date) ──
class _EffEvent {
  final AppEvent event;
  final DateTime date;
  const _EffEvent(this.event, this.date);
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
        ? (state.events.where((e) {
            if (e.reminderDate == null) return false;
            if (e.repeat == RepeatInterval.none) return _sameDay(e.reminderDate!, selDay);
            // For repeating events check if selDay is an occurrence
            final days = eventOccurrenceDaysInMonth(e, displayMonth);
            return days.contains(selDay.day) &&
                e.reminderDate!.isBefore(selDay.add(const Duration(days: 1)));
          }).toList()
          ..sort((a, b) => a.reminderDate!.compareTo(b.reminderDate!)))
        : <AppEvent>[];

    final dayTodos = selDay != null && !isSelToday
        ? state.todos
            .where((t) => t.reminderDate != null && _sameDay(t.reminderDate!, selDay))
            .toList()
        : <TodoGroup>[];

    // ── Режим "сегодня/нет выбора" ──
    // Для повторяющихся событий: вычисляем ближайшее вхождение.
    // _UpcomingEvent хранит событие + эффективную дату показа.
    final todayEvents = <_EffEvent>[];
    final upcomingEvents = <_EffEvent>[];

    if (isSelToday) {
      for (final e in state.events) {
        if (e.reminderDate == null) continue;
        if (e.repeat == RepeatInterval.none) {
          final d = DateTime(e.reminderDate!.year, e.reminderDate!.month, e.reminderDate!.day);
          if (_sameDay(d, today)) {
            todayEvents.add(_EffEvent(e, e.reminderDate!));
          } else if (d.isAfter(today) && d.difference(today).inDays <= 70) {
            upcomingEvents.add(_EffEvent(e, e.reminderDate!));
          }
        } else {
          // Check if today is an occurrence
          final todayOcc = eventOccurrenceDaysInMonth(e, displayMonth);
          if (todayOcc.contains(today.day)) {
            final effDate = DateTime(today.year, today.month, today.day,
                e.reminderDate!.hour, e.reminderDate!.minute);
            todayEvents.add(_EffEvent(e, effDate));
          } else {
            // Find next occurrence after today
            final next = nextOccurrence(e, today);
            if (next != null && next.difference(today).inDays <= 70) {
              upcomingEvents.add(_EffEvent(e, next));
            }
          }
        }
      }
      todayEvents.sort((a, b) => a.date.compareTo(b.date));
      upcomingEvents.sort((a, b) => a.date.compareTo(b.date));
    }

    // Дни с событиями или задачами для точек на сетке
    // Учитываем повторяющиеся события
    final eventDays = <int>{};
    for (final e in state.events) {
      eventDays.addAll(eventOccurrenceDaysInMonth(e, displayMonth));
    }
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
                children: List.generate(7, (i) {
                  final days = state.s.weekdaysShort;
                  final d = days[i];
                  final isWknd = i >= 5;
                  return Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Text(d, textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: isWknd
                            ? AppColors.terracotta.withValues(alpha: 0.6)
                            : textSec,
                      )),
                  ));
                }),
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
          child: () {
                // Режим выбранного прошедшего/будущего дня
                if (!isSelToday) {
                  if (dayEvents.isEmpty && dayTodos.isEmpty) {
                    return Center(child: Text(
                      state.s.noEvents,
                      style: appTitleStyle(state.appFont, size: 13, color: textSec),
                    ));
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    children: [
                      if (dayEvents.isNotEmpty) ...[
                        _ListHeader(state.s.sectionEvents, isDark),
                        ...dayEvents.map((e) {
                          // For repeating events show time on the selected day
                          final effDate = e.repeat != RepeatInterval.none && e.reminderDate != null
                              ? DateTime(selDay!.year, selDay.month, selDay.day,
                                  e.reminderDate!.hour, e.reminderDate!.minute)
                              : e.reminderDate;
                          return _CalEventTile(
                            event: e, isDark: isDark, showDate: false,
                            effectiveDate: effDate,
                            onTap: () => showDialog(
                              context: context,
                              barrierColor: Colors.black.withValues(alpha: 0.4),
                              builder: (_) => EventEditorDialog(event: e),
                            ),
                          );
                        }),
                      ],
                      if (dayTodos.isNotEmpty) ...[
                        if (dayEvents.isNotEmpty) const SizedBox(height: 12),
                        _ListHeader(state.s.sectionTodos, isDark),
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
                    state.s.noEvents,
                    style: appTitleStyle(state.appFont, size: 13, color: textSec),
                  ));
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  children: [
                    if (todayEvents.isNotEmpty) ...[
                      _ListHeader(state.s.sectionToday, isDark),
                      ...todayEvents.map((ee) => _CalEventTile(
                        event: ee.event, isDark: isDark, showDate: false,
                        effectiveDate: ee.date,
                        onTap: () => showDialog(
                          context: context,
                          barrierColor: Colors.black.withValues(alpha: 0.4),
                          builder: (_) => EventEditorDialog(event: ee.event),
                        ),
                      )),
                    ],
                    if (upcomingEvents.isNotEmpty) ...[
                      if (todayEvents.isNotEmpty) const SizedBox(height: 12),
                      _ListHeader(state.s.sectionUpcoming, isDark),
                      ...upcomingEvents.map((ee) => _CalEventTile(
                        event: ee.event, isDark: isDark, showDate: true,
                        effectiveDate: ee.date,
                        onTap: () => showDialog(
                          context: context,
                          barrierColor: Colors.black.withValues(alpha: 0.4),
                          builder: (_) => EventEditorDialog(event: ee.event),
                        ),
                      )),
                    ],
                  ],
                );
          }(),
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
    child: Text(label, style: appTitleStyle(
      context.watch<AppState>().appFont,
      size: 9, weight: FontWeight.w800, color: AppColors.terracotta,
    )),
  );
}

class _CalEventTile extends StatelessWidget {
  final AppEvent event;
  final bool isDark;
  final bool showDate;
  final DateTime? effectiveDate;
  final VoidCallback onTap;
  const _CalEventTile(
      {required this.event, required this.isDark, required this.onTap,
       this.showDate = false, this.effectiveDate});

  @override
  Widget build(BuildContext context) {
    final text     = isDark ? AppColors.darkText     : AppColors.lightText;
    final textSec  = isDark ? AppColors.darkTextDate : AppColors.lightTextDate;
    final cardBg   = isDark ? AppColors.darkCard     : AppColors.lightBg;
    final divider  = isDark ? AppColors.darkDivider  : AppColors.lightDivider;
    final catColor = AppColors.categoryColor(event.category);
    final appFont  = context.watch<AppState>().appFont;

    // Use effectiveDate (computed repeat occurrence) if provided, else fall back to reminderDate
    final displayDate = effectiveDate ?? event.reminderDate;
    String? timeLabel;
    if (displayDate != null) {
      timeLabel = showDate
          ? DateFormat('d MMM, HH:mm', 'ru').format(displayDate)
          : DateFormat('HH:mm').format(displayDate);
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
          if (repeatLabel(event.repeat, event.customDays, s: context.read<AppState>().s).isNotEmpty)
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


// ─── Calendar Search Screen ───────────────────────────────
class CalendarSearchScreen extends StatefulWidget {
  const CalendarSearchScreen({super.key});
  @override
  State<CalendarSearchScreen> createState() => _CalendarSearchScreenState();
}

class _CalendarSearchScreenState extends State<CalendarSearchScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ── Build list of upcoming days with events/todos (next 70 days) ──
  List<_CalDayGroup> _buildDayGroups(AppState state, String query) {
    final today  = DateTime.now();
    final todayD = DateTime(today.year, today.month, today.day);
    final endD   = todayD.add(const Duration(days: 70));

    final q = query.trim().toLowerCase();

    // Collect all (event, effectiveDate) pairs in range
    final eventPairs = <MapEntry<AppEvent, DateTime>>[];
    for (final e in state.events) {
      if (e.reminderDate == null) continue;
      if (e.repeat == RepeatInterval.none) {
        final d = DateTime(e.reminderDate!.year, e.reminderDate!.month, e.reminderDate!.day);
        if (!d.isBefore(todayD) && !d.isAfter(endD)) {
          if (q.isEmpty || e.title.toLowerCase().contains(q) || e.body.toLowerCase().contains(q)) {
            eventPairs.add(MapEntry(e, e.reminderDate!));
          }
        }
      } else {
        // For repeating events collect all occurrences in range
        DateTime? cur = nextOccurrence(e, todayD.subtract(const Duration(days: 1)));
        int iter = 0;
        while (cur != null && !cur.isAfter(endD) && iter < 100) {
          final dayOnly = DateTime(cur.year, cur.month, cur.day);
          if (!dayOnly.isBefore(todayD)) {
            if (q.isEmpty || e.title.toLowerCase().contains(q) || e.body.toLowerCase().contains(q)) {
              eventPairs.add(MapEntry(e, cur));
            }
          }
          cur = nextOccurrence(e, cur);
          iter++;
        }
      }
    }

    // Collect todos in range
    final todoPairs = <MapEntry<TodoGroup, DateTime>>[];
    for (final t in state.todos) {
      if (t.reminderDate == null) continue;
      final d = DateTime(t.reminderDate!.year, t.reminderDate!.month, t.reminderDate!.day);
      if (!d.isBefore(todayD) && !d.isAfter(endD)) {
        if (q.isEmpty || t.name.toLowerCase().contains(q)) {
          todoPairs.add(MapEntry(t, t.reminderDate!));
        }
      }
    }

    // Group by date
    final Map<DateTime, _CalDayGroup> groups = {};
    for (final ep in eventPairs) {
      final dayKey = DateTime(ep.value.year, ep.value.month, ep.value.day);
      groups.putIfAbsent(dayKey, () => _CalDayGroup(dayKey)).events.add(
        _EffEvent(ep.key, ep.value),
      );
    }
    for (final tp in todoPairs) {
      final dayKey = DateTime(tp.value.year, tp.value.month, tp.value.day);
      groups.putIfAbsent(dayKey, () => _CalDayGroup(dayKey)).todos.add(tp.key);
    }

    final result = groups.values.toList()..sort((a, b) => a.day.compareTo(b.day));
    for (final g in result) {
      g.events.sort((a, b) => a.date.compareTo(b.date));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final state   = context.watch<AppState>();
    final isDark  = state.darkMode;
    final bg      = isDark ? AppColors.darkBg2   : AppColors.lightBg2;
    final surface = isDark ? AppColors.darkBg    : AppColors.lightBg;
    final text    = isDark ? AppColors.darkText  : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextDate : AppColors.lightTextDate;
    final divider = isDark ? AppColors.darkDivider  : AppColors.lightDivider;
    final fieldBg = isDark ? AppColors.darkSearchBg : AppColors.lightSearchBg;

    final groups = _buildDayGroups(state, _query);
    final today  = DateTime.now();
    final todayD = DateTime(today.year, today.month, today.day);

    String dayLabel(DateTime d) {
      if (_sameDay(d, todayD)) return state.s.today;
      if (_sameDay(d, todayD.add(const Duration(days: 1)))) return state.s.tomorrow;
      final weekdays = state.s.weekdaysShort;
      final months   = state.s.monthsLower;
      final wd = weekdays[d.weekday - 1];
      final mo = months[d.month - 1];
      return '${d.day} $mo, $wd';
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0, shadowColor: Colors.transparent, surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, size: 18, color: text),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchCtrl,
          focusNode: _focusNode,
          onChanged: (v) => setState(() => _query = v),
          style: appTitleStyle(state.appFont, size: 15, color: text),
          decoration: InputDecoration(
            hintText: state.s.searchAll,
            hintStyle: appTitleStyle(state.appFont, size: 15,
                color: isDark ? AppColors.darkTextDate : AppColors.lightTextDate),
            filled: true, fillColor: fieldBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            isDense: true,
            suffixIcon: _query.isNotEmpty
                ? GestureDetector(
                    onTap: () { _searchCtrl.clear(); setState(() => _query = ''); },
                    child: Icon(Icons.close_rounded, size: 16, color: textSec),
                  )
                : null,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: divider, height: 1),
        ),
      ),
      body: groups.isEmpty
          ? Center(child: Text(
              _query.isEmpty ? state.s.noUpcoming : state.s.noResults,
              style: GoogleFonts.dmSans(fontSize: 14, color: textSec),
            ))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: groups.length,
              itemBuilder: (ctx, i) {
                final group = groups[i];
                final isToday = _sameDay(group.day, todayD);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Day header ──
                    Container(
                      color: surface,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.terracotta
                                : AppColors.terracotta.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text('${group.day.day}', style: GoogleFonts.dmSans(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: isToday ? Colors.white : AppColors.terracotta,
                          )),
                        ),
                        const SizedBox(width: 10),
                        Text(dayLabel(group.day), style: appTitleStyle(state.appFont,
                          size: 13, weight: FontWeight.w700,
                          color: isToday ? AppColors.terracotta : text,
                        )),
                      ]),
                    ),
                    // ── Events ──
                    ...group.events.map((ee) => _SearchEventTile(
                      effEvent: ee, isDark: isDark,
                      onTap: () => showDialog(
                        context: context,
                        barrierColor: Colors.black.withValues(alpha: 0.4),
                        builder: (_) => EventEditorDialog(event: ee.event),
                      ),
                    )),
                    // ── Todos ──
                    ...group.todos.map((t) => _SearchTodoTile(
                      group: t, isDark: isDark,
                      onTap: () => showDialog(
                        context: context,
                        barrierColor: Colors.black.withValues(alpha: 0.4),
                        builder: (_) => TodoEditorDialog(group: t),
                      ),
                    )),
                    Divider(color: divider.withValues(alpha: 0.5), height: 1),
                  ],
                );
              },
            ),
    );
  }
}

class _CalDayGroup {
  final DateTime day;
  final List<_EffEvent> events = [];
  final List<TodoGroup> todos  = [];
  _CalDayGroup(this.day);
}

class _SearchEventTile extends StatelessWidget {
  final _EffEvent effEvent;
  final bool isDark;
  final VoidCallback onTap;
  const _SearchEventTile({required this.effEvent, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final e       = effEvent.event;
    final text    = isDark ? AppColors.darkText     : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextDate : AppColors.lightTextDate;
    final cardBg  = isDark ? AppColors.darkCard     : AppColors.lightBg;
    final divider = isDark ? AppColors.darkDivider  : AppColors.lightDivider;
    final catColor= AppColors.categoryColor(e.category);
    final appFont = context.watch<AppState>().appFont;
    final timeStr = DateFormat('HH:mm').format(effEvent.date);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: divider, width: 0.5),
        ),
        child: Row(children: [
          Container(width: 3, height: 36,
            decoration: BoxDecoration(color: catColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.title, style: appTitleStyle(appFont,
                size: 13, weight: FontWeight.w600, color: text)),
            Text(timeStr, style: GoogleFonts.dmSans(
                fontSize: 11, color: AppColors.terracotta)),
          ])),
          if (e.repeat != RepeatInterval.none)
            Icon(Icons.repeat_rounded, size: 13, color: textSec),
        ]),
      ),
    );
  }
}

class _SearchTodoTile extends StatelessWidget {
  final TodoGroup group;
  final bool isDark;
  final VoidCallback onTap;
  const _SearchTodoTile({required this.group, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text    = isDark ? AppColors.darkText     : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextDate : AppColors.lightTextDate;
    final cardBg  = isDark ? AppColors.darkCard     : AppColors.lightBg;
    final divider = isDark ? AppColors.darkDivider  : AppColors.lightDivider;
    final catColor= AppColors.categoryColor(group.category);
    final appFont = context.watch<AppState>().appFont;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: divider, width: 0.5),
        ),
        child: Row(children: [
          Container(width: 3, height: 36,
            decoration: BoxDecoration(color: catColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(group.name, style: appTitleStyle(appFont,
                size: 13, weight: FontWeight.w600, color: text)),
            Text('${group.doneCount}/${group.total} выполнено',
                style: GoogleFonts.dmSans(fontSize: 11, color: textSec)),
          ])),
          SizedBox(width: 28, height: 28,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                value: group.total > 0 ? group.doneCount / group.total : 0,
                strokeWidth: 2, color: AppColors.terracotta,
                backgroundColor: AppColors.terracotta.withValues(alpha: 0.15),
              ),
              Text('${group.doneCount}', style: GoogleFonts.dmSans(
                fontSize: 8, fontWeight: FontWeight.w700, color: AppColors.terracotta)),
            ]),
          ),
        ]),
      ),
    );
  }
}
