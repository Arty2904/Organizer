import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.darkMode;
    final events = state.filteredEvents(_query);
    final v = state.eventsView;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSearchBar(onChanged: (q) => setState(() => _query = q), hint: 'Поиск событий...'),
              const SizedBox(height: 10),
              CategoryFilterRow(
                categories: state.eventCategories,
                selected: state.eventsFilter,
                onSelect: (c) { state.eventsFilter = c; state.refresh(); },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        Expanded(
          child: events.isEmpty
              ? _emptyState(isDark)
              : v == 1
                  ? _listView(context, events, state)
                  : v == 2
                      ? _gridView(context, events, state)
                      : _compactView(context, events, state),
        ),
      ],
    );
  }

  Widget _emptyState(bool isDark) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.event_outlined, size: 48, color: AppColors.terracotta.withValues(alpha: 0.3)),
        const SizedBox(height: 12),
        Text('Нет событий', style: GoogleFonts.fraunces(
          fontSize: 16, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        )),
      ],
    ),
  );

  Widget _listView(BuildContext context, List<AppEvent> events, AppState state) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _SwipableCard(
        key: ValueKey(events[i].id),
        itemKey: ValueKey('del-event-${events[i].id}'),
        padding: const EdgeInsets.only(bottom: 10),
        onDelete: () => state.deleteEvent(events[i].id),
        child: _EventCard(
          event: events[i],
          showTag: state.eventsFilter == 'Все',
          view: 1,
          onTap: () => _openEditor(context, events[i]),
          onCheckTask: (idx) => state.toggleEventTask(events[i].id, idx),
        ),
      ),
    );
  }

  Widget _gridView(BuildContext context, List<AppEvent> events, AppState state) {
    return MasonryGridView.count(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      itemCount: events.length,
      itemBuilder: (ctx, i) => _EventCard(
        event: events[i],
        showTag: state.eventsFilter == 'Все',
        view: 2,
        onTap: () => _openEditor(context, events[i]),
        onCheckTask: (idx) => state.toggleEventTask(events[i].id, idx),
      ),
    );
  }

  Widget _compactView(BuildContext context, List<AppEvent> events, AppState state) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: events.length,
      itemBuilder: (ctx, i) => _EventCard(
        event: events[i],
        showTag: false,
        view: 3,
        onTap: () => _openEditor(context, events[i]),
        onCheckTask: (idx) => state.toggleEventTask(events[i].id, idx),
      ),
    );
  }

  void _openEditor(BuildContext context, [AppEvent? event]) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => EventEditorDialog(event: event),
    );
  }
}


// ─── Swipable Card ─────────────────────────────────────────
class _SwipableCard extends StatelessWidget {
  final Key itemKey;
  final Widget child;
  final VoidCallback onDelete;
  final EdgeInsets padding;
  const _SwipableCard({super.key, required this.itemKey, required this.child, required this.onDelete, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().darkMode;
    return Dismissible(
      key: itemKey,
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.4),
          builder: (ctx) {
            final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
            final text = isDark ? AppColors.darkText : AppColors.lightText;
            final textSec = isDark ? AppColors.darkTextBody : AppColors.lightTextBody;
            return Dialog(
              backgroundColor: bg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Удалить?', style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w600, color: text)),
                    const SizedBox(height: 8),
                    Text('Это действие нельзя отменить.', style: GoogleFonts.dmSans(fontSize: 13, color: textSec)),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(child: GestureDetector(
                        onTap: () => Navigator.pop(ctx, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: isDark ? AppColors.darkBg2 : AppColors.lightBg2, borderRadius: BorderRadius.circular(12)),
                          alignment: Alignment.center,
                          child: Text('Отмена', style: GoogleFonts.dmSans(fontSize: 13, color: textSec, fontWeight: FontWeight.w600)),
                        ),
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: GestureDetector(
                        onTap: () => Navigator.pop(ctx, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(12)),
                          alignment: Alignment.center,
                          child: Text('Удалить', style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      )),
                    ]),
                  ],
                ),
              ),
            );
          },
        ) ?? false;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: padding,
        decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(18)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

// ─── Event Card ────────────────────────────────────────────
class _EventCard extends StatefulWidget {
  final AppEvent event;
  final bool showTag;
  final int view;
  final VoidCallback onTap;
  final ValueChanged<int> onCheckTask;

