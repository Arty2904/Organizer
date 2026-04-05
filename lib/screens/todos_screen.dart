import 'package:flutter/material.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:flutter/services.dart';
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
        ScreenHeader(
          searchHint: state.s.searchTodos,
          onSearch: (q) => setState(() => _query = q),
          categories: state.todoCategories,
          selectedCategory: state.todosFilter,
          onSelectCategory: (c) { state.todosFilter = c; state.refresh(); },
          colorResolver: state.folderColor,
        ),
        Expanded(
          child: todos.isEmpty
              ? EmptyState(icon: Icons.checklist_rounded, label: state.s.noTodos)
              : v == 1
                  ? _listView(context, todos, state, isDark)
                  : v == 2
                      ? _gridView(context, todos, state, isDark)
                      : _compactView(context, todos, state, isDark),
        ),
      ],
    );
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

  Widget _listView(BuildContext context, List<TodoGroup> todos, AppState state, bool isDark) {
    return Column(
      children: [
        ExpandCollapseBar(allExpanded: _allExpanded, onToggle: () => _toggleAll(todos)),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: todos.length,
            itemBuilder: (ctx, i) {
              final todo = todos[i];
              final card = SelectableCardWrapper(
                key: ValueKey(todo.id),
                itemId: todo.id,
                child: SwipableCard(
                  key: ValueKey('sw-td-${todo.id}'),
                  dismissKey: ValueKey('del-todo-${todo.id}'),
                  padding: const EdgeInsets.only(bottom: 10),
                  onDelete: () => state.deleteTodo(todo.id),
                  child: _TodoCard(
                    group: todo,
                    showTag: state.todosFilter == state.s.all,
                    view: 1,
                    expanded: _expandedIds.contains(todo.id),
                    onToggleExpand: () => _toggleExpand(todo.id),
                    onTap: () => _openEditor(context, todo),
                    onCheckItem: (idx) => state.toggleTodoItem(todo.id, idx),
                  ),
                ),
              );
              if (state.todosSort != 'manual') return card;
              return DraggableListCard(
                key: ValueKey(todo.id),
                itemId: todo.id,
                dragState: _listDragState,
                onReorder: (f, t) => state.reorderTodoById(f, t),
                child: card,
              );
            },
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
    return Column(
      children: [
        ExpandCollapseBar(allExpanded: _allExpanded, onToggle: () => _toggleAll(todos)),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: todos.length,
            itemBuilder: (ctx, i) {
              final todo = todos[i];
              final card = SelectableCardWrapper(
                key: ValueKey(todo.id),
                itemId: todo.id,
                child: _TodoCard(
                  key: ValueKey('td-c-${todo.id}'),
                  group: todo,
                  showTag: false,
                  view: 3,
                  expanded: _expandedIds.contains(todo.id),
                  onToggleExpand: () => _toggleExpand(todo.id),
                  onTap: () => _openEditor(context, todo),
                  onCheckItem: (idx) => state.toggleTodoItem(todo.id, idx),
                ),
              );
              if (state.todosSort != 'manual') return card;
              return DraggableListCard(
                key: ValueKey(todo.id),
                itemId: todo.id,
                dragState: _listDragState,
                onReorder: (f, t) => state.reorderTodoById(f, t),
                child: card,
              );
            },
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

// ─── Todos Grid ──────────────────────────────────────────
// date sort → статичный grid; manual sort → ReorderableGridView
class _TodosMasonryGrid extends StatelessWidget {
  final void Function(TodoGroup) onOpenEditor;

  const _TodosMasonryGrid({required this.onOpenEditor});

  @override
  Widget build(BuildContext context) {
    final state   = context.watch<AppState>();
    final todos   = state.filteredTodos('');
    final showTag = state.todosFilter == state.s.all;

    return LayoutBuilder(builder: (ctx, constraints) {
      const double spacing = 10;
      const double hPad    = 16;
      final colW = (constraints.maxWidth - hPad * 2 - spacing) / 2;
      const double itemHeight = 148;

      if (state.todosSort == 'manual') {
        return ReorderableGridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: colW / itemHeight,
          padding: const EdgeInsets.fromLTRB(hPad, 0, hPad, 100),
          onReorder: (oldIdx, newIdx) {
            final fromId = todos[oldIdx].id;
            final toId   = todos[newIdx].id;
            context.read<AppState>().reorderTodoById(fromId, toId);
          },
          dragWidgetBuilder: (index, child) => Material(
            color: Colors.transparent,
            child: Transform.scale(scale: 1.03,
              child: Opacity(opacity: 0.92, child: child)),
          ),
          children: todos.map((g) => SelectableCardWrapper(
            key: ValueKey(g.id),
            itemId: g.id,
            child: _TodoCard(
              group: g, showTag: showTag, view: 2,
              expanded: false, onToggleExpand: () {},
              onTap: () => onOpenEditor(g),
              onCheckItem: (idx) => context.read<AppState>().toggleTodoItem(g.id, idx),
            ),
          )).toList(),
        );
      }

      // date sort — обычный двухколоночный grid
      Widget buildCard(TodoGroup g) => KeyedSubtree(
        key: ValueKey(g.id),
        child: SelectableCardWrapper(
          itemId: g.id,
          child: Padding(
            padding: const EdgeInsets.only(bottom: spacing),
            child: _TodoCard(
              group: g, showTag: showTag, view: 2,
              expanded: false, onToggleExpand: () {},
              onTap: () => onOpenEditor(g),
              onCheckItem: (idx) => context.read<AppState>().toggleTodoItem(g.id, idx),
            ),
          ),
        ),
      );

      final left  = [for (int i = 0; i < todos.length; i += 2) todos[i]];
      final right = [for (int i = 1; i < todos.length; i += 2) todos[i]];

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(hPad, 0, hPad, 100),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: colW, child: Column(children: left.map(buildCard).toList())),
            const SizedBox(width: spacing),
            SizedBox(width: colW, child: Column(children: right.map(buildCard).toList())),
          ],
        ),
      );
    });
  }
}

