import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../theme/font_helper.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/selection_state.dart';

const List<Color> kTodoColors = [
  Color(0xFFE53935), Color(0xFFE91E63), Color(0xFF9C27B0),
  Color(0xFF673AB7), Color(0xFF3F51B5), Color(0xFF2196F3),
  Color(0xFF03A9F4), Color(0xFF00BCD4), Color(0xFF009688),
  Color(0xFF4CAF50), Color(0xFF8BC34A), Color(0xFFCDDC39),
  Color(0xFFFFEB3B), Color(0xFFFFC107), Color(0xFFFF9800),
  Color(0xFFFF5722), Color(0xFFD07840), Color(0xFF795548),
  Color(0xFF607D8B), Color(0xFF9E9E9E), Color(0xFF37474F),
];


class TodosScreen extends StatefulWidget {
  const TodosScreen({super.key});

  @override
  State<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
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
    final todos = state.filteredTodos(_query);
    return todos.isNotEmpty && todos.every((t) => _expandedIds.contains(t.id));
  }

  void _toggleAll(List<TodoGroup> todos) {
    setState(() {
      if (_allExpanded) {
        _expandedIds.clear();
      } else {
        for (final t in todos) {
          _expandedIds.add(t.id);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.darkMode;
    final todos = state.filteredTodos(_query);
    final v = state.todosView;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSearchBar(onChanged: (q) => setState(() => _query = q), hint: 'Поиск...'),
              const SizedBox(height: 10),
              CategoryFilterRow(
                categories: state.todoCategories,
                selected: state.todosFilter,
                onSelect: (c) { state.todosFilter = c; state.refresh(); },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        Expanded(
          child: todos.isEmpty
              ? _emptyState(isDark)
              : v == 1
                  ? _listView(context, todos, state, isDark)
                  : v == 2
                      ? _gridView(context, todos, state, isDark)
                      : _compactView(context, todos, state, isDark),
        ),
      ],
    );
  }

  Widget _emptyState(bool isDark) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.checklist_rounded, size: 48, color: AppColors.terracotta.withValues(alpha: 0.3)),
        const SizedBox(height: 12),
        Text('Нет дел', style: appTitleStyle(context.watch<AppState>().appFont, size: 16, weight: FontWeight.w600, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
      ],
    ),
  );

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  Widget _listView(BuildContext context, List<TodoGroup> todos, AppState state, bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => _toggleAll(todos),
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
          child: state.todosSort == 'manual'
            ? ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: todos.length,
                onReorder: (o, n) => state.reorderTodo(o, n),
                proxyDecorator: (child, _, __) => Material(color: Colors.transparent, child: child),
                itemBuilder: (ctx, i) => SelectableCardWrapper(
                  key: ValueKey(todos[i].id),
                  itemId: todos[i].id,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TodoCard(
                      group: todos[i],
                      showTag: state.todosFilter == 'Все',
                      view: 1,
                      expanded: _expandedIds.contains(todos[i].id),
                      onToggleExpand: () => _toggleExpand(todos[i].id),
                      onTap: () => _openEditor(context, todos[i]),
                      onCheckItem: (idx) => state.toggleTodoItem(todos[i].id, idx),
                    ),
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: todos.length,
                itemBuilder: (ctx, i) => SelectableCardWrapper(
                  key: ValueKey(todos[i].id),
                  itemId: todos[i].id,
                  child: _SwipableCard(
                    key: ValueKey('sw-td-${todos[i].id}'),
                    itemKey: ValueKey('del-todo-${todos[i].id}'),
                    padding: const EdgeInsets.only(bottom: 10),
                    onDelete: () => state.deleteTodo(todos[i].id),
                    child: _TodoCard(
                      group: todos[i],
                      showTag: state.todosFilter == 'Все',
                      view: 1,
                      expanded: _expandedIds.contains(todos[i].id),
                      onToggleExpand: () => _toggleExpand(todos[i].id),
                      onTap: () => _openEditor(context, todos[i]),
                      onCheckItem: (idx) => state.toggleTodoItem(todos[i].id, idx),
                    ),
                  ),
                ),
              ),
        ),
      ],
    );
  }

  Widget _gridView(BuildContext context, List<TodoGroup> todos, AppState state, bool isDark) {
    return _TodosMasonryGrid(
      onOpenEditor: (g) => _openEditor(context, g),
    );
  }

  Widget _compactView(BuildContext context, List<TodoGroup> todos, AppState state, bool isDark) {
    final textSec = isDark ? AppColors.darkTextBody : AppColors.lightTextBody;
    return Column(
      children: [
        // Кнопки свернуть/развернуть все
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => _toggleAll(todos),
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
          child: state.todosSort == 'manual'
            ? ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: todos.length,
                onReorder: (o, n) => state.reorderTodo(o, n),
                proxyDecorator: (child, _, __) => Material(color: Colors.transparent, child: child),
                itemBuilder: (ctx, i) => SelectableCardWrapper(
                  key: ValueKey(todos[i].id),
                  itemId: todos[i].id,
                  child: _TodoCard(
                    key: ValueKey('td-c-${todos[i].id}'),
                    group: todos[i],
                    showTag: false,
                    view: 3,
                    expanded: _expandedIds.contains(todos[i].id),
                    onToggleExpand: () => setState(() {
                      if (_expandedIds.contains(todos[i].id)) {
                        _expandedIds.remove(todos[i].id);
                      } else {
                        _expandedIds.add(todos[i].id);
                      }
                    }),
                    onTap: () => _openEditor(context, todos[i]),
                    onCheckItem: (idx) => state.toggleTodoItem(todos[i].id, idx),
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: todos.length,
                itemBuilder: (ctx, i) => SelectableCardWrapper(
                  key: ValueKey(todos[i].id),
                  itemId: todos[i].id,
                  child: _TodoCard(
                    group: todos[i],
                    showTag: false,
                    view: 3,
                    expanded: _expandedIds.contains(todos[i].id),
                    onToggleExpand: () => setState(() {
                      if (_expandedIds.contains(todos[i].id)) {
                        _expandedIds.remove(todos[i].id);
                      } else {
                        _expandedIds.add(todos[i].id);
                      }
                    }),
                    onTap: () => _openEditor(context, todos[i]),
                    onCheckItem: (idx) => state.toggleTodoItem(todos[i].id, idx),
                  ),
                ),
            ),
          ),
      ],
    );
  }

  void _openEditor(BuildContext context, [TodoGroup? group]) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => TodoEditorDialog(group: group),
    );
  }
}

