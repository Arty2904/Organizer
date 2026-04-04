import 'package:flutter/material.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../theme/font_helper.dart';
import '../widgets/common_widgets.dart';
import '../widgets/selection_state.dart';
import '../theme/card_colors.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _query = '';
  final Set<String> _expandedIds = {};
  final ValueNotifier<String?> _listDragState = ValueNotifier(null);

  bool get _allExpanded {
    final state = context.read<AppState>();
    final notes = state.filteredNotes(_query);
    return notes.isNotEmpty && notes.every((n) => _expandedIds.contains(n.id));
  }

  void _toggleAll(List<Note> notes) {
    setState(() {
      if (_allExpanded) {
        _expandedIds.clear();
      } else {
        for (final n in notes) {
          _expandedIds.add(n.id);
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
  void dispose() {
    _listDragState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final notes = state.filteredNotes(_query);
    final v = state.notesView;

    return Column(
      children: [
        ScreenHeader(
          searchHint: 'Поиск заметок...',
          onSearch: (q) => setState(() => _query = q),
          categories: state.noteCategories,
          selectedCategory: state.notesFilter,
          onSelectCategory: (c) { state.notesFilter = c; state.refresh(); },
          colorResolver: state.folderColor,
        ),
        Expanded(
          child: notes.isEmpty
              ? const EmptyState(icon: Icons.note_add_outlined, label: 'Нет заметок')
              : v == 1
                  ? _listView(context, notes, state)
                  : v == 2
                      ? _NoteGrid(notes: notes, state: state, showTag: state.notesFilter == 'Все', onOpenEditor: (n) => _openEditor(context, n))
                      : _compactView(context, notes, state),
        ),
      ],
    );
  }

  Widget _listView(BuildContext context, List<Note> notes, AppState state) {
    return Column(
      children: [
        ExpandCollapseBar(allExpanded: _allExpanded, onToggle: () => _toggleAll(notes)),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: notes.length,
            itemBuilder: (ctx, i) {
              final note = notes[i];
              final card = SelectableCardWrapper(
                key: ValueKey(note.id),
                itemId: note.id,
                child: _SwipableNote(
                  key: ValueKey('note-sw-${note.id}'),
                  note: note,
                  showTag: state.notesFilter == 'Все',
                  expanded: _expandedIds.contains(note.id),
                  onToggleExpand: () => _toggleExpand(note.id),
                  onTap: () => _openEditor(context, note),
                  onDelete: () => state.deleteNote(note.id),
                ),
              );
              if (state.notesSort != 'manual') return card;
              return DraggableListCard(
                key: ValueKey(note.id),
                itemId: note.id,
                dragState: _listDragState,
                onReorder: (f, t) => state.reorderNoteById(f, t),
                child: card,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _compactView(BuildContext context, List<Note> notes, AppState state) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: notes.length,
      itemBuilder: (ctx, i) {
        final note = notes[i];
        final card = SelectableCardWrapper(
          key: ValueKey(note.id),
          itemId: note.id,
          child: SwipableCard(
            key: ValueKey('swc-${note.id}'),
            dismissKey: ValueKey('del-notec-${note.id}'),
            onDelete: () => state.deleteNote(note.id),
            child: _NoteCard(
              note: note, showTag: false,
              compact: true, grid: false,
              onTap: () => _openEditor(context, note),
            ),
          ),
        );
        if (state.notesSort != 'manual') return card;
        return DraggableListCard(
          key: ValueKey(note.id),
          itemId: note.id,
          dragState: _listDragState,
          onReorder: (f, t) => state.reorderNoteById(f, t),
          child: card,
        );
      },
    );
  }

  void _openEditor(BuildContext context, [Note? note]) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => NoteEditorScreen(note: note),
    ));
  }
}

// ─── Note Grid ────────────────────────────────────────────
// date sort → статичный masonry; manual sort → ReorderableGridView
class _NoteGrid extends StatelessWidget {
  final List<Note> notes;
  final AppState state;
  final bool showTag;
  final void Function(Note) onOpenEditor;

  const _NoteGrid({
    super.key,
    required this.notes,
    required this.state,
    required this.showTag,
    required this.onOpenEditor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      const double spacing = 10;
      const double hPad    = 16;
      final colWidth = (constraints.maxWidth - hPad * 2 - spacing) / 2;
      const double itemHeight = 148;

      if (state.notesSort == 'manual') {
        return ReorderableGridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: colWidth / itemHeight,
          padding: const EdgeInsets.fromLTRB(hPad, 0, hPad, 100),
          onReorder: (oldIdx, newIdx) {
            final fromId = notes[oldIdx].id;
            final toId   = notes[newIdx].id;
            context.read<AppState>().reorderNoteById(fromId, toId);
          },
          dragWidgetBuilder: (index, child) => Material(
            color: Colors.transparent,
            child: Transform.scale(scale: 1.03,
              child: Opacity(opacity: 0.92, child: child)),
          ),
          children: notes.map((note) => SelectableCardWrapper(
            key: ValueKey(note.id),
            itemId: note.id,
            child: _GridCard(
              note: note, showTag: showTag, width: colWidth,
              onTap: () => onOpenEditor(note),
              isDark: state.darkMode,
            ),
          )).toList(),
        );
      }

      // date sort — обычный двухколоночный grid
      final left  = [for (int i = 0; i < notes.length; i += 2) notes[i]];
      final right = [for (int i = 1; i < notes.length; i += 2) notes[i]];

      Widget card(Note note) => KeyedSubtree(
        key: ValueKey(note.id),
        child: SelectableCardWrapper(
          itemId: note.id,
          child: Padding(
            padding: const EdgeInsets.only(bottom: spacing),
            child: _GridCard(
              note: note, showTag: showTag, width: colWidth,
              onTap: () => onOpenEditor(note),
              isDark: state.darkMode,
            ),
          ),
        ),
      );

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(hPad, 0, hPad, 100),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: colWidth, child: Column(children: left.map(card).toList())),
            const SizedBox(width: spacing),
            SizedBox(width: colWidth, child: Column(children: right.map(card).toList())),
          ],
        ),
      );
    });
  }
}

