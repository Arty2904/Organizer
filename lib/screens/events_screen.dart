import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../theme/font_helper.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/selection_state.dart';

const List<Color> kEventColors = [
  Color(0xFFE53935), Color(0xFFE91E63), Color(0xFF9C27B0),
  Color(0xFF673AB7), Color(0xFF3F51B5), Color(0xFF2196F3),
  Color(0xFF03A9F4), Color(0xFF00BCD4), Color(0xFF009688),
  Color(0xFF4CAF50), Color(0xFF8BC34A), Color(0xFFCDDC39),
  Color(0xFFFFEB3B), Color(0xFFFFC107), Color(0xFFFF9800),
  Color(0xFFFF5722), Color(0xFFD07840), Color(0xFF795548),
  Color(0xFF607D8B), Color(0xFF9E9E9E), Color(0xFF37474F),
];


class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _query = '';
  final Set<String> _expandedIds = {};

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
        Text('Нет событий', style: appTitleStyle(context.watch<AppState>().appFont, size: 16, weight: FontWeight.w600, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
      ],
    ),
  );

  Widget _listView(BuildContext context, List<AppEvent> events, AppState state) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => _toggleAll(events),
                child: Row(
                  children: [
                    Icon(
                      _allExpanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
                      size: 14, color: AppColors.terracotta,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _allExpanded ? 'Свернуть все' : 'Развернуть все',
                      style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.terracotta),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: state.eventsSort == 'manual'
            ? ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                onReorder: (o, n) => state.reorderEvent(o, n),
                proxyDecorator: (child, index, animation) => Material(
                  color: Colors.transparent,
                  elevation: 0,
                  child: child,
                ),
                itemCount: events.length,
                itemBuilder: (ctx, i) => SelectableCardWrapper(
                  key: ValueKey(events[i].id),
                  itemId: events[i].id,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _EventCard(
                      event: events[i],
                      showTag: state.eventsFilter == 'Все',
                      view: 1,
                      expanded: _expandedIds.contains(events[i].id),
                      onToggleExpand: () => _toggleExpand(events[i].id),
                      isDarkOverride: state.darkMode,
                      onTap: () => _openEditor(context, events[i]),
                      onCheckTask: (idx) => state.toggleEventTask(events[i].id, idx),
                    ),
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: events.length,
                itemBuilder: (ctx, i) => SelectableCardWrapper(
                  key: ValueKey(events[i].id),
                  itemId: events[i].id,
                  child: _SwipableCard(
                    key: ValueKey('sw-ev-${events[i].id}'),
                    itemKey: ValueKey('del-event-${events[i].id}'),
                    padding: const EdgeInsets.only(bottom: 10),
                    onDelete: () => state.deleteEvent(events[i].id),
                    child: _EventCard(
                      event: events[i],
                      showTag: state.eventsFilter == 'Все',
                      view: 1,
                      expanded: _expandedIds.contains(events[i].id),
                      onToggleExpand: () => _toggleExpand(events[i].id),
                      isDarkOverride: state.darkMode,
                      onTap: () => _openEditor(context, events[i]),
                      onCheckTask: (idx) => state.toggleEventTask(events[i].id, idx),
                    ),
                  ),
                ),
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
    if (state.eventsSort == 'manual') {
      return ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        onReorder: (o, n) => state.reorderEvent(o, n),
        proxyDecorator: (child, index, animation) => Material(
          color: Colors.transparent,
          elevation: 0,
          child: child,
        ),
        itemCount: events.length,
        itemBuilder: (ctx, i) => SelectableCardWrapper(
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
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: events.length,
      itemBuilder: (ctx, i) => SelectableCardWrapper(
        key: ValueKey(events[i].id),
        itemId: events[i].id,
        child: _EventCard(
          event: events[i],
          showTag: false,
          view: 3,
          isDarkOverride: state.darkMode,
          onTap: () => _openEditor(context, events[i]),
          onCheckTask: (idx) => state.toggleEventTask(events[i].id, idx),
        ),
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


// ─── Events Masonry Grid with drag support ────────────────
class _EventsMasonryGrid extends StatefulWidget {
  final List<AppEvent> events;
  final AppState state;
  final void Function(AppEvent) onOpenEditor;
  const _EventsMasonryGrid({required this.events, required this.state, required this.onOpenEditor});

  @override
  State<_EventsMasonryGrid> createState() => _EventsMasonryGridState();
}

class _EventsMasonryGridState extends State<_EventsMasonryGrid> {
  final ValueNotifier<String?> _dragState = ValueNotifier(null);

  @override
  void dispose() {
    _dragState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final events = widget.events;
    final canDrag = state.eventsSort == 'manual';
    final isDark = state.darkMode;

    return LayoutBuilder(builder: (ctx, constraints) {
      final colWidth = (constraints.maxWidth - 16 - 16 - 10) / 2;

      Widget buildCard(AppEvent e) {
        final card = SelectableCardWrapper(
          itemId: e.id,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _EventGridCard(
              event: e,
              showTag: state.eventsFilter == 'Все',
              isDark: isDark,
              onTap: () => widget.onOpenEditor(e),
            ),
          ),
        );
        if (!canDrag) return KeyedSubtree(key: ValueKey(e.id), child: card);
        final feedbackCard = _EventGridCard(
          event: e,
          showTag: state.eventsFilter == 'Все',
          isDark: isDark,
          asFeedback: true,
          onTap: () {},
        );
        return _DraggableMasonryCard(
          key: ValueKey(e.id),
          itemId: e.id,
          dragState: _dragState,
          feedbackWidth: colWidth,
          onReorder: (fromId, toId) =>
              context.read<AppState>().reorderEventById(fromId, toId),
          feedbackChild: feedbackCard,
          child: card,
        );
      }

      final left  = [for (int i = 0; i < events.length; i += 2) events[i]];
      final right = [for (int i = 1; i < events.length; i += 2) events[i]];

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: colWidth,
              child: Column(children: left.map(buildCard).toList()),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: colWidth,
              child: Column(children: right.map(buildCard).toList()),
            ),
          ],
        ),
      );
    });
  }
}

// ─── Event Grid Card (StatelessWidget, no context.watch — safe in drag feedback) ──
class _EventGridCard extends StatelessWidget {
  final AppEvent event;
  final bool showTag;
  final bool isDark;
  final VoidCallback onTap;
  final bool asFeedback;

  const _EventGridCard({
    required this.event,
    required this.showTag,
    required this.isDark,
    required this.onTap,
    this.asFeedback = false,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('🃏 _EventGridCard build: isDark=$isDark asFeedback=$asFeedback cardBg=${asFeedback ? "OPAQUE" : "TRANSPARENT"}');
    final bool hasColor = !asFeedback && event.colorIndex > 0 && event.colorIndex <= kEventColors.length;
    final Color cardBg = asFeedback
        ? (isDark ? AppColors.darkBg : AppColors.lightBg)
        : hasColor
            ? kEventColors[event.colorIndex - 1]
            : (isDark ? const Color(0x0DFFFFFF) : const Color(0x40FFFFFF));
    final textColor = hasColor ? const Color(0xFF2A1F14) : (isDark ? AppColors.darkText : AppColors.lightText);
    final textSec = hasColor ? AppColors.lightTextDate : (isDark ? AppColors.darkTextBody : AppColors.lightTextBody);
    final borderColor = hasColor ? Colors.transparent : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder);

    return GestureDetector(
      onTap: onTap,
      child: SelectionHighlight(
        borderRadius: BorderRadius.circular(16),
        child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (event.title.isNotEmpty)
              Text(
                event.title,
                style: appTitleStyle(context.watch<AppState>().appFont, size: 13, weight: FontWeight.w600, color: textColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (event.body.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                event.body,
                style: GoogleFonts.dmSans(fontSize: 11, color: textSec, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
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
                  children: [
                    Icon(Icons.notifications_outlined, size: 11, color: AppColors.terracotta),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        formatDateTime(event.reminderDate),
                        style: GoogleFonts.dmSans(
                          fontSize: 10, color: AppColors.terracotta, fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }
}


// ─── Draggable Masonry Card (shared) ─────────────────────
class _DraggableMasonryCard extends StatefulWidget {
  final String itemId;
  final void Function(String fromId, String toId) onReorder;
  final ValueNotifier<String?> dragState;
  final Widget child;
  final Widget feedbackChild;
  final double feedbackWidth;

  const _DraggableMasonryCard({
    super.key,
    required this.itemId,
    required this.onReorder,
    required this.dragState,
    required this.child,
    required this.feedbackChild,
    required this.feedbackWidth,
  });

  @override
  State<_DraggableMasonryCard> createState() => _DraggableMasonryCardState();
}

class _DraggableMasonryCardState extends State<_DraggableMasonryCard> {
  static String? _draggingIdFrom(String? v) {
    if (v == null) return null;
    return v.split('->')[0];
  }

  static String? _targetIdFrom(String? v) {
    if (v == null || !v.contains('->')) return null;
    return v.split('->')[1];
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: widget.dragState,
      builder: (ctx, dragVal, _) {
        final isMe = _draggingIdFrom(dragVal) == widget.itemId;
        final isTarget = _targetIdFrom(dragVal) == widget.itemId;

        return DragTarget<String>(
          onWillAcceptWithDetails: (details) {
            if (details.data == widget.itemId) return false;
            widget.dragState.value = '${details.data}->${widget.itemId}';
            return true;
          },
          onLeave: (fromId) {
            if (fromId != null) widget.dragState.value = fromId;
          },
          onAcceptWithDetails: (details) {
            widget.dragState.value = null;
            if (details.data != widget.itemId) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.onReorder(details.data, widget.itemId);
              });
            }
          },
          builder: (ctx, candidateData, rejectedData) {
            return LongPressDraggable<String>(
              data: widget.itemId,
              delay: const Duration(milliseconds: 350),
              onDragStarted: () => widget.dragState.value = widget.itemId,
              onDragEnd: (_) => widget.dragState.value = null,
              onDraggableCanceled: (_, __) => widget.dragState.value = null,
              feedback: Builder(builder: (ctx) {
                debugPrint('🚀 FEEDBACK built! ctx.widget=${ctx.widget.runtimeType}');
                return SizedBox(
                  width: widget.feedbackWidth,
                  child: Material(
                    color: Colors.transparent,
                    child: Opacity(opacity: 0.92, child: widget.feedbackChild),
                  ),
                );
              }),
              childWhenDragging: _SizedPlaceholder(visible: false, child: widget.child),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: isMe ? 0.0 : 1.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: isTarget
                          ? _SizedPlaceholder(visible: true, child: widget.child)
                          : const SizedBox.shrink(),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: isTarget
                          ? BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppColors.terracotta.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            )
                          : const BoxDecoration(),
                      child: widget.child,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SizedPlaceholder extends StatefulWidget {
  final Widget child;
  final bool visible;
  const _SizedPlaceholder({required this.child, required this.visible});

  @override
  State<_SizedPlaceholder> createState() => _SizedPlaceholderState();
}

class _SizedPlaceholderState extends State<_SizedPlaceholder> {
  final _key = GlobalKey();
  Size? _size;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final ctx = _key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box != null && mounted && _size != box.size) {
      setState(() => _size = box.size);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(opacity: 0, child: KeyedSubtree(key: _key, child: widget.child)),
        if (_size != null)
          SizedBox(
            width: _size!.width,
            height: _size!.height,
            child: widget.visible
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.terracotta.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        color: AppColors.terracotta.withValues(alpha: 0.05),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
      ],
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
                    Text('Удалить?', style: appTitleStyle(context.watch<AppState>().appFont, size: 18, weight: FontWeight.w600, color: text)),
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
    final bool hasColor = event.colorIndex > 0 && event.colorIndex <= kEventColors.length;
    final Color cardBg = hasColor
        ? kEventColors[event.colorIndex - 1]
        : (isDark ? const Color(0x0DFFFFFF) : const Color(0x40FFFFFF));
    final textColor = hasColor ? const Color(0xFF2A1F14) : (isDark ? AppColors.darkText : AppColors.lightText);
    final textSec = hasColor ? AppColors.lightTextDate : (isDark ? AppColors.darkTextBody : AppColors.lightTextBody);
    final divider = hasColor ? const Color(0x33785028) : (isDark ? AppColors.darkDivider : AppColors.lightDivider);
    final catColor = state.folderColor(event.category);
    final maxTasks = view == 2 ? 3 : event.tasks.length;
    final tasks = event.tasks.take(maxTasks).toList();
    final repeatStr = repeatLabel(event.repeat, event.customDays);

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
                Text(formatDate(event.reminderDate!), style: GoogleFonts.dmSans(fontSize: 10, color: textSec)),
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
                          maxLines: view == 1 ? 3 : 2,
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
                              formatDateTime(event.reminderDate),
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
  bool _tagMenuOpen = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

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
    _overlayEntry?.remove();
    _overlayEntry = null;
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _customDaysCtrl.dispose();
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
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
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
                child: Text('Повторять', style: appTitleStyle(context.watch<AppState>().appFont, size: 16, weight: FontWeight.w600, color: text)),
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
              Text('Через сколько дней?', style: appTitleStyle(context.watch<AppState>().appFont, size: 16, weight: FontWeight.w600, color: text)),
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

    return GestureDetector(
      onTap: () { if (_tagMenuOpen) _hideTagMenu(); },
      child: Dialog(
      backgroundColor: bg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
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
                      hintText: 'Название события',
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
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                filled: false, border: InputBorder.none,
                hintText: 'Описание...',
                hintStyle: contentStyle(state.contentFont, size: 13, color: textHint, height: 1.4),
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
    ));
  }
}

