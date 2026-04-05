import 'package:flutter/material.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_state.dart';
import '../l10n/app_strings.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../theme/font_helper.dart';
import '../widgets/common_widgets.dart';
import '../widgets/selection_state.dart';
import '../theme/card_colors.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _query = '';
  final Set<String> _expandedIds = {};
  final ValueNotifier<String?> _listDragState = ValueNotifier(null);

  @override
  void dispose() {
    _listDragState.dispose();
    super.dispose();
  }

  bool get _allExpanded {
    final state = context.read<AppState>();
    final events = state.filteredEvents(_query);
    return events.isNotEmpty && events.every((e) => _expandedIds.contains(e.id));
  }

  void _toggleAll(List<AppEvent> events) {
    setState(() {
      if (_allExpanded) {
        _expandedIds.clear();
      } else {
        for (final e in events) {
          _expandedIds.add(e.id);
        }
      }
    });
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final events = state.filteredEvents(_query);
    final v = state.eventsView;

    return Column(
      children: [
        ScreenHeader(
          searchHint: state.s.searchEvents,
          onSearch: (q) => setState(() => _query = q),
          categories: state.eventCategories,
          selectedCategory: state.eventsFilter,
          onSelectCategory: (c) { state.eventsFilter = c; state.refresh(); },
          colorResolver: state.folderColor,
        ),
        Expanded(
          child: events.isEmpty
              ? EmptyState(icon: Icons.event_outlined, label: state.s.noEvents)
              : v == 1
                  ? _listView(context, events, state)
                  : v == 2
                      ? _gridView(context, events, state)
                      : _compactView(context, events, state),
        ),
      ],
    );
  }

  Widget _listView(BuildContext context, List<AppEvent> events, AppState state) {
    return Column(
      children: [
        ExpandCollapseBar(allExpanded: _allExpanded, onToggle: () => _toggleAll(events)),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: events.length,
            itemBuilder: (ctx, i) {
              final event = events[i];
              final inner = SelectableCardWrapper(
                key: ValueKey(event.id),
                itemId: event.id,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _EventCard(
                    event: event,
                    showTag: state.eventsFilter == state.s.all,
                    view: 1,
                    expanded: _expandedIds.contains(event.id),
                    onToggleExpand: () => _toggleExpand(event.id),
                    isDarkOverride: state.darkMode,
                    onTap: () => _openEditor(context, event),
                    onCheckTask: (idx) => state.toggleEventTask(event.id, idx),
                  ),
                ),
              );
              if (state.eventsSort != 'manual') {
                return SwipableCard(
                  key: ValueKey('sw-ev-${event.id}'),
                  dismissKey: ValueKey('del-event-${event.id}'),
                  padding: const EdgeInsets.only(bottom: 10),
                  onDelete: () => state.deleteEvent(event.id),
                  child: SelectableCardWrapper(
                    key: ValueKey('sel-${event.id}'),
                    itemId: event.id,
                    child: _EventCard(
                      event: event,
                      showTag: state.eventsFilter == state.s.all,
                      view: 1,
                      expanded: _expandedIds.contains(event.id),
                      onToggleExpand: () => _toggleExpand(event.id),
                      isDarkOverride: state.darkMode,
                      onTap: () => _openEditor(context, event),
                      onCheckTask: (idx) => state.toggleEventTask(event.id, idx),
                    ),
                  ),
                );
              }
              return DraggableListCard(
                key: ValueKey(event.id),
                itemId: event.id,
                dragState: _listDragState,
                onReorder: (f, t) => state.reorderEventById(f, t),
                child: inner,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _gridView(BuildContext context, List<AppEvent> events, AppState state) {
    return _EventsMasonryGrid(
      events: events,
      state: state,
      onOpenEditor: (e) => _openEditor(context, e),
    );
  }

  Widget _compactView(BuildContext context, List<AppEvent> events, AppState state) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: events.length,
      itemBuilder: (ctx, i) {
        final card = SelectableCardWrapper(
          key: ValueKey(events[i].id),
          itemId: events[i].id,
          child: _EventCard(
            key: ValueKey('ev-compact-${events[i].id}'),
            event: events[i],
            showTag: false,
            view: 3,
            isDarkOverride: state.darkMode,
            onTap: () => _openEditor(context, events[i]),
            onCheckTask: (idx) => state.toggleEventTask(events[i].id, idx),
          ),
        );
        if (state.eventsSort != 'manual') return card;
        return DraggableListCard(
          key: ValueKey(events[i].id),
          itemId: events[i].id,
          dragState: _listDragState,
          onReorder: (f, t) => state.reorderEventById(f, t),
          child: card,
        );
      },
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

// ─── Events Grid ─────────────────────────────────────────
// date sort → статичный grid; manual sort → ReorderableGridView
class _EventsMasonryGrid extends StatelessWidget {
  final List<AppEvent> events;
  final AppState state;
  final void Function(AppEvent) onOpenEditor;
  const _EventsMasonryGrid({required this.events, required this.state, required this.onOpenEditor});

  @override
  Widget build(BuildContext context) {
    final isDark = state.darkMode;

    return LayoutBuilder(builder: (ctx, constraints) {
      const double spacing = 10;
      const double hPad    = 16;
      final colWidth = (constraints.maxWidth - hPad * 2 - spacing) / 2;
      const double itemHeight = 148;

      if (state.eventsSort == 'manual') {
        return ReorderableGridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: colWidth / itemHeight,
          padding: const EdgeInsets.fromLTRB(hPad, 0, hPad, 100),
          onReorder: (oldIdx, newIdx) {
            final fromId = events[oldIdx].id;
            final toId   = events[newIdx].id;
            context.read<AppState>().reorderEventById(fromId, toId);
          },
          dragWidgetBuilder: (index, child) => Material(
            color: Colors.transparent,
            child: Transform.scale(scale: 1.03,
              child: Opacity(opacity: 0.92, child: child)),
          ),
          children: events.map((e) => SelectableCardWrapper(
            key: ValueKey(e.id),
            itemId: e.id,
            child: _EventGridCard(
              event: e,
              showTag: state.eventsFilter == state.s.all,
              isDark: isDark,
              onTap: () => onOpenEditor(e),
            ),
          )).toList(),
        );
      }

      // date sort — обычный двухколоночный grid
      Widget buildCard(AppEvent e) => KeyedSubtree(
        key: ValueKey(e.id),
        child: SelectableCardWrapper(
          itemId: e.id,
          child: Padding(
            padding: const EdgeInsets.only(bottom: spacing),
            child: _EventGridCard(
              event: e,
              showTag: state.eventsFilter == state.s.all,
              isDark: isDark,
              onTap: () => onOpenEditor(e),
            ),
          ),
        ),
      );

      final left  = [for (int i = 0; i < events.length; i += 2) events[i]];
      final right = [for (int i = 1; i < events.length; i += 2) events[i]];

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(hPad, 0, hPad, 100),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: colWidth, child: Column(children: left.map(buildCard).toList())),
            const SizedBox(width: spacing),
            SizedBox(width: colWidth, child: Column(children: right.map(buildCard).toList())),
          ],
        ),
      );
    });
  }
}