// ─── Swipable Note (list view only) ──────────────────────
class _SwipableNote extends StatelessWidget {
  final Note note;
  final bool showTag;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SwipableNote({
    super.key,
    required this.note,
    required this.showTag,
    this.expanded = false,
    this.onToggleExpand = _noop,
    required this.onTap,
    required this.onDelete,
  });

  static void _noop() {}

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().darkMode;
    return Dismissible(
      key: ValueKey('dismiss-${note.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => DeleteConfirmDialog.show(
        context,
        isDark: isDark,
        title: 'Удалить?',
        subtitle: note.title,
      ),
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
            const SizedBox(height: 2),
            Text('Удалить', style: GoogleFonts.dmSans(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _NoteCard(
          note: note, showTag: showTag,
          compact: false, grid: false,
          expanded: expanded,
          onToggleExpand: onToggleExpand,
          onTap: onTap,
        ),
      ),
    );
  }
}

// ─── Note Card ────────────────────────────────────────────
class _NoteCard extends StatefulWidget {
  final Note note;
  final bool showTag;
  final bool compact;
  final bool grid;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onTap;

  const _NoteCard({
    required this.note,
    required this.showTag,
    required this.compact,
    required this.grid,
    this.expanded = false,
    this.onToggleExpand = _noop,
    required this.onTap,
  });

  static void _noop() {}

