import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _query = '';
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.darkMode;
    final notes = state.filteredNotes(_query);
    final v = state.notesView;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSearchBar(onChanged: (q) => setState(() => _query = q), hint: 'Поиск заметок...'),
              const SizedBox(height: 10),
              CategoryFilterRow(
                categories: state.noteCategories,
                selected: state.notesFilter,
                onSelect: (c) { state.notesFilter = c; state.refresh(); },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        Expanded(
          child: notes.isEmpty
              ? _emptyState(isDark)
              : v == 1
                  ? _listView(context, notes, state)
                  : v == 2
                      ? _MasonryGrid(notes: notes, state: state, onOpenEditor: (n) => _openEditor(context, n))
                      : _compactView(context, notes, state),
        ),
      ],
    );
  }

  Widget _emptyState(bool isDark) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.note_add_outlined, size: 48,
            color: AppColors.terracotta.withValues(alpha: 0.3)),
        const SizedBox(height: 12),
        Text('Нет заметок', style: GoogleFonts.fraunces(
          fontSize: 16,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        )),
      ],
    ),
  );

  Widget _listView(BuildContext context, List<Note> notes, AppState state) {
    if (state.notesSort == 'manual') {
      return ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: notes.length,
        onReorder: (o, n) => state.reorderNote(o, n),
        proxyDecorator: (child, _, __) =>
            Material(color: Colors.transparent, child: child),
        itemBuilder: (ctx, i) => _SwipableNote(
          key: ValueKey(notes[i].id),
          note: notes[i],
          showTag: state.notesFilter == 'Все',
          onTap: () => _openEditor(context, notes[i]),
          onDelete: () => state.deleteNote(notes[i].id),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: notes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _SwipableCard(
        key: ValueKey(notes[i].id),
        itemKey: ValueKey('del-note2-${notes[i].id}'),
        padding: const EdgeInsets.only(bottom: 10),
        onDelete: () => state.deleteNote(notes[i].id),
        child: _NoteCard(
          note: notes[i], showTag: state.notesFilter == 'Все',
          compact: false, grid: false,
          onTap: () => _openEditor(context, notes[i]),
        ),
      ),
    );
  }



  Widget _compactView(BuildContext context, List<Note> notes, AppState state) {
    if (state.notesSort == 'manual') {
      return ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: notes.length,
        onReorder: (o, n) => state.reorderNote(o, n),
        proxyDecorator: (child, _, __) =>
            Material(color: Colors.transparent, child: child),
        itemBuilder: (ctx, i) => _SwipableCard(
          key: ValueKey(notes[i].id),
          itemKey: ValueKey('del-notec-${notes[i].id}'),
          onDelete: () => state.deleteNote(notes[i].id),
          child: _NoteCard(
            note: notes[i], showTag: false,
            compact: true, grid: false,
            onTap: () => _openEditor(context, notes[i]),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: notes.length,
      itemBuilder: (ctx, i) => _SwipableCard(
        key: ValueKey(notes[i].id),
        itemKey: ValueKey('del-notec2-${notes[i].id}'),
        onDelete: () => state.deleteNote(notes[i].id),
        child: _NoteCard(
          note: notes[i], showTag: false,
          compact: true, grid: false,
          onTap: () => _openEditor(context, notes[i]),
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, [Note? note]) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => NoteEditorScreen(note: note),
    ));
  }
}

// ─── Masonry Grid ─────────────────────────────────────────
class _MasonryGrid extends StatefulWidget {
  final List<Note> notes;
  final AppState state;
  final void Function(Note) onOpenEditor;

  const _MasonryGrid({
    required this.notes,
    required this.state,
    required this.onOpenEditor,
  });

  @override
  State<_MasonryGrid> createState() => _MasonryGridState();
}

class _MasonryGridState extends State<_MasonryGrid> {
  final ValueNotifier<String?> _dragState = ValueNotifier(null);

  @override
  void dispose() {
    _dragState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notes = widget.notes;
    final state = widget.state;
    final showTag = state.notesFilter == 'Все';
    final canDrag = state.notesSort == 'manual';

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final colWidth = (constraints.maxWidth - 16 - 16 - 10) / 2;

        Widget buildCard(Note note) {
          final card = Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _GridCard(
              note: note, showTag: showTag, width: colWidth,
              onTap: () => widget.onOpenEditor(note),
              isDark: state.darkMode,
            ),
          );
          if (!canDrag) return KeyedSubtree(key: ValueKey(note.id), child: card);
          return _DraggableMasonryCard<Note>(
            key: ValueKey(note.id),
            itemId: note.id,
            dragState: _dragState,
            feedbackWidth: colWidth,
            onReorder: (fromId, toId) =>
                context.read<AppState>().reorderNoteById(fromId, toId),
            child: card,
          );
        }

        final left  = [for (int i = 0; i < notes.length; i += 2) notes[i]];
        final right = [for (int i = 1; i < notes.length; i += 2) notes[i]];

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
      },
    );
  }
}

