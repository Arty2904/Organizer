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
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'События',
                style: GoogleFonts.fraunces(
                  fontSize: 26, fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${events.length} событий',
                style: GoogleFonts.dmSans(
                  fontSize: 11, fontStyle: FontStyle.italic,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 10),
              AppSearchBar(onChanged: (q) => setState(() => _query = q), hint: 'Поиск событий...'),
              const SizedBox(height: 10),
              CategoryFilterRow(
                categories: AppState.eventCategories,
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
        Icon(Icons.event_outlined, size: 48, color: AppColors.terracotta.withOpacity(0.3)),
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
      itemBuilder: (ctx, i) => _EventCard(
        event: events[i],
        showTag: state.eventsFilter == 'Все',
        view: 1,
        onTap: () => _openEditor(context, events[i]),
        onCheckTask: (idx) => state.toggleEventTask(events[i].id, idx),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventEditorSheet(event: event),
    );
  }
}

// ─── Event Card ────────────────────────────────────────────
class _EventCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.darkMode;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final catColor = AppColors.categoryColor(event.category);
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
          border: Border.all(color: divider, width: 0.5),
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
                    ), maxLines: view == 2 ? 2 : null, overflow: view == 2 ? TextOverflow.ellipsis : null),
                  ),
                ],
                if (event.reminderDate != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.terracotta.withOpacity(0.12),
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
                          Text('· $repeatStr', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.terracotta.withOpacity(0.7))),
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
            Positioned(
              top: 0, right: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (showTag) CategoryBadge(label: event.category),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Event Editor Sheet ────────────────────────────────────
class EventEditorSheet extends StatefulWidget {
  final AppEvent? event;
  const EventEditorSheet({super.key, this.event});

  @override
  State<EventEditorSheet> createState() => _EventEditorSheetState();
}

class _EventEditorSheetState extends State<EventEditorSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _bodyCtrl;
  late String _category;
  DateTime? _reminderDate;
  RepeatInterval _repeat = RepeatInterval.none;
  int? _customDays;
  late List<TextEditingController> _taskCtrls;
  late List<bool> _taskDone;
  final List<FocusNode> _focusNodes = [];
  final _customDaysCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _bodyCtrl = TextEditingController(text: e?.body ?? '');
    _category = e?.category ?? 'Личное';
    _reminderDate = e?.reminderDate;
    _repeat = e?.repeat ?? RepeatInterval.none;
    _customDays = e?.customDays;
    if (_customDays != null) _customDaysCtrl.text = _customDays.toString();
    final tasks = e?.tasks ?? [];
    _taskCtrls = tasks.map((t) => TextEditingController(text: t.text)).toList();
    _taskDone = tasks.map((t) => t.done).toList();
    _focusNodes.addAll(List.generate(_taskCtrls.length, (_) => FocusNode()));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _customDaysCtrl.dispose();
    for (var c in _taskCtrls) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _addTask() {
    setState(() {
      _taskCtrls.add(TextEditingController());
      _taskDone.add(false);
      _focusNodes.add(FocusNode());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNodes.last.requestFocus());
  }

  Future<void> _pickDate() async {
    final isDark = context.read<AppState>().darkMode;
    final dt = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (ctx, child) => Theme(
        data: buildTheme(isDark),
        child: child!,
      ),
    );
    if (dt != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_reminderDate ?? DateTime.now()),
      );
      if (time != null && mounted) {
        setState(() => _reminderDate = DateTime(dt.year, dt.month, dt.day, time.hour, time.minute));
      }
    }
  }

  void _save() {
    final state = context.read<AppState>();
    final tasks = _taskCtrls.asMap().entries
        .where((e) => e.value.text.trim().isNotEmpty)
        .map((e) => EventTask(text: e.value.text.trim(), done: _taskDone[e.key]))
        .toList();
    final customD = _repeat == RepeatInterval.custom ? int.tryParse(_customDaysCtrl.text) : null;

    if (widget.event != null) {
      widget.event!
        ..title = _titleCtrl.text.trim().isEmpty ? 'Событие' : _titleCtrl.text.trim()
        ..body = _bodyCtrl.text
        ..category = _category
        ..reminderDate = _reminderDate
        ..repeat = _repeat
        ..customDays = customD
        ..tasks = tasks;
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
        tasks: tasks,
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
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    final repeatLabels = {
      RepeatInterval.none: 'Не повторять',
      RepeatInterval.daily: 'Каждый день',
      RepeatInterval.weekly: 'Каждую неделю',
      RepeatInterval.monthly: 'Каждый месяц',
      RepeatInterval.yearly: 'Каждый год',
      RepeatInterval.custom: 'Через N дней',
    };

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: divider, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _titleCtrl,
                      style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w600, color: text),
                      decoration: InputDecoration(
                        filled: false, border: InputBorder.none,
                        hintText: 'Название события',
                        hintStyle: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w600, color: textSec.withOpacity(0.4)),
                      ),
                    ),
                  ),
                  if (widget.event != null)
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, color: Colors.red.withOpacity(0.7), size: 20),
                      onPressed: _delete,
                    ),
                ],
              ),
            ),
            // Category
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: AppState.eventCategories.skip(1).map((cat) {
                    final sel = _category == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _category = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.categoryColor(cat) : (isDark ? AppColors.darkCard : AppColors.lightCardAlt),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(cat, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: sel ? Colors.white : textSec)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: divider, height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    TextField(
                      controller: _bodyCtrl,
                      style: GoogleFonts.dmSans(fontSize: 13, color: text),
                      maxLines: 3,
                      decoration: InputDecoration(
                        filled: false, border: InputBorder.none,
                        hintText: 'Описание...',
                        hintStyle: GoogleFonts.dmSans(fontSize: 13, color: textSec.withOpacity(0.4)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Reminder date
                    _Section(label: 'Напоминание', isDark: isDark, child: GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCardAlt,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.notifications_outlined, size: 16, color: AppColors.terracotta),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _reminderDate != null ? formatDateTime(_reminderDate) : 'Выбрать дату и время',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: _reminderDate != null ? text : textSec,
                                ),
                              ),
                            ),
                            if (_reminderDate != null)
                              GestureDetector(
                                onTap: () => setState(() => _reminderDate = null),
                                child: Icon(Icons.close_rounded, size: 16, color: textSec),
                              ),
                          ],
                        ),
                      ),
                    )),
                    const SizedBox(height: 12),
                    // Repeat
                    _Section(label: 'Повторять', isDark: isDark, child: Column(
                      children: [
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: repeatLabels.entries.map((e) {
                            final sel = _repeat == e.key;
                            return GestureDetector(
                              onTap: () => setState(() => _repeat = e.key),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: sel ? AppColors.terracotta : (isDark ? AppColors.darkCard : AppColors.lightCardAlt),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(e.value, style: GoogleFonts.dmSans(
                                  fontSize: 11, fontWeight: FontWeight.w600,
                                  color: sel ? Colors.white : textSec,
                                )),
                              ),
                            );
                          }).toList(),
                        ),
                        if (_repeat == RepeatInterval.custom) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text('Через ', style: GoogleFonts.dmSans(fontSize: 13, color: text)),
                              SizedBox(
                                width: 60,
                                child: TextField(
                                  controller: _customDaysCtrl,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.dmSans(fontSize: 13, color: text),
                                  decoration: InputDecoration(
                                    hintText: '7',
                                    hintStyle: GoogleFonts.dmSans(fontSize: 13, color: textSec),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                ),
                              ),
                              Text(' дней', style: GoogleFonts.dmSans(fontSize: 13, color: text)),
                            ],
                          ),
                        ],
                      ],
                    )),
                    const SizedBox(height: 12),
                    // Tasks
                    _Section(label: 'Задачи', isDark: isDark, child: Column(
                      children: [
                        ..._taskCtrls.asMap().entries.map((e) {
                          final i = e.key;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => setState(() => _taskDone[i] = !_taskDone[i]),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 18, height: 18,
                                    decoration: BoxDecoration(
                                      color: _taskDone[i] ? AppColors.terracotta : Colors.transparent,
                                      border: Border.all(color: _taskDone[i] ? AppColors.terracotta : divider, width: 1.5),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: _taskDone[i] ? const Icon(Icons.check_rounded, size: 11, color: Colors.white) : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _taskCtrls[i],
                                    focusNode: _focusNodes[i],
                                    style: GoogleFonts.dmSans(fontSize: 13, color: text),
                                    decoration: InputDecoration(
                                      filled: false, border: InputBorder.none,
                                      hintText: 'Задача...',
                                      hintStyle: GoogleFonts.dmSans(fontSize: 13, color: textSec.withOpacity(0.4)),
                                    ),
                                    onSubmitted: (_) => _addTask(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        GestureDetector(
                          onTap: _addTask,
                          child: Row(
                            children: [
                              Icon(Icons.add_rounded, size: 18, color: AppColors.terracotta),
                              const SizedBox(width: 8),
                              Text('Добавить задачу', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.terracotta)),
                            ],
                          ),
                        ),
                      ],
                    )),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Divider(color: divider, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: GestureDetector(
                onTap: _save,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: AppColors.terracotta, borderRadius: BorderRadius.circular(14)),
                  alignment: Alignment.center,
                  child: Text('Сохранить', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  final bool isDark;
  final Widget child;
  const _Section({required this.label, required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.2,
            color: AppColors.terracotta,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