  @override
  State<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<_NoteCard> {
  bool _bodyOverflows = false;

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final showTag = widget.showTag;
    final compact = widget.compact;
    final grid = widget.grid;
    final onTap = widget.onTap;

    final state = context.watch<AppState>();
    final isDark = state.darkMode;
    final bool hasCustomColor = note.colorIndex > 0;
    final Color cardBg = hasCustomColor && note.colorIndex <= kNoteColors.length
        ? kNoteColors[note.colorIndex - 1]
        : (isDark ? const Color(0x0DFFFFFF) : const Color(0x40FFFFFF));
    final textColor = hasCustomColor
        ? AppColors.textColorFor(cardBg)
        : (isDark ? AppColors.darkText : AppColors.lightText);
    final textSec = hasCustomColor
        ? AppColors.textSecColorFor(cardBg)
        : (isDark ? AppColors.darkTextDate : AppColors.lightTextDate);
    final catColor = state.folderColor(note.category);

    // ── Compact view (view 3) — no date ──
    if (compact) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            )),
          ),
          child: Row(
            children: [
              Container(width: 6, height: 6,
                  decoration: BoxDecoration(color: catColor, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(note.title,
                  style: appTitleStyle(state.appFont, size: 13, weight: FontWeight.w600, color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Grid view (view 2) — fixed height, title 1 line, body 4 lines ──
    if (grid) {
      return GestureDetector(
        onTap: onTap,
        child: SelectionHighlight(
          borderRadius: BorderRadius.circular(16),
          child: Container(
          width: double.infinity,
          height: 148,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasCustomColor ? Colors.transparent : (isDark ? AppColors.darkDivider : AppColors.lightDivider),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                note.title,
                style: appTitleStyle(state.appFont, size: 13, weight: FontWeight.w600, color: textColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (note.body.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  note.body,
                  style: contentStyle(state.contentFont, size: 11, color: textSec, height: 1.4),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ],
            ],
          ),
        ),
        ),
      );
    }

    // ── List view (view 1) ──
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
              border: Border.all(
                color: hasCustomColor ? Colors.transparent : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 60),
                  child: Row(
                    children: [
                      Container(width: 6, height: 6,
                          decoration: BoxDecoration(color: catColor, shape: BoxShape.circle)),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(note.title,
                          style: appTitleStyle(state.appFont, size: 15, weight: FontWeight.w600, color: textColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (note.body.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    // Текст: правый отступ оставляет место для уголка
                    Padding(
                      padding: EdgeInsets.only(right: _bodyOverflows ? 22.0 : 0.0),
                      child: widget.expanded
                        ? ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 180),
                            child: SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              child: Text(
                                note.body,
                                style: contentStyle(state.contentFont, size: 12, color: textSec, height: 1.4),
                              ),
                            ),
                          )
                        : Text(
                            note.body,
                            style: contentStyle(state.contentFont, size: 12, color: textSec, height: 1.4),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                    ),
                    // LayoutBuilder всегда на полной ширине — без петли
                    LayoutBuilder(builder: (ctx, constraints) {
                      final tp = TextPainter(
                        text: TextSpan(
                          text: note.body,
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
                ],
              ),
            ),
            // Top right: tag (7 chars max) only — no date
            if (showTag)
              Positioned(
                top: 14, right: 14,
                child: CategoryBadge(
                  label: note.category.length > 7
                      ? note.category.substring(0, 7)
                      : note.category,
                ),
              ),
            if (widget.expanded || _bodyOverflows)
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

// ─── Grid Card (explicit width) ───────────────────────────
class _GridCard extends StatelessWidget {
  final Note note;
  final bool showTag;
  final double width;
  final VoidCallback onTap;
  final bool isDark;

  const _GridCard({
    required this.note,
    required this.showTag,
    required this.width,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasCustomColor = note.colorIndex > 0;
    final Color cardBg = hasCustomColor && note.colorIndex <= kNoteColors.length
        ? kNoteColors[note.colorIndex - 1]
        : (isDark ? const Color(0x0DFFFFFF) : const Color(0x40FFFFFF));
    final textColor = hasCustomColor
        ? AppColors.textColorFor(cardBg)
        : (isDark ? AppColors.darkText : AppColors.lightText);
    final textSec = hasCustomColor
        ? AppColors.textSecColorFor(cardBg)
        : (isDark ? AppColors.darkTextDate : AppColors.lightTextDate);
    final borderColor = hasCustomColor
        ? Colors.transparent
        : (isDark ? AppColors.darkDivider : AppColors.lightDivider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 148,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: width - 24,
              child: Text(
                note.title,
                style: appTitleStyle(context.watch<AppState>().appFont, size: 13, weight: FontWeight.w600, color: textColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (note.body.isNotEmpty) ...[
              const SizedBox(height: 6),
              SizedBox(
                width: width - 24,
                child: Text(
                  note.body,
                  style: contentStyle(context.watch<AppState>().contentFont, size: 11, color: textSec, height: 1.4),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Note Editor ─────────────────────────────────────────

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final String initialCategory;
  const NoteEditorScreen({super.key, this.note, this.initialCategory = ''});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _bodyCtrl;
  late String _category;
  late int _colorIndex;
  bool _tagMenuOpen = false;
  final LayerLink _menuLayerLink = LayerLink();
  OverlayEntry? _menuOverlayEntry;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note?.title ?? '');
    _bodyCtrl = TextEditingController(text: widget.note?.body ?? '');
    _category = widget.note?.category ?? widget.initialCategory;
    _colorIndex = widget.note?.colorIndex ?? 0;
  }

  @override
  void dispose() {
    _menuOverlayEntry?.remove();
    _menuOverlayEntry = null;
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _delete() {
    if (widget.note != null) {
      context.read<AppState>().deleteNote(widget.note!.id);
    }
    Navigator.pop(context);
  }

  void _hideMenu() {
    _menuOverlayEntry?.remove();
    _menuOverlayEntry = null;
  }

  void _showDropdownMenu(BuildContext context, bool isDark) {
    _hideMenu();
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    _menuOverlayEntry = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _hideMenu,
        child: Stack(
          children: [
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
                  width: 220,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: divider, width: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                        blurRadius: 16, offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Цвет ──
                      GestureDetector(
                        onTap: () {
                          _hideMenu();
                          _showColorPickerPopup(context, isDark);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Icon(Icons.palette_outlined, size: 16, color: AppColors.terracotta),
                              const SizedBox(width: 10),
                              Text('Цвет', style: GoogleFonts.dmSans(fontSize: 13, color: text)),
                            ],
                          ),
                        ),
                      ),
                      Divider(height: 1, color: divider),
                      // ── Удалить ──
                      GestureDetector(
                        onTap: () {
                          _hideMenu();
                          _showDeleteConfirm(context, isDark);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red.withValues(alpha: 0.75)),
                              const SizedBox(width: 10),
                              Text('Удалить', style: GoogleFonts.dmSans(fontSize: 13, color: Colors.red.withValues(alpha: 0.85))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    Overlay.of(context).insert(_menuOverlayEntry!);
  }

  void _showColorPickerPopup(BuildContext context, bool isDark) {
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
              Text('Цвет заметки', style: appTitleStyle(context.watch<AppState>().appFont, size: 16, weight: FontWeight.w600, color: text)),
              const SizedBox(height: 16),
              ColorPickerGrid(
                selectedIndex: _colorIndex,
                isDark: isDark,
                large: true,
                onSelect: (i) => setState(() => _colorIndex = i),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, bool isDark) {
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextBody : AppColors.lightTextBody;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => Dialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Удалить заметку?', style: appTitleStyle(context.watch<AppState>().appFont, size: 18, weight: FontWeight.w600, color: text)),
              const SizedBox(height: 8),
              Text(
                widget.note?.title.isEmpty ?? true ? 'Без названия' : widget.note!.title,
                style: GoogleFonts.dmSans(fontSize: 13, color: textSec),
                maxLines: 2, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBg2 : AppColors.lightBg2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text('Отмена', style: GoogleFonts.dmSans(
                          fontSize: 13, fontWeight: FontWeight.w600, color: textSec,
                        )),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _delete();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text('Удалить', style: GoogleFonts.dmSans(
                          fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white,
                        )),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasContent =>
      _titleCtrl.text.trim().isNotEmpty || _bodyCtrl.text.trim().isNotEmpty;

  void _saveAndPop() {
    if (!_hasContent && widget.note == null) {
      Navigator.pop(context);
      return;
    }
    final state = context.read<AppState>();
    final title = _titleCtrl.text.trim().isEmpty ? 'Без названия' : _titleCtrl.text.trim();
    if (widget.note != null) {
      widget.note!.title = title;
      widget.note!.body = _bodyCtrl.text;
      widget.note!.category = _category;
      widget.note!.colorIndex = _colorIndex;
      widget.note!.createdAt = DateTime.now();
      state.updateNote(widget.note!);
    } else {
      state.addNote(Note(
        id: const Uuid().v4(),
        title: title,
        body: _bodyCtrl.text,
        category: _category,
        colorIndex: _colorIndex,
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.darkMode;
    // Note background: custom color or default
    final Color noteBg = _colorIndex > 0 && _colorIndex <= kNoteColors.length
        ? kNoteColors[_colorIndex - 1]
        : (isDark ? AppColors.darkBg2 : AppColors.lightBg2);
    final text = _colorIndex == 0
        ? (isDark ? AppColors.darkText : AppColors.lightText)
        : AppColors.textColorFor(noteBg);
    final textHint = _colorIndex == 0
        ? (isDark ? AppColors.darkTextDate : const Color(0x6E785028))
        : AppColors.textSecColorFor(noteBg);
    final textSec = _colorIndex == 0
        ? (isDark ? AppColors.darkTextDate : AppColors.lightTextDate)
        : AppColors.textSecColorFor(noteBg);
    final divider = _colorIndex == 0
        ? (isDark ? AppColors.darkDivider : const Color(0x33785028))
        : AppColors.dividerColorFor(noteBg);
    final charCount = _bodyCtrl.text.length;
    final catColor = state.folderColor(_category);
    final editDate = widget.note?.createdAt ?? DateTime.now();

    return Theme(
      data: buildTheme(isDark),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _saveAndPop();
        },
        child: GestureDetector(
          onTap: () { if (_tagMenuOpen) setState(() => _tagMenuOpen = false); },
          child: Scaffold(
          backgroundColor: noteBg,
          appBar: AppBar(
            backgroundColor: noteBg,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded, size: 18, color: text),
              onPressed: _saveAndPop,
            ),
            title: Text('Заметка',
              style: appTitleStyle(state.appFont, size: 15, weight: FontWeight.w600, color: text),
            ),
            actions: [
              CompositedTransformTarget(
                link: _menuLayerLink,
                child: IconButton(
                  icon: Icon(Icons.more_vert_rounded, size: 22, color: text),
                  onPressed: () => _showDropdownMenu(context, isDark),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              // ── Single scroll area — no separate boxes ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title — no decoration, no box
                    Padding(
                      padding: const EdgeInsets.only(right: 110),
                      child: TextField(
                        controller: _titleCtrl,
                        onChanged: (_) => setState(() {}),
                        autofocus: widget.note == null,
                        style: appTitleStyle(state.appFont, size: 24, weight: FontWeight.w600, color: text),
                        decoration: InputDecoration(
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: 'Заголовок',
                          hintStyle: appTitleStyle(state.appFont, size: 24, weight: FontWeight.w600, color: textHint),
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Divider(color: divider, height: 1),
                    const SizedBox(height: 4),
                    // Body — no decoration, fills rest of screen
                    Expanded(
                      child: TextField(
                        controller: _bodyCtrl,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        onChanged: (_) => setState(() {}),
                        style: contentStyle(state.contentFont, size: 15, color: text, height: 1.6),
                        decoration: InputDecoration(
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: 'Текст заметки...',
                          hintStyle: contentStyle(state.contentFont, size: 15, color: textHint, height: 1.4),
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                    // Bottom bar — date + char count
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: divider, width: 0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${formatDate(editDate)}  ·  $charCount симв.',
                            style: GoogleFonts.dmSans(fontSize: 10, color: textSec),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Tag dropdown — top right ──
              Positioned(
                top: 8,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _tagMenuOpen = !_tagMenuOpen),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _category.isEmpty ? '–' : _category,
                              style: GoogleFonts.dmSans(
                                fontSize: 11, fontWeight: FontWeight.w700,
                                color: catColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _tagMenuOpen
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 14, color: catColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_tagMenuOpen)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 150,
                        constraints: const BoxConstraints(maxHeight: 300),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBg : AppColors.lightBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                              width: 0.5),
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
                          children: ['', ...context.read<AppState>().noteFolders].map((tag) {
                            final sel = _category == tag;
                            final tColor = state.folderColor(tag);
                            return GestureDetector(
                              onTap: () => setState(() {
                                _category = tag;
                                _tagMenuOpen = false;
                              }),
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
                                      child: Text(tag.isEmpty ? '–' : tag,
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