// ─── Swipable Card (свайп влево = удалить) ────────────────
class _SwipableCard extends StatelessWidget {
  final Key itemKey;
  final Widget child;
  final VoidCallback onDelete;
  final EdgeInsets padding;

  const _SwipableCard({
    super.key,
    required this.itemKey,
    required this.child,
    required this.onDelete,
    this.padding = EdgeInsets.zero,
  });

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
                    Text('Удалить?', style: GoogleFonts.fraunces(
                      fontSize: 18, fontWeight: FontWeight.w600, color: text,
                    )),
                    const SizedBox(height: 8),
                    Text('Это действие нельзя отменить.', style: GoogleFonts.dmSans(
                      fontSize: 13, color: textSec,
                    )),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx, false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkBg2 : AppColors.lightBg2,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text('Отмена', style: GoogleFonts.dmSans(fontSize: 13, color: textSec, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx, true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade400,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text('Удалить', style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                      ],
                    ),
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
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}


// ─── Swipable Note (list view only) ──────────────────────
class _SwipableNote extends StatelessWidget {
  final Note note;
  final bool showTag;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SwipableNote({
    super.key,
    required this.note,
    required this.showTag,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().darkMode;
    return Dismissible(
      key: ValueKey('dismiss-${note.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => _DeleteConfirmDialog(isDark: isDark, name: note.title),
        ) ?? false;
      },
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
  final VoidCallback onTap;

  const _NoteCard({
    required this.note,
    required this.showTag,
    required this.compact,
    required this.grid,
    required this.onTap,
  });

  @override
  State<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<_NoteCard> {
  bool _bodyExpanded = false;

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final showTag = widget.showTag;
    final compact = widget.compact;
    final grid = widget.grid;
    final onTap = widget.onTap;

    final state = context.watch<AppState>();
    final isDark = state.darkMode;
    final Color cardBg = note.colorIndex > 0 && note.colorIndex <= kNoteColors.length
        ? kNoteColors[note.colorIndex - 1]
        : (isDark ? const Color(0x0DFFFFFF) : const Color(0x40FFFFFF));
    final bool hasCustomColor = note.colorIndex > 0;
    final textColor = hasCustomColor
        ? const Color(0xFF2A1F14)
        : (isDark ? AppColors.darkText : AppColors.lightText);
    final textSec = hasCustomColor
        ? AppColors.lightTextDate
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
                  style: GoogleFonts.fraunces(
                      fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Grid view (view 2) — no dot, no date, title 1 line, body edge-to-edge ──
    if (grid) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                note.title,
                style: GoogleFonts.fraunces(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: textColor, height: 1.25,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (note.body.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  note.body,
                  style: GoogleFonts.dmSans(
                    fontSize: 11, color: textSec, height: 1.4,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ],
            ],
          ),
        ),
      );
    }

    // ── List view (view 1) ──
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasCustomColor ? Colors.transparent : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 6, height: 6,
                          decoration: BoxDecoration(color: catColor, shape: BoxShape.circle)),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(note.title,
                          style: GoogleFonts.fraunces(
                            fontSize: 15, fontWeight: FontWeight.w600,
                            color: textColor, height: 1.25,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (note.body.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(note.body,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: textSec, height: 1.4),
                      maxLines: _bodyExpanded ? 10 : 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    LayoutBuilder(builder: (ctx, constraints) {
                      final tp = TextPainter(
                        text: TextSpan(
                          text: note.body,
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
                ],
              ),
            ),
            // Top right: tag (7 chars max) only — no date
            if (showTag)
              Positioned(
                top: 0, right: 0,
                child: CategoryBadge(
                  label: note.category.length > 7
                      ? note.category.substring(0, 7)
                      : note.category,
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
    final Color cardBg = note.colorIndex > 0 && note.colorIndex <= kNoteColors.length
        ? kNoteColors[note.colorIndex - 1]
        : (isDark ? const Color(0x0DFFFFFF) : const Color(0x40FFFFFF));
    final bool hasCustomColor = note.colorIndex > 0;
    final textColor = hasCustomColor
        ? const Color(0xFF2A1F14)
        : (isDark ? AppColors.darkText : AppColors.lightText);
    final textSec = hasCustomColor
        ? AppColors.lightTextDate
        : (isDark ? AppColors.darkTextDate : AppColors.lightTextDate);
    final borderColor = hasCustomColor
        ? Colors.transparent
        : (isDark ? AppColors.darkDivider : AppColors.lightDivider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: width - 24, // minus padding
              child: Text(
                note.title,
                style: GoogleFonts.fraunces(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: textColor, height: 1.25,
                ),
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
                  style: GoogleFonts.dmSans(
                    fontSize: 11, color: textSec, height: 1.4,
                  ),
                  maxLines: 5,
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

// ─── Draggable Masonry Card ───────────────────────────────
// Передаёт ID — безопасно при любых фильтрах.
// dragTargetId — ValueNotifier, shared между всеми карточками сетки:
//   null = нет активного перетаскивания
//   "fromId->toId" = fromId завис над toId (превью позиции)
class _DraggableMasonryCard<T> extends StatefulWidget {
  final String itemId;
  final void Function(String fromId, String toId) onReorder;
  final ValueNotifier<String?> dragState; // shared notifier
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
        // Используем dragVal из builder — не читаем widget.dragState.value напрямую
        final isMe = _draggingIdFrom(dragVal) == widget.itemId;
        final isTarget = _targetIdFrom(dragVal) == widget.itemId;

        return DragTarget<String>(
          onWillAcceptWithDetails: (details) {
            if (details.data == widget.itemId) return false;
            widget.dragState.value = '${details.data}->${widget.itemId}';
            return true;
          },
          onLeave: (fromId) {
            if (fromId != null) {
              widget.dragState.value = fromId;
            }
          },
          onAcceptWithDetails: (details) {
            // Сначала сбрасываем состояние, потом reorder через postFrame —
            // иначе notifyListeners() внутри reorder делает rebuild до того
            // как dragState стал null, и карточка зависает с opacity:0.
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
              childWhenDragging: _SizedPlaceholder(
                visible: false,
                child: widget.child,
              ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: isMe ? 0.0 : 1.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Превью-слот ПЕРЕД карточкой (появляется когда тянут сюда)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: isTarget
                          ? _SizedPlaceholder(visible: true, child: widget.child)
                          : const SizedBox.shrink(),
                    ),
                    // Сама карточка с подсветкой цели
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

// Placeholder той же высоты что и child — измеряет через GlobalKey
class _SizedPlaceholder extends StatefulWidget {
  final Widget child;
  final bool visible; // true = показать рамку, false = прозрачный

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
        Opacity(
          opacity: 0,
          child: KeyedSubtree(key: _key, child: widget.child),
        ),
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

// ─── Note Editor ─────────────────────────────────────────
// 21 preset note background colors
// Same 21 colors as folder editor palette (sidebar.dart)
const List<Color> kNoteColors = [
  Color(0xFFE53935), Color(0xFFE91E63), Color(0xFF9C27B0),
  Color(0xFF673AB7), Color(0xFF3F51B5), Color(0xFF2196F3),
  Color(0xFF03A9F4), Color(0xFF00BCD4), Color(0xFF009688),
  Color(0xFF4CAF50), Color(0xFF8BC34A), Color(0xFFCDDC39),
  Color(0xFFFFEB3B), Color(0xFFFFC107), Color(0xFFFF9800),
  Color(0xFFFF5722), Color(0xFFD07840), Color(0xFF795548),
  Color(0xFF607D8B), Color(0xFF9E9E9E), Color(0xFF37474F),
];

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
    _category = widget.note?.category ?? widget.initialCategory ?? '';
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
                      if (widget.note != null)
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
              Text('Цвет заметки', style: GoogleFonts.fraunces(
                fontSize: 16, fontWeight: FontWeight.w600, color: text,
              )),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (ctx2, setDialogState) => _buildColorWrapDialog(isDark, setDialogState),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorWrapDialog(bool isDark, StateSetter setDialogState) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(22, (i) {
        final sel = _colorIndex == i;
        if (i == 0) {
          return GestureDetector(
            onTap: () {
              setState(() => _colorIndex = 0);
              setDialogState(() {});
            },
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCardAlt,
                shape: BoxShape.circle,
                border: Border.all(
                  color: sel ? AppColors.terracotta : (isDark ? AppColors.darkDivider : AppColors.lightDivider),
                  width: sel ? 2.5 : 1,
                ),
              ),
              child: Icon(Icons.block_rounded, size: 16,
                  color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
            ),
          );
        }
        final color = kNoteColors[i - 1];
        return GestureDetector(
          onTap: () {
            setState(() => _colorIndex = i);
            setDialogState(() {});
          },
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: sel ? Colors.white : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: sel ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6)] : null,
            ),
            child: sel ? const Icon(Icons.check_rounded, size: 18, color: Colors.white) : null,
          ),
        );
      }),
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
              Text('Удалить заметку?', style: GoogleFonts.fraunces(
                fontSize: 18, fontWeight: FontWeight.w600, color: text,
              )),
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

  Widget _buildColorWrap(bool isDark) {
    // 0 = reset, 1..21 = color
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(22, (i) {
        final sel = _colorIndex == i;
        if (i == 0) {
          return GestureDetector(
            onTap: () => setState(() => _colorIndex = 0),
            child: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCardAlt,
                shape: BoxShape.circle,
                border: Border.all(
                  color: sel ? AppColors.terracotta : (isDark ? AppColors.darkDivider : AppColors.lightDivider),
                  width: sel ? 2 : 1,
                ),
              ),
              child: Icon(Icons.block_rounded, size: 12,
                  color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
            ),
          );
        }
        final color = kNoteColors[i - 1];
        return GestureDetector(
          onTap: () => setState(() => _colorIndex = i),
          child: Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: sel ? Colors.white : Colors.transparent,
                width: 2,
              ),
              boxShadow: sel ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 4)] : null,
            ),
            child: sel ? Icon(Icons.check_rounded, size: 13, color: Colors.white) : null,
          ),
        );
      }),
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
    final text = isDark && _colorIndex == 0 ? AppColors.darkText : const Color(0xFF2A1F14);
    const textHint = Color(0x6E785028);
    final textSec = isDark && _colorIndex == 0 ? AppColors.darkTextDate : AppColors.lightTextDate;
    final divider = isDark && _colorIndex == 0 ? AppColors.darkDivider : const Color(0x33785028);
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
              style: GoogleFonts.fraunces(
                fontSize: 15, fontWeight: FontWeight.w600,
                fontStyle: FontStyle.normal,
                color: text,
              ),
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
                        style: GoogleFonts.fraunces(
                          fontSize: 24, fontWeight: FontWeight.w600, color: text,
                        ),
                        decoration: InputDecoration(
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: 'Заголовок',
                          hintStyle: GoogleFonts.fraunces(
                            fontSize: 24, fontWeight: FontWeight.w600,
                            color: textHint,
                          ),
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
                        style: GoogleFonts.dmSans(fontSize: 15, color: text, height: 1.6),
                        decoration: InputDecoration(
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: 'Текст заметки...',
                          hintStyle: GoogleFonts.dmSans(fontSize: 15, color: textHint),
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

// ─── Delete Confirm Dialog ────────────────────────────────
class _DeleteConfirmDialog extends StatelessWidget {
  final bool isDark;
  final String name;
  const _DeleteConfirmDialog({required this.isDark, required this.name});

  @override
  Widget build(BuildContext context) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Удалить?', style: GoogleFonts.fraunces(
              fontSize: 18, fontWeight: FontWeight.w600, color: text,
            )),
            const SizedBox(height: 8),
            Text(
              name.isEmpty ? 'Без названия' : name,
              style: GoogleFonts.dmSans(fontSize: 13, color: textSec),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
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
                    onTap: () => Navigator.pop(context, true),
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
    );
  }
}