// ─── Swipable Card ─────────────────────────────────────────

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
    final bool hasColor = group.colorIndex > 0 && group.colorIndex <= kCardColors.length;
    final Color cardBg = hasColor
        ? kCardColors[group.colorIndex - 1]
        : (isDark ? const Color(0x0DFFFFFF) : const Color(0x40FFFFFF));
    final textColor = hasColor ? AppColors.textColorFor(cardBg) : (isDark ? AppColors.darkText : AppColors.lightText);
    final textSec = hasColor ? AppColors.textSecColorFor(cardBg) : (isDark ? AppColors.darkTextBody : AppColors.lightTextBody);
    final divider = hasColor ? AppColors.dividerColorFor(cardBg) : (isDark ? AppColors.darkDivider : AppColors.lightDivider);
    final catColor = state.folderColor(group.category);

    // ── Compact view (view 3) — expandable rows ──
    if (view == 3) {
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
    // reminder/repeat chip — показываем в list и grid (не в compact)
    final repeatStr = repeatLabel(group.repeat, group.customDays, s: state.s);
    Widget reminderChip = const SizedBox.shrink();
    bool hasReminderChip = false;
    if (group.reminderDate != null) {
      hasReminderChip = true;
      reminderChip = Container(
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
            Flexible(
              child: Text(
                formatDateTime(group.reminderDate, s: state.s),
                style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.terracotta, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
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
      );
    } else if (repeatStr.isNotEmpty) {
      hasReminderChip = true;
      reminderChip = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.terracotta.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.repeat_rounded, size: 11, color: AppColors.terracotta),
            const SizedBox(width: 4),
            Text(
              repeatStr,
              style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.terracotta, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    // ── Grid view (view 2) — fixed 148px, uniform layout ──
    if (view == 2) {
      final hasTitle = group.name.trim().isNotEmpty;

      // Чип для grid — только дата, без периодичности
      Widget gridChip = const SizedBox.shrink();
      bool hasChip = false;
      if (group.reminderDate != null) {
        hasChip = true;
        gridChip = Container(
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
              Flexible(
                child: Text(
                  formatDateTime(group.reminderDate, s: state.s),
                  style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.terracotta, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      } else if (repeatStr.isNotEmpty) {
        hasChip = true;
        gridChip = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.terracotta.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.repeat_rounded, size: 11, color: AppColors.terracotta),
              const SizedBox(width: 4),
              Text(
                repeatStr,
                style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.terracotta, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      }

      // Точный подсчёт доступного места под задачи
      // Карточка 148, паддинг top 12, паддинг bottom 12
      // Чип занимает 38px снизу (26px высота + 12px gap)
      // Заголовок: 18px. Прогресс+gap: 19px. SizedBox(6): 6px.
      const double cardInner   = 148 - 12 - 12; // 124
      const double chipReserve = 38.0;
      const double titleH      = 18.0;
      const double progressH   = 19.0; // SizedBox(5) + bar(8) + SizedBox(6) = 19
      const double itemH       = 18.0; // checkbox 14 + padding-bottom 4

      final double available = cardInner
          - (hasChip ? chipReserve : 0)
          - titleH
          - (group.total > 0 ? progressH : 6.0) // 6 = только SizedBox(6)
      ;
      final int maxItems = (available / itemH).floor().clamp(0, 4);
      final gridItems = group.items.take(maxItems).toList();

      return GestureDetector(
        onTap: onTap,
        child: SelectionHighlight(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 148,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasColor ? Colors.transparent : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
                width: 1,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  top: 12, left: 12, right: 12,
                  bottom: hasChip ? 38 : 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Заголовок + точка категории
                      if (hasTitle)
                        Padding(
                          padding: EdgeInsets.only(right: showTag ? 56 : 0),
                          child: Row(
                            children: [
                              Container(width: 6, height: 6, decoration: BoxDecoration(color: catColor, shape: BoxShape.circle)),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  group.name.trim(),
                                  style: appTitleStyle(state.appFont, size: 13, weight: FontWeight.w600, color: textColor),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Прогресс-бар
                      if (group.total > 0) ...[
                        const SizedBox(height: 5),
                        _ProgressBar(done: group.doneCount, total: group.total),
                      ],
                      const SizedBox(height: 6),
                      // Задачи — только если есть заголовок
                      if (hasTitle)
                        ...gridItems.asMap().entries.map((e) {
                        final idx = e.key;
                        final item = e.value;
                        return GestureDetector(
                          onTap: () => onCheckItem(idx),
                          child: SizedBox(
                            height: itemH,
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 14, height: 14,
                                  decoration: BoxDecoration(
                                    color: item.done ? AppColors.terracotta : Colors.transparent,
                                    border: Border.all(
                                      color: item.done ? AppColors.terracotta : divider,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: item.done
                                      ? const Icon(Icons.check_rounded, size: 9, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    item.text,
                                    style: contentStyle(state.contentFont, size: 11, color: item.done ? textSec : textColor, height: 1.3).copyWith(
                                      decoration: item.done ? TextDecoration.lineThrough : null,
                                      decorationColor: textSec,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                // Чип напоминания/повтора — прибит к низу
                if (hasChip)
                  Positioned(
                    bottom: 10, left: 12, right: 12,
                    child: gridChip,
                  ),
                // Тег папки — верхний правый угол (только если есть заголовок)
                if (showTag && hasTitle && group.category.isNotEmpty)
                  Positioned(
                    top: 12, right: 12,
                    child: CategoryBadge(
                      label: group.category.length > 7
                          ? group.category.substring(0, 7)
                          : group.category,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // ── List view (view 1) ──
    final maxVisible = !expanded ? 3 : group.items.length;
    final items = group.items.take(maxVisible).toList();

    // Режим «только задача»: одна задача — без названия, бара и тега (все виды)
    final singleTaskNoTitle = group.items.length == 1;

    if (singleTaskNoTitle) {
      final item = group.items.first;
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hasColor ? Colors.transparent : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
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
                      style: contentStyle(state.contentFont, size: 12, color: item.done ? textSec : textColor, height: 1.4).copyWith(
                        decoration: item.done ? TextDecoration.lineThrough : null,
                        decorationColor: textSec,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (hasReminderChip) ...[
                const SizedBox(height: 8),
                reminderChip,
              ],
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: SelectionHighlight(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: hasColor ? Colors.transparent : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (group.name.trim().isNotEmpty)
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
                if (group.name.trim().isNotEmpty && group.total > 0) ...[
                  const SizedBox(height: 6),
                  _ProgressBar(done: group.doneCount, total: group.total),
                ],
                if (items.isNotEmpty) ...[
                  if (group.name.trim().isNotEmpty) const SizedBox(height: 8),
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
                                  style: contentStyle(state.contentFont, size: 12, color: item.done ? textSec : textColor, height: 1.4).copyWith(
                                    decoration: item.done ? TextDecoration.lineThrough : null,
                                    decorationColor: textSec,
                                  ),
                                  maxLines: expanded ? 2 : 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList();

                    if (expanded && group.items.length > 3) {
                      return ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: itemWidgets),
                        ),
                      );
                    }
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: itemWidgets);
                  }),
                  if (group.items.length > 3)
                    const SizedBox(height: 12),
                ],
                if (hasReminderChip) ...[
                  const SizedBox(height: 8),
                  reminderChip,
                ],
              ],
            ),
            ),
            if (showTag && group.name.trim().isNotEmpty)
              Positioned(
                top: 14, right: 14,
                child: CategoryBadge(
                  label: group.category.length > 7
                      ? group.category.substring(0, 7)
                      : group.category,
                ),
              ),
            if (group.items.length > 3)
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
  RepeatInterval _repeat = RepeatInterval.none;
  int? _customDays;
  final TextEditingController _customDaysCtrl = TextEditingController();
  final FocusNode _customDaysFocus = FocusNode();
  final ScrollController _listScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.group?.name ?? '');
    _category = widget.group?.category ?? widget.initialCategory;
    final items = widget.group?.items ?? [TodoItem(text: '')];
    _itemCtrls = items.map((i) => TextEditingController(text: i.text)).toList();
    _itemDone = items.map((i) => i.done).toList();
    _focusNodes.addAll(List.generate(_itemCtrls.length, (_) => FocusNode()));
    _dueDate = widget.group?.dueDate;
    _reminderDate = widget.group?.reminderDate;
    _repeat = widget.group?.repeat ?? RepeatInterval.none;
    _customDays = widget.group?.customDays;
    if (_customDays != null) _customDaysCtrl.text = _customDays.toString();
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

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _nameCtrl.dispose();
    _customDaysCtrl.dispose();
    _customDaysFocus.dispose();
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

  void _showRepeatPicker() {
    final appState = context.read<AppState>();
    final isDark = appState.darkMode;
    final appFont = appState.appFont;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextBody : AppColors.lightTextBody;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;

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
                                        size: 14, color: textSec),
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
                                          color: AppColors.terracotta, width: 1.5),
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() => _repeat = RepeatInterval.custom);
                                      setDlgState(() {});
                                    },
                                    onChanged: (v) {
                                      setState(() => _customDays = int.tryParse(v));
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
      setState(() => _customDays = int.tryParse(_customDaysCtrl.text));
    });
  }

  void _save() {
    final state = context.read<AppState>();
    final validItems = _itemCtrls.asMap().entries
        .where((e) => e.value.text.trim().isNotEmpty)
        .map((e) => TodoItem(text: e.value.text.trim(), done: _itemDone[e.key]))
        .toList();
    final defaultName = validItems.length == 1 ? state.s.defaultTask : state.s.defaultList;
    if (widget.group != null) {
      widget.group!.name = _nameCtrl.text.trim().isEmpty ? defaultName : _nameCtrl.text.trim();
      widget.group!.category = _category;
      widget.group!.items = validItems;
      widget.group!.dueDate = _dueDate;
      widget.group!.reminderDate = _reminderDate;
      widget.group!.repeat = _repeat;
      widget.group!.customDays = _repeat == RepeatInterval.custom ? int.tryParse(_customDaysCtrl.text) : null;
      state.updateTodo(widget.group!);
    } else {
      state.addTodo(TodoGroup(
        id: const Uuid().v4(),
        name: _nameCtrl.text.trim().isEmpty ? defaultName : _nameCtrl.text.trim(),
        category: _category,
        items: validItems,
        dueDate: _dueDate,
        reminderDate: _reminderDate,
        repeat: _repeat,
        customDays: _repeat == RepeatInterval.custom ? int.tryParse(_customDaysCtrl.text) : null,
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
                            textInputAction: TextInputAction.done,
                            style: appTitleStyle(state.appFont, size: 20, weight: FontWeight.w600, color: text),
                            decoration: InputDecoration(
                              filled: false, border: InputBorder.none,
                              hintText: state.s.todoTitle,
                              hintStyle: appTitleStyle(state.appFont, size: 20, weight: FontWeight.w600, color: textHint),
                              contentPadding: EdgeInsets.zero, isDense: true,
                            ),
                          ),
                        ),
                        CompositedTransformTarget(
                          link: _layerLink,
                          child: CategoryChip(
                              category: _category,
                              color: state.folderColor(_category),
                              menuOpen: _tagMenuOpen,
                              onTap: () => _tagMenuOpen ? _hideTagMenu() : _showTagMenu(context, state, isDark, text),
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
                          hintText: state.s.taskPlaceholder,
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
                        child: CategoryChip(
                          category: _category,
                          color: state.folderColor(_category),
                          menuOpen: _tagMenuOpen,
                          onTap: () => _tagMenuOpen ? _hideTagMenu() : _showTagMenu(context, state, isDark, text),
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
                        _reminderDate != null ? fmtReminder(_reminderDate!) : state.s.reminder,
                        style: appTitleStyle(state.appFont, size: 12,
                          color: _reminderDate != null ? AppColors.terracotta : textSec,
                        ),
                      ),
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