  const _EventCard({
    required this.event,
    required this.showTag,
    required this.view,
    required this.onTap,
    required this.onCheckTask,
  });

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  bool _bodyExpanded = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final showTag = widget.showTag;
    final view = widget.view;
    final onTap = widget.onTap;
    final onCheckTask = widget.onCheckTask;

    final state = context.watch<AppState>();
    final isDark = state.darkMode;
    final cardBg = isDark ? const Color(0x0DFFFFFF) : const Color(0x40FFFFFF);
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextBody : AppColors.lightTextBody;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final catColor = state.folderColor(event.category);
    final maxTasks = view == 2 ? 3 : event.tasks.length;
    final tasks = event.tasks.take(maxTasks).toList();
    final repeatStr = repeatLabel(event.repeat, event.customDays);

    if (view == 3) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: divider))),
          child: Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: catColor, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(child: Text(event.title, style: GoogleFonts.fraunces(
                fontSize: 13, fontWeight: FontWeight.w600, color: textColor,
              ), overflow: TextOverflow.ellipsis)),
              if (event.reminderDate != null)
                Text(formatDate(event.reminderDate!), style: GoogleFonts.dmSans(fontSize: 10, color: textSec)),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(view == 2 ? 12 : 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(view == 2 ? 16 : 18),
          border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder, width: 1),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 60),
                  child: Row(
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: catColor, shape: BoxShape.circle)),
                      const SizedBox(width: 7),
                      Expanded(child: Text(event.title, style: GoogleFonts.fraunces(
                        fontSize: view == 2 ? 13 : 15, fontWeight: FontWeight.w600, color: textColor,
                      ))),
                    ],
                  ),
                ),
                if (event.body.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.only(right: 60),
                    child: Text(event.body, style: GoogleFonts.dmSans(
                      fontSize: view == 2 ? 11 : 12, color: textSec, height: 1.4,
                    ), maxLines: view == 1 ? (_bodyExpanded ? 10 : 3) : 2, overflow: TextOverflow.ellipsis),
                  ),
                  if (view == 1)
                    LayoutBuilder(builder: (ctx, constraints) {
                      final tp = TextPainter(
                        text: TextSpan(
                          text: event.body,
                          style: GoogleFonts.dmSans(fontSize: 12, height: 1.4),
                        ),
                        maxLines: 3,
                        textDirection: TextDirection.ltr,
                      )..layout(maxWidth: constraints.maxWidth);
                      if (!tp.didExceedMaxLines) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: GestureDetector(
                          onTap: () => setState(() => _bodyExpanded = !_bodyExpanded),
                          child: Text(
                            _bodyExpanded ? 'Свернуть' : 'Ещё',
                            style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.terracotta),
                          ),
                        ),
                      );
                    }),
                ],
                if (event.reminderDate != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.terracotta.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_outlined, size: 11, color: AppColors.terracotta),
                        const SizedBox(width: 4),
                        Text(
                          formatDateTime(event.reminderDate),
                          style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.terracotta, fontWeight: FontWeight.w600),
                        ),
                        if (repeatStr.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text('· $repeatStr', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.terracotta.withValues(alpha: 0.7))),
                        ],
                      ],
                    ),
                  ),
                ],
                if (tasks.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...tasks.asMap().entries.map((e) {
                    final item = e.value;
                    return GestureDetector(
                      onTap: () => onCheckTask(e.key),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 16, height: 16,
                              decoration: BoxDecoration(
                                color: item.done ? AppColors.terracotta : Colors.transparent,
                                border: Border.all(color: item.done ? AppColors.terracotta : divider, width: 1.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: item.done ? const Icon(Icons.check_rounded, size: 10, color: Colors.white) : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item.text, style: GoogleFonts.dmSans(
                              fontSize: view == 2 ? 11 : 12,
                              color: item.done ? textSec : textColor,
                              decoration: item.done ? TextDecoration.lineThrough : null,
                              decorationColor: textSec,
                            ), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
            if (showTag)
              Positioned(
                top: 0, right: 0,
                child: CategoryBadge(
                  label: event.category.length > 7
                      ? event.category.substring(0, 7)
                      : event.category,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Event Editor Dialog (center) ────────────────────────
class EventEditorDialog extends StatefulWidget {
  final AppEvent? event;
  final String initialCategory;
  const EventEditorDialog({super.key, this.event, this.initialCategory = ''});

  @override
  State<EventEditorDialog> createState() => _EventEditorDialogState();
}

class _EventEditorDialogState extends State<EventEditorDialog> {
  late TextEditingController _titleCtrl;
  late TextEditingController _bodyCtrl;
  late String _category;
  DateTime? _reminderDate;
  RepeatInterval _repeat = RepeatInterval.none;
  int? _customDays;
  final _customDaysCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _bodyCtrl = TextEditingController(text: e?.body ?? '');
    _category = e?.category ?? widget.initialCategory ?? '';
    _reminderDate = e?.reminderDate;
    _repeat = e?.repeat ?? RepeatInterval.none;
    _customDays = e?.customDays;
    if (_customDays != null) _customDaysCtrl.text = _customDays.toString();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _customDaysCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final isDark = context.read<AppState>().darkMode;
    final result = await showDialog<DateTime>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _CustomDateTimePicker(
        initial: _reminderDate ?? DateTime.now().add(const Duration(days: 1)),
        isDark: isDark,
      ),
    );
    if (result != null && mounted) {
      setState(() => _reminderDate = result);
    }
  }

  void _showRepeatPicker() {
    final isDark = context.read<AppState>().darkMode;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextBody : AppColors.lightTextBody;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    final labels = {
      RepeatInterval.none: 'Не повторять',
      RepeatInterval.daily: 'Каждый день',
      RepeatInterval.weekly: 'Каждую неделю',
      RepeatInterval.monthly: 'Каждый месяц',
      RepeatInterval.yearly: 'Каждый год',
      RepeatInterval.custom: 'Через N дней',
    };

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (ctx) => Dialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text('Повторять', style: GoogleFonts.fraunces(
                  fontSize: 16, fontWeight: FontWeight.w600, color: text,
                )),
              ),
              Divider(color: divider, height: 1),
              ...labels.entries.map((e) {
                final sel = _repeat == e.key;
                return GestureDetector(
                  onTap: () {
                    setState(() => _repeat = e.key);
                    Navigator.pop(ctx);
                    if (e.key == RepeatInterval.custom) _showCustomDaysPicker();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    color: Colors.transparent,
                    child: Row(
                      children: [
                        Expanded(child: Text(e.value, style: GoogleFonts.dmSans(
                          fontSize: 14, color: sel ? AppColors.terracotta : text,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        ))),
                        if (sel) Icon(Icons.check_rounded, size: 16, color: AppColors.terracotta),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomDaysPicker() {
    final isDark = context.read<AppState>().darkMode;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (ctx) => Dialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Через сколько дней?', style: GoogleFonts.fraunces(
                fontSize: 16, fontWeight: FontWeight.w600, color: text,
              )),
              const SizedBox(height: 16),
              TextField(
                controller: _customDaysCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: GoogleFonts.dmSans(fontSize: 20, color: text),
                decoration: InputDecoration(
                  suffixText: 'дней',
                  suffixStyle: GoogleFonts.dmSans(fontSize: 14, color: text),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _customDays = int.tryParse(_customDaysCtrl.text));
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.terracotta,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Готово', style: GoogleFonts.dmSans(
                      fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white,
                    )),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _repeatLabel {
    switch (_repeat) {
      case RepeatInterval.none: return 'Не повторять';
      case RepeatInterval.daily: return 'Каждый день';
      case RepeatInterval.weekly: return 'Каждую неделю';
      case RepeatInterval.monthly: return 'Каждый месяц';
      case RepeatInterval.yearly: return 'Каждый год';
      case RepeatInterval.custom:
        final d = _customDays ?? int.tryParse(_customDaysCtrl.text);
        return d != null ? 'Через $d дней' : 'Через N дней';
    }
  }

  void _save() {
    final state = context.read<AppState>();
    final customD = _repeat == RepeatInterval.custom ? int.tryParse(_customDaysCtrl.text) : null;
    if (widget.event != null) {
      widget.event!
        ..title = _titleCtrl.text.trim().isEmpty ? 'Событие' : _titleCtrl.text.trim()
        ..body = _bodyCtrl.text
        ..category = _category
        ..reminderDate = _reminderDate
        ..repeat = _repeat
        ..customDays = customD
        ..tasks = widget.event!.tasks; // сохраняем существующие задачи
      state.updateEvent(widget.event!);
    } else {
      state.addEvent(AppEvent(
        id: const Uuid().v4(),
        title: _titleCtrl.text.trim().isEmpty ? 'Событие' : _titleCtrl.text.trim(),
        body: _bodyCtrl.text,
        category: _category,
        reminderDate: _reminderDate,
        repeat: _repeat,
        customDays: customD,
        tasks: [],
      ));
    }
    Navigator.pop(context);
  }

  void _delete() {
    if (widget.event != null) context.read<AppState>().deleteEvent(widget.event!.id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.darkMode;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextBody : AppColors.lightTextBody;
    final textHint = isDark ? const Color(0x4DE6AF78) : const Color(0x6E785028);
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final fieldBg = isDark ? AppColors.darkCard : AppColors.lightCardAlt;

    return Dialog(
      backgroundColor: bg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Шапка ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleCtrl,
                    autofocus: widget.event == null,
                    style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w600, color: text),
                    decoration: InputDecoration(
                      filled: false, border: InputBorder.none,
                      hintText: 'Название события',
                      hintStyle: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w600, color: textHint),
                      contentPadding: EdgeInsets.zero, isDense: true,
                    ),
                  ),
                ),
                if (widget.event != null)
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: Colors.red.withValues(alpha: 0.7), size: 20),
                    onPressed: _delete,
                  ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: textSec, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // ── Категория ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['', ...context.read<AppState>().eventFolders].map((cat) {
                  final sel = _category == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _category = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: sel ? state.folderColor(cat) : fieldBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(cat.isEmpty ? '–' : cat, style: GoogleFonts.dmSans(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : textSec,
                        )),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: divider, height: 1),
          const SizedBox(height: 12),
          // ── Описание ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _bodyCtrl,
              style: GoogleFonts.dmSans(fontSize: 13, color: text),
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                filled: false, border: InputBorder.none,
                hintText: 'Описание...',
                hintStyle: GoogleFonts.dmSans(fontSize: 13, color: textHint),
                contentPadding: EdgeInsets.zero, isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ── Поля Напоминание / Повтор ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Напоминание
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: fieldBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('НАПОМИНАНИЕ', style: GoogleFonts.dmSans(
                            fontSize: 8, fontWeight: FontWeight.w800,
                            letterSpacing: 1.1, color: AppColors.terracotta,
                          )),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.notifications_outlined, size: 13, color: _reminderDate != null ? AppColors.terracotta : textSec),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _reminderDate != null ? formatDateTime(_reminderDate) : 'Не задано',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: _reminderDate != null ? text : textSec,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_reminderDate != null)
                                GestureDetector(
                                  onTap: () => setState(() => _reminderDate = null),
                                  child: Icon(Icons.close_rounded, size: 13, color: textSec),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Повтор
                Expanded(
                  child: GestureDetector(
                    onTap: _showRepeatPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: fieldBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ПОВТОР', style: GoogleFonts.dmSans(
                            fontSize: 8, fontWeight: FontWeight.w800,
                            letterSpacing: 1.1, color: AppColors.terracotta,
                          )),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.repeat_rounded, size: 13, color: _repeat != RepeatInterval.none ? AppColors.terracotta : textSec),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _repeatLabel,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: _repeat != RepeatInterval.none ? text : textSec,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // ── Кнопка сохранить ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: GestureDetector(
              onTap: _save,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.terracotta,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text('Сохранить', style: GoogleFonts.dmSans(
                  fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white,
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Custom DateTime Picker (drum scroll) ─────────────────
class _CustomDateTimePicker extends StatefulWidget {
  final DateTime initial;
  final bool isDark;
  const _CustomDateTimePicker({required this.initial, required this.isDark});

  @override
  State<_CustomDateTimePicker> createState() => _CustomDateTimePickerState();
}

class _CustomDateTimePickerState extends State<_CustomDateTimePicker> {
  late int _day, _month, _year, _hour, _minute;

  // Контроллеры для барабанов
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
    _day   = d.day;
    _month = d.month;
    _year  = d.year;
    _hour  = d.hour;
    _minute = d.minute;

    _dayCtrl    = FixedExtentScrollController(initialItem: _day - 1);
    _monthCtrl  = FixedExtentScrollController(initialItem: _month - 1);
    _yearCtrl   = FixedExtentScrollController(initialItem: _year - _startYear);
    _hourCtrl   = FixedExtentScrollController(initialItem: _hour);
    _minuteCtrl = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _dayCtrl.dispose(); _monthCtrl.dispose(); _yearCtrl.dispose();
    _hourCtrl.dispose(); _minuteCtrl.dispose();
    super.dispose();
  }

  void _onDayChanged(int i) {
    setState(() {
      _day = i + 1;
      final max = _daysInMonth(_month, _year);
      if (_day > max) _day = max;
    });
  }

  void _onMonthChanged(int i) {
    setState(() {
      _month = i + 1;
      final max = _daysInMonth(_month, _year);
      if (_day > max) {
        _day = max;
        _dayCtrl.jumpToItem(_day - 1);
      }
    });
  }

  void _onYearChanged(int i) {
    setState(() {
      _year = _startYear + i;
      final max = _daysInMonth(_month, _year);
      if (_day > max) {
        _day = max;
        _dayCtrl.jumpToItem(_day - 1);
      }
    });
  }

  Widget _drum({
    required FixedExtentScrollController ctrl,
    required int itemCount,
    required String Function(int) label,
    required ValueChanged<int> onChanged,
    required bool isDark,
    double width = 64,
  }) {
    final text    = isDark ? AppColors.darkText     : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextDate : AppColors.lightTextDate;
    final selBg   = isDark ? AppColors.darkBg2      : AppColors.lightBg2;

    return SizedBox(
      width: width,
      height: 180,
      child: Stack(
        children: [
          // Выделение центрального элемента
          Center(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: selBg,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          // Барабан
          ListWheelScrollView.useDelegate(
            controller: ctrl,
            itemExtent: 44,
            perspective: 0.003,
            diameterRatio: 1.6,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: itemCount,
              builder: (ctx, i) {
                final selected = ctrl.hasClients
                    ? (ctrl.selectedItem == i)
                    : false;
                return Center(
                  child: Text(
                    label(i),
                    style: GoogleFonts.fraunces(
                      fontSize: selected ? 20 : 15,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? text : textSec,
                    ),
                  ),
                );
              },
            ),
          ),
          // Fade top
          Positioned(
            top: 0, left: 0, right: 0,
            child: IgnorePointer(
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                      (isDark ? AppColors.darkSurface : AppColors.lightSurface).withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Fade bottom
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: IgnorePointer(
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                      (isDark ? AppColors.darkSurface : AppColors.lightSurface).withValues(alpha: 0),
                    ],
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
    final isDark  = widget.isDark;
    final bg      = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final text    = isDark ? AppColors.darkText    : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextDate : AppColors.lightTextDate;
    final divider = isDark ? AppColors.darkDivider  : AppColors.lightDivider;

    return Dialog(
      backgroundColor: bg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            Text('Дата и время', style: GoogleFonts.fraunces(
              fontSize: 17, fontWeight: FontWeight.w600, color: text,
            )),
            const SizedBox(height: 20),

            // ── Барабаны даты ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // День
                _drum(
                  ctrl: _dayCtrl,
                  itemCount: _daysInMonth(_month, _year),
                  label: (i) => '${i + 1}',
                  onChanged: _onDayChanged,
                  isDark: isDark,
                  width: 56,
                ),
                const SizedBox(width: 4),
                // Месяц
                _drum(
                  ctrl: _monthCtrl,
                  itemCount: 12,
                  label: (i) => _months[i],
                  onChanged: _onMonthChanged,
                  isDark: isDark,
                  width: 120,
                ),
                const SizedBox(width: 4),
                // Год
                _drum(
                  ctrl: _yearCtrl,
                  itemCount: _endYear - _startYear + 1,
                  label: (i) => '${_startYear + i}',
                  onChanged: _onYearChanged,
                  isDark: isDark,
                  width: 72,
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(color: divider, height: 1),
            const SizedBox(height: 12),

            // ── Барабаны времени ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _drum(
                  ctrl: _hourCtrl,
                  itemCount: 24,
                  label: (i) => i.toString().padLeft(2, '0'),
                  onChanged: (i) => setState(() => _hour = i),
                  isDark: isDark,
                  width: 64,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(' : ', style: GoogleFonts.fraunces(
                    fontSize: 22, fontWeight: FontWeight.w600, color: text)),
                ),
                _drum(
                  ctrl: _minuteCtrl,
                  itemCount: 60,
                  label: (i) => i.toString().padLeft(2, '0'),
                  onChanged: (i) => setState(() => _minute = i),
                  isDark: isDark,
                  width: 64,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Кнопки ──
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBg2 : AppColors.lightBg2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text('Отмена', style: GoogleFonts.dmSans(
                        fontSize: 13, fontWeight: FontWeight.w600, color: textSec)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context,
                        DateTime(_year, _month, _day, _hour, _minute)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: AppColors.terracotta,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text('Готово', style: GoogleFonts.dmSans(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
