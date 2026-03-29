import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class TodosScreen extends StatefulWidget {
  const TodosScreen({super.key});

  @override
  State<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
  String _query = '';
  final Set<String> _expandedIds = {};

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
                categories: AppState.todoCategories,
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
        Icon(Icons.checklist_rounded, size: 48, color: AppColors.terracotta.withOpacity(0.3)),
        const SizedBox(height: 12),
        Text('Нет дел', style: GoogleFonts.fraunces(
          fontSize: 16, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        )),
      ],
    ),
  );

  Widget _listView(BuildContext context, List<TodoGroup> todos, AppState state, bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: todos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _TodoCard(
        group: todos[i],
        showTag: state.todosFilter == 'Все',
        view: 1,
        expanded: _expandedIds.contains(todos[i].id),
        onToggleExpand: () => setState(() {
          if (_expandedIds.contains(todos[i].id)) _expandedIds.remove(todos[i].id);
          else _expandedIds.add(todos[i].id);
        }),
        onTap: () => _openEditor(context, todos[i]),
        onCheckItem: (idx) => state.toggleTodoItem(todos[i].id, idx),
      ),
    );
  }

  Widget _gridView(BuildContext context, List<TodoGroup> todos, AppState state, bool isDark) {
    return MasonryGridView.count(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      itemCount: todos.length,
      itemBuilder: (ctx, i) => _TodoCard(
        group: todos[i],
        showTag: state.todosFilter == 'Все',
        view: 2,
        expanded: false,
        onToggleExpand: () {},
        onTap: () => _openEditor(context, todos[i]),
        onCheckItem: (idx) => state.toggleTodoItem(todos[i].id, idx),
      ),
    );
  }

  Widget _compactView(BuildContext context, List<TodoGroup> todos, AppState state, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: todos.length,
      itemBuilder: (ctx, i) => _TodoCard(
        group: todos[i],
        showTag: false,
        view: 3,
        expanded: false,
        onToggleExpand: () {},
        onTap: () => _openEditor(context, todos[i]),
        onCheckItem: (idx) => state.toggleTodoItem(todos[i].id, idx),
      ),
    );
  }

  void _openEditor(BuildContext context, [TodoGroup? group]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TodoEditorSheet(group: group),
    );
  }

}

// ─── Todo Card ─────────────────────────────────────────────
class _TodoCard extends StatelessWidget {
  final TodoGroup group;
  final bool showTag;
  final int view; // 1=list, 2=grid, 3=compact
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onTap;
  final ValueChanged<int> onCheckItem;

  const _TodoCard({
    required this.group,
    required this.showTag,
    required this.view,
    required this.expanded,
    required this.onToggleExpand,
    required this.onTap,
    required this.onCheckItem,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.darkMode;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final catColor = AppColors.categoryColor(group.category);
    final maxItems = view == 2 ? 3 : (view == 3 ? 0 : (expanded ? group.items.length : 3));
    final showItems = view != 3;
    final items = showItems ? group.items.take(maxItems).toList() : [];

    if (view == 3) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: divider)),
          ),
          child: Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: catColor, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(group.name, style: GoogleFonts.fraunces(
                  fontSize: 13, fontWeight: FontWeight.w600, color: textColor,
                ), overflow: TextOverflow.ellipsis),
              ),
              Text(
                '${group.doneCount}/${group.total}',
                style: GoogleFonts.dmSans(fontSize: 10, color: textSec),
              ),
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
                      Expanded(
                        child: GestureDetector(
                          onTap: view == 1 ? onToggleExpand : null,
                          child: Text(
                            group.name,
                            style: GoogleFonts.fraunces(
                              fontSize: view == 2 ? 13 : 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                      if (view == 1)
                        Icon(
                          expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          size: 16, color: textSec,
                        ),
                    ],
                  ),
                ),
                if (group.total > 0) ...[
                  const SizedBox(height: 6),
                  _ProgressBar(done: group.doneCount, total: group.total),
                ],
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...items.asMap().entries.map((e) {
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
                                style: GoogleFonts.dmSans(
                                  fontSize: view == 2 ? 11 : 12,
                                  color: item.done ? textSec : textColor,
                                  decoration: item.done ? TextDecoration.lineThrough : null,
                                  decorationColor: textSec,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (group.items.length > maxItems && view == 1 && !expanded)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+ ещё ${group.items.length - maxItems}',
                        style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.terracotta),
                      ),
                    ),
                ],
              ],
            ),
            Positioned(
              top: 0, right: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (showTag) CategoryBadge(label: group.category),
                  const SizedBox(height: 4),
                  Text(
                    formatDate(group.createdAt),
                    style: GoogleFonts.dmSans(fontSize: 9, color: textSec),
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

// ─── Todo Editor Sheet ─────────────────────────────────────
class TodoEditorSheet extends StatefulWidget {
  final TodoGroup? group;
  const TodoEditorSheet({super.key, this.group});

  @override
  State<TodoEditorSheet> createState() => _TodoEditorSheetState();
}

class _TodoEditorSheetState extends State<TodoEditorSheet> {
  late TextEditingController _nameCtrl;
  late String _category;
  late List<TextEditingController> _itemCtrls;
  late List<bool> _itemDone;
  final List<FocusNode> _focusNodes = [];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.group?.name ?? '');
    _category = widget.group?.category ?? 'Дом';
    final items = widget.group?.items ?? [TodoItem(text: '')];
    _itemCtrls = items.map((i) => TextEditingController(text: i.text)).toList();
    _itemDone = items.map((i) => i.done).toList();
    _focusNodes.addAll(List.generate(_itemCtrls.length, (_) => FocusNode()));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (var c in _itemCtrls) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _addRow() {
    setState(() {
      _itemCtrls.add(TextEditingController());
      _itemDone.add(false);
      _focusNodes.add(FocusNode());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes.last.requestFocus();
    });
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
      state.updateTodo(widget.group!);
    } else {
      state.addTodo(TodoGroup(
        id: const Uuid().v4(),
        name: _nameCtrl.text.trim().isEmpty ? 'Список' : _nameCtrl.text.trim(),
        category: _category,
        items: validItems,
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
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: divider, borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Header row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameCtrl,
                      style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w600, color: text),
                      decoration: InputDecoration(
                        filled: false,
                        border: InputBorder.none,
                        hintText: 'Название списка',
                        hintStyle: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w600, color: textSec.withOpacity(0.4)),
                      ),
                    ),
                  ),
                  if (widget.group != null)
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
                  children: AppState.todoCategories.skip(1).map((cat) {
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
                          child: Text(cat, style: GoogleFonts.dmSans(
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
            const SizedBox(height: 8),
            Divider(color: divider, height: 1),
            Flexible(
              child: ListView.builder(
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
                        child: TextField(
                          controller: _itemCtrls[i],
                          focusNode: _focusNodes[i],
                          style: GoogleFonts.dmSans(fontSize: 14, color: text),
                          decoration: InputDecoration(
                            filled: false,
                            border: InputBorder.none,
                            hintText: 'Задача...',
                            hintStyle: GoogleFonts.dmSans(fontSize: 14, color: textSec.withOpacity(0.4)),
                          ),
                          onSubmitted: (_) => _addRow(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: GestureDetector(
                onTap: _addRow,
                child: Row(
                  children: [
                    Icon(Icons.add_rounded, size: 18, color: AppColors.terracotta),
                    const SizedBox(width: 8),
                    Text('Добавить задачу', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.terracotta)),
                  ],
                ),
              ),
            ),
            Divider(color: divider, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _save,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.terracotta,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Сохранить',
                          style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
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