// ─── Event Grid Card ─────────────────────────────────────
class _EventGridCard extends StatelessWidget {
  final AppEvent event;
  final bool showTag;
  final bool isDark;
  final VoidCallback onTap;

  const _EventGridCard({
    required this.event,
    required this.showTag,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final bool hasColor = event.colorIndex > 0 && event.colorIndex <= kCardColors.length;
    final Color cardBg = hasColor
            ? kCardColors[event.colorIndex - 1]
            : (isDark ? const Color(0x0DFFFFFF) : const Color(0x40FFFFFF));
    final textColor = hasColor ? AppColors.textColorFor(cardBg) : (isDark ? AppColors.darkText : AppColors.lightText);
    final textSec = hasColor ? AppColors.textSecColorFor(cardBg) : (isDark ? AppColors.darkTextBody : AppColors.lightTextBody);
    final borderColor = hasColor ? Colors.transparent : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder);

    final hasChip = event.reminderDate != null || event.repeat != RepeatInterval.none;

    return GestureDetector(
      onTap: onTap,
      child: SelectionHighlight(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: 148,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Stack(
            children: [
              // Контент — паддинг снизу резервирует место под чип
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12, 12, 12, hasChip ? 38 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (event.title.isNotEmpty)
                        Text(
                          event.title,
                          style: appTitleStyle(state.appFont, size: 13, weight: FontWeight.w600, color: textColor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (event.body.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          event.body,
                          style: contentStyle(state.contentFont, size: 11, color: textSec, height: 1.4),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Чип — всегда прибит к низу
              if (hasChip)
                Positioned(
                  bottom: 10, left: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.terracotta.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          event.reminderDate != null
                              ? Icons.notifications_outlined
                              : Icons.repeat_rounded,
                          size: 11, color: AppColors.terracotta,
                        ),
                        const SizedBox(width: 4),
                        if (event.reminderDate != null)
                          Flexible(
                            child: Text(
                              formatDateTime(event.reminderDate, s: state.s),
                              style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.terracotta, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (event.repeat != RepeatInterval.none && event.reminderDate == null)
                          Text(
                            repeatLabel(event.repeat, event.customDays, s: state.s),
                            style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.terracotta, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Swipable Card ─────────────────────────────────────────

// ─── Event Card ────────────────────────────────────────────
class _EventCard extends StatefulWidget {
  final AppEvent event;
  final bool showTag;
  final int view;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onTap;
  final ValueChanged<int> onCheckTask;
  final bool? isDarkOverride;

  const _EventCard({
    super.key,
    required this.event,
    required this.showTag,
    required this.view,
    this.expanded = false,
    this.onToggleExpand = _noop,
    required this.onTap,
    required this.onCheckTask,
    this.isDarkOverride,
  });

  static void _noop() {}

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  bool _bodyOverflows = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final showTag = widget.showTag;
    final view = widget.view;
    final onTap = widget.onTap;
    final onCheckTask = widget.onCheckTask;

    final state = context.watch<AppState>();
    final isDark = widget.isDarkOverride ?? state.darkMode;
    final bool hasColor = event.colorIndex > 0 && event.colorIndex <= kCardColors.length;
    final Color cardBg = hasColor
        ? kCardColors[event.colorIndex - 1]
        : (isDark ? const Color(0x0DFFFFFF) : const Color(0x40FFFFFF));
    final textColor = hasColor ? AppColors.textColorFor(cardBg) : (isDark ? AppColors.darkText : AppColors.lightText);
    final textSec = hasColor ? AppColors.textSecColorFor(cardBg) : (isDark ? AppColors.darkTextBody : AppColors.lightTextBody);
    final divider = hasColor ? AppColors.dividerColorFor(cardBg) : (isDark ? AppColors.darkDivider : AppColors.lightDivider);
    final catColor = state.folderColor(event.category);
    final maxTasks = view == 2 ? 3 : event.tasks.length;
    final tasks = event.tasks.take(maxTasks).toList();
    final repeatStr = repeatLabel(event.repeat, event.customDays, s: state.s);

    if (view == 3) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 11, horizontal: hasColor ? 8 : 2),
          decoration: BoxDecoration(
            color: hasColor ? cardBg : Colors.transparent,
            borderRadius: hasColor ? BorderRadius.circular(10) : BorderRadius.zero,
            border: hasColor ? null : Border(bottom: BorderSide(color: divider)),
          ),
          child: Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: catColor, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(child: Text(event.title, style: appTitleStyle(state.appFont, size: 13, weight: FontWeight.w600, color: textColor), overflow: TextOverflow.ellipsis)),
              if (event.reminderDate != null)
                Text(formatDate(event.reminderDate!, s: state.s), style: GoogleFonts.dmSans(fontSize: 10, color: textSec)),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: SelectionHighlight(
        borderRadius: BorderRadius.circular(view == 2 ? 16 : 18),
        child: Stack(
          children: [
            Container(
            width: double.infinity,
            padding: EdgeInsets.all(view == 2 ? 12 : 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(view == 2 ? 16 : 18),
              border: Border.all(color: hasColor ? Colors.transparent : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 60),
                  child: Row(
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: catColor, shape: BoxShape.circle)),
                      const SizedBox(width: 7),
                      Expanded(child: Text(event.title, style: appTitleStyle(state.appFont, size: 15, weight: FontWeight.w600, color: textColor))),
                    ],
                  ),
                ),
                if (event.body.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  // Текст: правый отступ оставляет место для уголка
                  Padding(
                    padding: EdgeInsets.only(right: view == 1 && _bodyOverflows ? 22.0 : 0.0),
                    child: view == 1 && widget.expanded
                      ? ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 180),
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: Text(
                              event.body,
                              style: contentStyle(state.contentFont, size: 12, color: textSec, height: 1.4),
                            ),
                          ),
                        )
                      : Text(
                          event.body,
                          style: contentStyle(state.contentFont, size: view == 2 ? 11 : 12, color: textSec, height: 1.4),
                          maxLines: view == 1 ? 3 : 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                  ),
                  // Invisible LayoutBuilder — only measures overflow, renders nothing
                  if (view == 1)
                    LayoutBuilder(builder: (ctx, constraints) {
                      final tp = TextPainter(
                        text: TextSpan(
                          text: event.body,
                          style: contentStyle(state.contentFont, size: 12, height: 1.4),
                        ),
                        maxLines: 3,
                        textDirection: TextDirection.ltr,
                      )..layout(maxWidth: constraints.maxWidth);
                      final overflows = tp.didExceedMaxLines;
                      if (overflows != _bodyOverflows) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _bodyOverflows = overflows);
                        });
                      }
                      return const SizedBox.shrink();
                    }),
                ],
                if (event.reminderDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
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
                              formatDateTime(event.reminderDate, s: state.s),
                              style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.terracotta, fontWeight: FontWeight.w600),
                            ),
                            if (repeatStr.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                '· $repeatStr',
                                style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.terracotta.withValues(alpha: 0.7)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
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
                            Expanded(child: Text(item.text, style: contentStyle(
                              state.contentFont,
                              size: view == 2 ? 11 : 12,
                              color: item.done ? textSec : textColor,
                              height: 1.4,
                            ).copyWith(
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
            ),
            if (showTag)
              Positioned(
                top: 14, right: 14,
                child: CategoryBadge(
                  label: event.category.length > 7
                      ? event.category.substring(0, 7)
                      : event.category,
                ),
              ),
            if (view == 1 && (widget.expanded || _bodyOverflows))
              Positioned(
                bottom: 0, right: 0,
                child: PageFoldCorner(
                  expanded: widget.expanded,
                  onTap: widget.onToggleExpand,
                  isDark: isDark,
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
  final _customDaysFocus = FocusNode();
  bool _tagMenuOpen = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _bodyCtrl = TextEditingController(text: e?.body ?? '');
    _category = e?.category ?? widget.initialCategory;
    _reminderDate = e?.reminderDate;
    _repeat = e?.repeat ?? RepeatInterval.none;
    _customDays = e?.customDays;
    if (_customDays != null) _customDaysCtrl.text = _customDays.toString();
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _customDaysCtrl.dispose();
    _customDaysFocus.dispose();
    super.dispose();
  }

  void _showTagMenu(BuildContext context, AppState state, bool isDark, Color text) {
    _hideTagMenu();
    _overlayEntry = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _hideTagMenu,
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.transparent)),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 32),
              targetAnchor: Alignment.topRight,
              followerAnchor: Alignment.topRight,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 160,
                  constraints: const BoxConstraints(maxHeight: 260),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBg : AppColors.lightBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                        blurRadius: 12, offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shrinkWrap: true,
                    children: ['', ...state.eventFolders].map((tag) {
                      final sel = _category == tag;
                      final tColor = state.folderColor(tag);
                      return GestureDetector(
                        onTap: () {
                          setState(() => _category = tag);
                          _hideTagMenu();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          color: sel ? tColor.withValues(alpha: 0.1) : Colors.transparent,
                          child: Row(
                            children: [
                              Container(
                                width: 7, height: 7,
                                decoration: BoxDecoration(color: tColor, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  tag.isEmpty ? '–' : tag,
                                  style: appTitleStyle(
                                    state.appFont,
                                    size: 12,
                                    weight: sel ? FontWeight.w700 : FontWeight.w400,
                                    color: sel ? tColor : text,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _tagMenuOpen = true);
  }

  void _hideTagMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _tagMenuOpen = false);
  }

  Future<void> _pickDate() async {
    final isDark = context.read<AppState>().darkMode;
    final result = await showDialog<DateTime>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => CustomDateTimePicker(
        initial: _reminderDate ?? DateTime.now().add(const Duration(days: 1)),
        isDark: isDark,
      ),
    );
    if (result != null && mounted) {
      setState(() => _reminderDate = result);
    }
  }

  void _showRepeatPicker() {
    final appState = context.read<AppState>();
    final isDark = appState.darkMode;
    final appFont = appState.appFont;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextBody : AppColors.lightTextBody;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    // FocusNode for inline custom days field — auto-focuses when custom selected
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          const options = [
            RepeatInterval.none,
            RepeatInterval.daily,
            RepeatInterval.weekly,
            RepeatInterval.monthly,
            RepeatInterval.yearly,
            RepeatInterval.custom,
          ];
          final staticLabels = {
            RepeatInterval.none:    appState.s.repeatNone,
            RepeatInterval.daily:   appState.s.repeatDaily,
            RepeatInterval.weekly:  appState.s.repeatWeekly,
            RepeatInterval.monthly: appState.s.repeatMonthly,
            RepeatInterval.yearly:  appState.s.repeatYearly,
          };

          return Dialog(
            backgroundColor: bg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Text(appState.s.repeatLabel,
                        style: appTitleStyle(context.read<AppState>().appFont,
                            size: 16, weight: FontWeight.w600, color: text)),
                  ),
                  Divider(color: divider, height: 1),
                  ...options.map((opt) {
                    final sel = _repeat == opt;
                    final isCustom = opt == RepeatInterval.custom;

                    return GestureDetector(
                      onTap: () {
                        setState(() => _repeat = opt);
                        setDlgState(() {});
                        if (isCustom) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _customDaysFocus.requestFocus();
                            _customDaysCtrl.selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: _customDaysCtrl.text.length,
                            );
                          });
                        } else {
                          Navigator.pop(ctx);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                        color: Colors.transparent,
                        child: Row(children: [
                          // Label / inline input for custom
                          if (!isCustom)
                            Expanded(child: Text(staticLabels[opt]!,
                              style: appTitleStyle(
                                appFont,
                                size: 14,
                                weight: sel ? FontWeight.w600 : FontWeight.w400,
                                color: sel ? AppColors.terracotta : text,
                              )))
                          else
                            Expanded(child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(appState.s.repeatEvery, style: appTitleStyle(
                                  appFont,
                                  size: 14,
                                  weight: sel ? FontWeight.w600 : FontWeight.w400,
                                  color: sel ? AppColors.terracotta : text,
                                )),
                                // Inline number field
                                IntrinsicWidth(
                                  child: TextField(
                                    controller: _customDaysCtrl,
                                    focusNode: _customDaysFocus,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: appTitleStyle(
                                      appFont,
                                      size: 14,
                                      weight: FontWeight.w700,
                                      color: AppColors.terracotta,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: appState.s.repeatDaysHint,
                                      hintStyle: appTitleStyle(
                                        appFont,
                                        size: 14,
                                        color: textSec,
                                      ),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 2),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: AppColors.terracotta.withValues(alpha: 0.5),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: AppColors.terracotta,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() => _repeat = RepeatInterval.custom);
                                      setDlgState(() {});
                                    },
                                    onChanged: (v) {
                                      setState(() =>
                                          _customDays = int.tryParse(v));
                                      setDlgState(() {});
                                    },
                                    onSubmitted: (_) => Navigator.pop(ctx),
                                  ),
                                ),
                                Text(appState.s.repeatDays, style: appTitleStyle(
                                  appFont,
                                  size: 14,
                                  weight: sel ? FontWeight.w600 : FontWeight.w400,
                                  color: sel ? AppColors.terracotta : text,
                                )),
                              ],
                            )),
                          // Checkmark — for custom show only when number entered
                          if (sel && (!isCustom || (_customDaysCtrl.text.isNotEmpty && int.tryParse(_customDaysCtrl.text) != null)))
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(Icons.check_rounded,
                                  size: 16, color: AppColors.terracotta),
                            ),
                        ]),
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) {
      // Sync _customDays from controller on close
      setState(() => _customDays = int.tryParse(_customDaysCtrl.text));
    });
  }

  String get _repeatLabel {
    final s = context.read<AppState>().s;
    switch (_repeat) {
      case RepeatInterval.none: return s.repeatNone;
      case RepeatInterval.daily: return s.repeatDaily;
      case RepeatInterval.weekly: return s.repeatWeekly;
      case RepeatInterval.monthly: return s.repeatMonthly;
      case RepeatInterval.yearly: return s.repeatYearly;
      case RepeatInterval.custom:
        final d = _customDays ?? int.tryParse(_customDaysCtrl.text);
        return d != null ? s.repeatCustom(d) : '${s.repeatEvery}N${s.repeatDays}';
    }
  }

  void _save() {
    final state = context.read<AppState>();
    final customD = _repeat == RepeatInterval.custom ? int.tryParse(_customDaysCtrl.text) : null;
    if (widget.event != null) {
      widget.event!
        ..title = _titleCtrl.text.trim().isEmpty ? state.s.defaultEvent : _titleCtrl.text.trim()
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
        title: _titleCtrl.text.trim().isEmpty ? state.s.defaultEvent : _titleCtrl.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.darkMode;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextBody : AppColors.lightTextBody;
    final textHint = isDark ? const Color(0x4DE6AF78) : const Color(0x6E785028);
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return GestureDetector(
      onTap: () { if (_tagMenuOpen) _hideTagMenu(); },
      child: Dialog(
      backgroundColor: bg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Шапка: название + dropdown папки ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                // Название
                Padding(
                  padding: const EdgeInsets.only(right: 120),
                  child: TextField(
                    controller: _titleCtrl,
                    autofocus: widget.event == null,
                    style: appTitleStyle(state.appFont, size: 20, weight: FontWeight.w600, color: text),
                    decoration: InputDecoration(
                      filled: false, border: InputBorder.none,
                      hintText: state.s.eventTitle,
                      hintStyle: appTitleStyle(state.appFont, size: 20, weight: FontWeight.w600, color: textHint),
                      contentPadding: EdgeInsets.zero, isDense: true,
                    ),
                  ),
                ),
                // Кнопки: dropdown папки + закрыть
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CompositedTransformTarget(
                      link: _layerLink,
                      child: GestureDetector(
                        onTap: () {
                          if (_tagMenuOpen) {
                            _hideTagMenu();
                          } else {
                            _showTagMenu(context, state, isDark, text);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: state.folderColor(_category).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _category.isEmpty ? '–' : _category,
                                style: GoogleFonts.dmSans(
                                  fontSize: 11, fontWeight: FontWeight.w700,
                                  color: state.folderColor(_category),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _tagMenuOpen
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 14, color: state.folderColor(_category),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        if (_tagMenuOpen) _hideTagMenu();
                        Navigator.pop(context);
                      },
                      child: Icon(Icons.close_rounded, color: textSec, size: 20),
                    ),
                  ],
                ),
              ],
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
              style: contentStyle(state.contentFont, size: 13, color: text, height: 1.4),
              maxLines: 10,
              minLines: 5,
              decoration: InputDecoration(
                filled: false, border: InputBorder.none,
                hintText: state.s.eventBody,
                hintStyle: contentStyle(state.contentFont, size: 13, color: textHint, height: 1.4),
                contentPadding: EdgeInsets.zero, isDense: true,
              ),
            ),
          ),
          Divider(color: divider, height: 1),
          // ── Футер: Напоминание | Повтор | Готово ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Row(
              children: [
                // Напоминание
                GestureDetector(
                  onTap: _pickDate,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 18,
                        color: _reminderDate != null ? AppColors.terracotta : textSec,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _reminderDate != null ? formatDateTime(_reminderDate, s: state.s) : state.s.reminder,
                        style: appTitleStyle(state.appFont, size: 12,
                          color: _reminderDate != null ? AppColors.terracotta : textSec,
                        ),
                      ),
                      if (_reminderDate != null) ...[
                        const SizedBox(width: 2),
                        GestureDetector(
                          onTap: () => setState(() => _reminderDate = null),
                          child: Icon(Icons.close_rounded, size: 13, color: textSec),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Повтор
                GestureDetector(
                  onTap: _showRepeatPicker,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.repeat_rounded,
                        size: 18,
                        color: _repeat != RepeatInterval.none ? AppColors.terracotta : textSec,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _repeat != RepeatInterval.none ? _repeatLabel : state.s.repeat,
                        style: appTitleStyle(state.appFont, size: 12,
                          color: _repeat != RepeatInterval.none ? AppColors.terracotta : textSec,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Готово
                GestureDetector(
                  onTap: _save,
                  child: Text(
                    state.s.done,
                    style: appTitleStyle(state.appFont, size: 14,
                      weight: FontWeight.w600, color: AppColors.terracotta,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}