// ─── Todos Masonry Grid ───────────────────────────────────
class _TodosMasonryGrid extends StatefulWidget {
  final void Function(TodoGroup) onOpenEditor;

  const _TodosMasonryGrid({
    required this.onOpenEditor,
  });

  @override
  State<_TodosMasonryGrid> createState() => _TodosMasonryGridState();
}

class _TodosMasonryGridState extends State<_TodosMasonryGrid> {
  final ValueNotifier<String?> _dragState = ValueNotifier(null);

  @override
  void dispose() {
    _dragState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // watch только нужные поля — dragState живёт отдельно и не сбрасывается
    final state = context.watch<AppState>();
    final todos = state.filteredTodos('');
    final showTag = state.todosFilter == 'Все';
    final canDrag = state.todosSort == 'manual';

    return LayoutBuilder(
      builder: (ctx, constraints) {
        // subtract horizontal padding (16+16) so the two columns + gap fit exactly
        final colW = (constraints.maxWidth - 32 - 10) / 2;

        Widget buildCard(TodoGroup g) {
          final card = SelectableCardWrapper(
            itemId: g.id,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TodoCard(
                group: g, showTag: showTag, view: 2,
                expanded: false, onToggleExpand: () {},
                onTap: () => widget.onOpenEditor(g),
                onCheckItem: (idx) => context.read<AppState>().toggleTodoItem(g.id, idx),
              ),
            ),
          );
          if (!canDrag) return KeyedSubtree(key: ValueKey(g.id), child: card);
          return _DraggableMasonryCard<TodoGroup>(
            key: ValueKey(g.id),
            itemId: g.id,
            dragState: _dragState,
            feedbackWidth: colW,
            onReorder: (fromId, toId) =>
                context.read<AppState>().reorderTodoById(fromId, toId),
            child: card,
          );
        }

        final left  = [for (int i = 0; i < todos.length; i += 2) todos[i]];
        final right = [for (int i = 1; i < todos.length; i += 2) todos[i]];

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: colW,
                child: Column(children: left.map(buildCard).toList()),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: colW,
                child: Column(children: right.map(buildCard).toList()),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Draggable Masonry Card ───────────────────────────────
class _DraggableMasonryCard<T> extends StatefulWidget {
  final String itemId;
  final void Function(String fromId, String toId) onReorder;
  final ValueNotifier<String?> dragState;
  final Widget child;
  final double feedbackWidth;

  const _DraggableMasonryCard({
    super.key,
    required this.itemId,
    required this.onReorder,
    required this.dragState,
    required this.child,
    required this.feedbackWidth,
  });

  @override
  State<_DraggableMasonryCard<T>> createState() => _DraggableMasonryCardState<T>();
}

class _DraggableMasonryCardState<T> extends State<_DraggableMasonryCard<T>> {
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
              feedback: SizedBox(
                width: widget.feedbackWidth,
                child: Material(
                  color: Colors.transparent,
                  child: Opacity(opacity: 0.88, child: widget.child),
                ),
              ),
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

// ─── Todo Card ─────────────────────────────────────────────
class _TodoCard extends StatefulWidget {
  final TodoGroup group;
  final bool showTag;
  final int view; // 1=list, 2=grid, 3=compact
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onTap;
  final ValueChanged<int> onCheckItem;

  const _TodoCard({
    super.key,
    required this.group,
    required this.showTag,
    required this.view,
    required this.expanded,
    required this.onToggleExpand,
    required this.onTap,
    required this.onCheckItem,
  });

  @override
  State<_TodoCard> createState() => _TodoCardState();
}

class _TodoCardState extends State<_TodoCard> {
  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final showTag = widget.showTag;
    final view = widget.view;
    final expanded = widget.expanded;
    final onToggleExpand = widget.onToggleExpand;
    final onTap = widget.onTap;
    final onCheckItem = widget.onCheckItem;

    final state = context.watch<AppState>();
    final isDark = state.darkMode;
    final bool hasColor = group.colorIndex > 0 && group.colorIndex <= kTodoColors.length;
    final Color cardBg = hasColor
        ? kTodoColors[group.colorIndex - 1]
        : (isDark ? const Color(0x0DFFFFFF) : const Color(0x40FFFFFF));
    final textColor = hasColor ? const Color(0xFF2A1F14) : (isDark ? AppColors.darkText : AppColors.lightText);
    final textSec = hasColor ? AppColors.lightTextDate : (isDark ? AppColors.darkTextBody : AppColors.lightTextBody);
    final divider = hasColor ? const Color(0x33785028) : (isDark ? AppColors.darkDivider : AppColors.lightDivider);
    final catColor = state.folderColor(group.category);

    // ── Compact view (view 3) — expandable rows ──
    if (view == 3) {
      final items = expanded ? group.items : [];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: hasColor ? cardBg : Colors.transparent,
              borderRadius: hasColor ? BorderRadius.circular(10) : BorderRadius.zero,
              border: hasColor ? null : Border(bottom: BorderSide(
                color: expanded ? Colors.transparent : divider,
              )),
            ),
            child: Row(
              children: [
                // Тап на название — открыть редактор
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 6, height: 6, decoration: BoxDecoration(color: catColor, shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ),
                ),
                // Expanded текст — тоже открывает редактор
                Expanded(
                  child: GestureDetector(
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Text(group.name, style: appTitleStyle(state.appFont, size: 13, weight: FontWeight.w600, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
                // Счётчик + шеврон — раскрыть/свернуть
                GestureDetector(
                  onTap: onToggleExpand,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
                    child: Row(
                      children: [
                        Text(
                          '${group.doneCount}/${group.total}',
                          style: GoogleFonts.dmSans(fontSize: 10, color: textSec),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          size: 15, color: textSec,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (expanded) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.fromLTRB(16, 6, 8, 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: divider)),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (group.total > 0) ...[
                        _ProgressBar(done: group.doneCount, total: group.total),
                        const SizedBox(height: 8),
                      ],
                      ...group.items.asMap().entries.map((e) {
                        final idx = e.key;
                        final item = e.value;
                        return GestureDetector(
                          onTap: () => onCheckItem(idx),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 15, height: 15,
                                  decoration: BoxDecoration(
                                    color: item.done ? AppColors.terracotta : Colors.transparent,
                                    border: Border.all(
                                      color: item.done ? AppColors.terracotta : divider,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: item.done
                                      ? const Icon(Icons.check_rounded, size: 9, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.text,
                                    style: contentStyle(state.contentFont, size: 12, color: item.done ? textSec : textColor, height: 1.4).copyWith(decoration: item.done ? TextDecoration.lineThrough : null, decorationColor: textSec),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }

    // ── List & Grid view ──
    // view 1: до 3 задач, раскрывается; view 2: до 5 задач, без кнопки
    final maxVisible = view == 2 ? 5 : (!expanded ? 3 : group.items.length);
    final items = group.items.take(maxVisible).toList();

    // Режим «только задача»: одна задача — без названия, бара и тега (все виды)
    final singleTask = group.items.length == 1;
    final singleTaskNoTitle = singleTask;

    if (singleTaskNoTitle) {
      final item = group.items.first;
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasColor ? Colors.transparent : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => onCheckItem(0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    color: item.done ? AppColors.terracotta : Colors.transparent,
                    border: Border.all(
                      color: item.done ? AppColors.terracotta : divider,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: item.done
                      ? const Icon(Icons.check_rounded, size: 10, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.text,
                  style: contentStyle(state.contentFont, size: 11, color: item.done ? textSec : textColor, height: 1.4).copyWith(decoration: item.done ? TextDecoration.lineThrough : null, decorationColor: textSec),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
            padding: EdgeInsets.all(view == 2 ? 12 : 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(view == 2 ? 16 : 18),
              border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Название — скрываем если одна задача (любой вид)
                if (group.name.trim().isNotEmpty && group.items.length != 1)
                  Padding(
                    padding: EdgeInsets.only(right: showTag ? 60 : 0),
                    child: Row(
                      children: [
                        Container(width: 6, height: 6, decoration: BoxDecoration(color: catColor, shape: BoxShape.circle)),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            group.name,
                            style: appTitleStyle(state.appFont, size: 15, weight: FontWeight.w600, color: textColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Прогресс-бар — скрываем если одна задача (любой вид)
                if (group.name.trim().isNotEmpty && group.total > 0 && group.items.length != 1) ...[
                  const SizedBox(height: 6),
                  _ProgressBar(done: group.doneCount, total: group.total),
                ],
                if (items.isNotEmpty) ...[
                  if (group.name.trim().isNotEmpty && group.items.length != 1) const SizedBox(height: 8),
                  Builder(builder: (ctx) {
                    final itemWidgets = items.asMap().entries.map((e) {
                      final idx = e.key;
                      final item = e.value;
                      return GestureDetector(
                        onTap: () { onCheckItem(idx); },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 16, height: 16,
                                decoration: BoxDecoration(
                                  color: item.done ? AppColors.terracotta : Colors.transparent,
                                  border: Border.all(
                                    color: item.done ? AppColors.terracotta : divider,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: item.done
                                    ? const Icon(Icons.check_rounded, size: 10, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.text,
                                  style: contentStyle(state.contentFont, size: view == 2 ? 11 : 12, color: item.done ? textSec : textColor, height: 1.4).copyWith(decoration: item.done ? TextDecoration.lineThrough : null, decorationColor: textSec),
                                  maxLines: (view == 1 && expanded) ? 2 : 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList();

                    if (view == 1 && expanded && group.items.length > 3) {
                      return ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: itemWidgets,
                          ),
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: itemWidgets,
                    );
                  }),
                  if (view == 1 && group.items.length > 3)
                    const SizedBox(height: 12),
                ],
              ],
            ),
            ),
            if (showTag && group.name.trim().isNotEmpty && group.items.length != 1)
              Positioned(
                top: 14, right: 14,
                child: CategoryBadge(
                  label: group.category.length > 7
                      ? group.category.substring(0, 7)
                      : group.category,
                ),
              ),
            if (view == 1 && group.items.length > 3)
              Positioned(
                bottom: 0, right: 0,
                child: PageFoldCorner(
                  expanded: expanded,
                  onTap: onToggleExpand,
                  isDark: isDark,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int done;
  final int total;
  const _ProgressBar({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? done / total : 0.0;
    final isDark = context.watch<AppState>().darkMode;
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: pct,
        minHeight: 3,
        backgroundColor: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        color: AppColors.terracotta,
      ),
    );
  }
}

// ─── Category Chip ────────────────────────────────────────
class _CategoryChip extends StatelessWidget {
  final String category;
  final Color color;
  final bool tagMenuOpen;
  const _CategoryChip({required this.category, required this.color, required this.tagMenuOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            category.isEmpty ? '–' : category,
            style: GoogleFonts.dmSans(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            tagMenuOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
            size: 14, color: color,
          ),
        ],
      ),
    );
  }
}

// ─── Todo Editor Dialog (center) ──────────────────────────
class TodoEditorDialog extends StatefulWidget {
  final TodoGroup? group;
  final String initialCategory;
  const TodoEditorDialog({super.key, this.group, this.initialCategory = ''});

  @override
  State<TodoEditorDialog> createState() => _TodoEditorDialogState();
}

class _TodoEditorDialogState extends State<TodoEditorDialog> {
  late TextEditingController _nameCtrl;
  late String _category;
  late List<TextEditingController> _itemCtrls;
  late List<bool> _itemDone;
  final List<FocusNode> _focusNodes = [];
  bool _tagMenuOpen = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  DateTime? _dueDate;
  DateTime? _reminderDate;
  final ScrollController _listScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.group?.name ?? '');
    _category = widget.group?.category ?? widget.initialCategory ?? '';
    final items = widget.group?.items ?? [TodoItem(text: '')];
    _itemCtrls = items.map((i) => TextEditingController(text: i.text)).toList();
    _itemDone = items.map((i) => i.done).toList();
    _focusNodes.addAll(List.generate(_itemCtrls.length, (_) => FocusNode()));
    _dueDate = widget.group?.dueDate;
    _reminderDate = widget.group?.reminderDate;
    if (widget.group == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _focusNodes.isNotEmpty) _focusNodes.first.requestFocus();
      });
    }
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
                    children: ['', ...state.todoFolders].map((tag) {
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

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _nameCtrl.dispose();
    _listScrollCtrl.dispose();
    for (var c in _itemCtrls) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _removeRow(int i) {
    if (_itemCtrls.length <= 1) return;
    final ctrl = _itemCtrls[i];
    final focus = _focusNodes[i];
    setState(() {
      _itemCtrls.removeAt(i);
      _itemDone.removeAt(i);
      _focusNodes.removeAt(i);
    });
    ctrl.dispose();
    focus.dispose();
    final nextIdx = (i > 0) ? i - 1 : 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && nextIdx < _focusNodes.length) {
        _focusNodes[nextIdx].requestFocus();
      }
    });
  }

  void _addRow() {
    final newFocus = FocusNode();
    setState(() {
      _itemCtrls.add(TextEditingController());
      _itemDone.add(false);
      _focusNodes.add(newFocus);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      newFocus.requestFocus();
      if (_listScrollCtrl.hasClients) {
        _listScrollCtrl.animateTo(
          _listScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

Future<void> _pickReminder() async {
    final isDark = context.read<AppState>().darkMode;
    final result = await showDialog<DateTime>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => CustomDateTimePicker(
        initial: _reminderDate ?? DateTime.now().add(const Duration(hours: 1)),
        isDark: isDark,
      ),
    );
    if (result != null && mounted) setState(() => _reminderDate = result);
  }

  void _save() {
    final state = context.read<AppState>();
    final validItems = _itemCtrls.asMap().entries
        .where((e) => e.value.text.trim().isNotEmpty)
        .map((e) => TodoItem(text: e.value.text.trim(), done: _itemDone[e.key]))
        .toList();
    if (widget.group != null) {
      widget.group!.name = _nameCtrl.text.trim().isEmpty ? 'Список' : _nameCtrl.text.trim();
      widget.group!.category = _category;
      widget.group!.items = validItems;
      widget.group!.dueDate = _dueDate;
      widget.group!.reminderDate = _reminderDate;
      state.updateTodo(widget.group!);
    } else {
      state.addTodo(TodoGroup(
        id: const Uuid().v4(),
        name: _nameCtrl.text.trim().isEmpty ? 'Список' : _nameCtrl.text.trim(),
        category: _category,
        items: validItems,
        dueDate: _dueDate,
        reminderDate: _reminderDate,
      ));
    }
    Navigator.pop(context);
  }

  void _delete() {
    if (widget.group != null) context.read<AppState>().deleteTodo(widget.group!.id);
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

    final mq = MediaQuery.of(context);
    final keyboardHeight = mq.viewInsets.bottom;
    final screenHeight = mq.size.height;
    // Available height = screen minus keyboard minus dialog vertical insets (40*2)
    final available = screenHeight - keyboardHeight - 80;
    // List max height = 85% of available minus fixed header (~85px) and footer (~68px)
    final maxListHeight = (available * 0.85 - 153).clamp(80.0, double.infinity);

    String fmtReminder(DateTime d) =>
        '${d.hour}:${d.minute.toString().padLeft(2, '0')} ${d.day}.${d.month.toString().padLeft(2, '0')}';

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
          // ── Шапка: только если задач > 1 ──
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: _itemCtrls.length > 1
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 120),
                          child: TextField(
                            controller: _nameCtrl,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) {
                              if (_focusNodes.isNotEmpty) _focusNodes.first.requestFocus();
                            },
                            style: appTitleStyle(state.appFont, size: 20, weight: FontWeight.w600, color: text),
                            decoration: InputDecoration(
                              filled: false, border: InputBorder.none,
                              hintText: 'Название списка',
                              hintStyle: appTitleStyle(state.appFont, size: 20, weight: FontWeight.w600, color: textHint),
                              contentPadding: EdgeInsets.zero, isDense: true,
                            ),
                          ),
                        ),
                        CompositedTransformTarget(
                          link: _layerLink,
                          child: GestureDetector(
                            onTap: () => _tagMenuOpen ? _hideTagMenu() : _showTagMenu(context, state, isDark, text),
                            child: _CategoryChip(
                              category: _category,
                              color: state.folderColor(_category),
                              tagMenuOpen: _tagMenuOpen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: _itemCtrls.length > 1
                ? Column(mainAxisSize: MainAxisSize.min, children: [
                    const SizedBox(height: 12),
                    Divider(color: divider, height: 1),
                  ])
                : const SizedBox(height: 16),
          ),
          // ── Список задач ──
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxListHeight),
            child: ListView.builder(
              controller: _listScrollCtrl,
              padding: const EdgeInsets.symmetric(vertical: 8),
              shrinkWrap: true,
              itemCount: _itemCtrls.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _itemDone[i] = !_itemDone[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 18, height: 18,
                        decoration: BoxDecoration(
                          color: _itemDone[i] ? AppColors.terracotta : Colors.transparent,
                          border: Border.all(
                            color: _itemDone[i] ? AppColors.terracotta : divider,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: _itemDone[i]
                            ? const Icon(Icons.check_rounded, size: 11, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CallbackShortcuts(
                        bindings: {
                          SingleActivator(LogicalKeyboardKey.backspace): () {
                            if (_itemCtrls[i].text.isEmpty) _removeRow(i);
                          },
                        },
                        child: TextField(
                        controller: _itemCtrls[i],
                        focusNode: _focusNodes[i],
                        textInputAction: TextInputAction.next,
                        maxLines: null,
                        onChanged: (val) {
                          if (val.contains('\n')) {
                            _itemCtrls[i].text = val.replaceAll('\n', '');
                            _itemCtrls[i].selection = TextSelection.collapsed(
                              offset: _itemCtrls[i].text.length,
                            );
                            if (_itemCtrls[i].text.trim().isNotEmpty) _addRow();
                          }
                        },
                        onSubmitted: (_) { if (_itemCtrls[i].text.trim().isNotEmpty) _addRow(); },
                        style: contentStyle(state.contentFont, size: 14, color: text, height: 1.6),
                        decoration: InputDecoration(
                          filled: false, border: InputBorder.none,
                          hintText: 'Задача...',
                          hintStyle: contentStyle(state.contentFont, size: 14, color: textHint, height: 1.6),
                        ),
                      ),
                      ),
                    ),
                    // Категория-чип — только когда задача одна
                    if (i == 0 && _itemCtrls.length == 1) ...[
                      const SizedBox(width: 8),
                      CompositedTransformTarget(
                        link: _layerLink,
                        child: GestureDetector(
                          onTap: () => _tagMenuOpen ? _hideTagMenu() : _showTagMenu(context, state, isDark, text),
                          child: _CategoryChip(
                            category: _category,
                            color: state.folderColor(_category),
                            tagMenuOpen: _tagMenuOpen,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Divider(color: divider, height: 1),
          // ── Футер: Напоминание | Готово ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Row(
              children: [
                // Напоминание
                GestureDetector(
                  onTap: _pickReminder,
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
                        _reminderDate != null ? fmtReminder(_reminderDate!) : 'Напоминание',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: _reminderDate != null ? AppColors.terracotta : textSec,
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
                    'Готово',
                    style: GoogleFonts.dmSans(
                      fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.terracotta,
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
