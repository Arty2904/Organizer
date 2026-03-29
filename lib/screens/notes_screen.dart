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
                categories: AppState.noteCategories,
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
                      ? _gridView(context, notes, state)
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
        itemBuilder: (ctx, i) => Padding(
          key: ValueKey(notes[i].id),
          padding: const EdgeInsets.only(bottom: 10),
          child: _NoteCard(
            note: notes[i], showTag: state.notesFilter == 'Все',
            compact: false, grid: false,
            onTap: () => _openEditor(context, notes[i]),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: notes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _NoteCard(
        note: notes[i], showTag: state.notesFilter == 'Все',
        compact: false, grid: false,
        onTap: () => _openEditor(context, notes[i]),
      ),
    );
  }

  Widget _gridView(BuildContext context, List<Note> notes, AppState state) {
    final showTag = state.notesFilter == 'Все';
    final left = [for (int i = 0; i < notes.length; i += 2) notes[i]];
    final right = [for (int i = 1; i < notes.length; i += 2) notes[i]];

    return LayoutBuilder(
      builder: (ctx, constraints) {
        // Calculate exact card width: screen - horizontal padding - gap between cols
        final colWidth = (constraints.maxWidth - 16 - 16 - 10) / 2;

        Widget buildCard(Note note) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _GridCard(
            note: note,
            showTag: showTag,
            width: colWidth,
            onTap: () => _openEditor(context, note),
            isDark: state.darkMode,
          ),
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(children: left.map(buildCard).toList()),
              const SizedBox(width: 10),
              Column(children: right.map(buildCard).toList()),
            ],
          ),
        );
      },
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
        itemBuilder: (ctx, i) => _NoteCard(
          key: ValueKey(notes[i].id),
          note: notes[i], showTag: false,
          compact: true, grid: false,
          onTap: () => _openEditor(context, notes[i]),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: notes.length,
      itemBuilder: (ctx, i) => _NoteCard(
        note: notes[i], showTag: false,
        compact: true, grid: false,
        onTap: () => _openEditor(context, notes[i]),
      ),
    );
  }

  void _openEditor(BuildContext context, [Note? note]) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => NoteEditorScreen(note: note),
    ));
  }
}

// ─── Note Card ────────────────────────────────────────────
class _NoteCard extends StatelessWidget {
  final Note note;
  final bool showTag;
  final bool compact;
  final bool grid;
  final VoidCallback onTap;

  const _NoteCard({
    super.key,
    required this.note,
    required this.showTag,
    required this.compact,
    required this.grid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.darkMode;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final catColor = AppColors.categoryColor(note.category);

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
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
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
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            width: 0.5,
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
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
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
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.lightDivider;

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

// ─── Note Editor ─────────────────────────────────────────
class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _bodyCtrl;
  late String _category;
  bool _tagMenuOpen = false;

  static const _allTags = [
    'Работа', 'Личное', 'Идеи', 'Путешествия', 'Рецепты',
    'Финансы', 'Здоровье', 'Учёба', 'Проекты', 'Разное',
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note?.title ?? '');
    _bodyCtrl = TextEditingController(text: widget.note?.body ?? '');
    _category = widget.note?.category ?? 'Личное';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final state = context.read<AppState>();
    final title = _titleCtrl.text.trim().isEmpty
        ? 'Без названия'
        : _titleCtrl.text.trim();
    if (widget.note != null) {
      widget.note!.title = title;
      widget.note!.body = _bodyCtrl.text;
      widget.note!.category = _category;
      widget.note!.createdAt = DateTime.now();
      state.updateNote(widget.note!);
    } else {
      state.addNote(Note(
        id: const Uuid().v4(),
        title: title,
        body: _bodyCtrl.text,
        category: _category,
      ));
    }
    Navigator.pop(context);
  }

  void _delete() {
    if (widget.note != null) {
      context.read<AppState>().deleteNote(widget.note!.id);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.darkMode;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final charCount = _bodyCtrl.text.length;
    final catColor = AppColors.categoryColor(_category);
    final editDate = widget.note?.createdAt ?? DateTime.now();

    return Theme(
      data: buildTheme(isDark),
      child: GestureDetector(
        onTap: () { if (_tagMenuOpen) setState(() => _tagMenuOpen = false); },
        child: Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: surface,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded, size: 18, color: text),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Органайзер',
              style: GoogleFonts.fraunces(
                fontSize: 17, fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic, color: text,
              ),
            ),
            actions: [
              if (widget.note != null)
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded,
                      color: Colors.red.withValues(alpha: 0.7), size: 20),
                  onPressed: _delete,
                ),
              TextButton(
                onPressed: _save,
                child: Text('ГОТОВО',
                  style: GoogleFonts.dmSans(
                    fontSize: 12, fontWeight: FontWeight.w800,
                    color: AppColors.terracotta,
                  ),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              // ── Main content ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Padding(
                      padding: const EdgeInsets.only(right: 110),
                      child: TextField(
                        controller: _titleCtrl,
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.fraunces(
                          fontSize: 24, fontWeight: FontWeight.w600, color: text,
                        ),
                        decoration: InputDecoration(
                          filled: false, border: InputBorder.none,
                          hintText: 'Заголовок',
                          hintStyle: GoogleFonts.fraunces(
                            fontSize: 24, fontWeight: FontWeight.w600,
                            color: textSec.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                    // Body
                    Expanded(
                      child: TextField(
                        controller: _bodyCtrl,
                        maxLines: null,
                        expands: true,
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.dmSans(
                            fontSize: 15, color: text, height: 1.6),
                        decoration: InputDecoration(
                          filled: false, border: InputBorder.none,
                          hintText: 'Текст заметки...',
                          hintStyle: GoogleFonts.dmSans(
                            fontSize: 15,
                            color: textSec.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                    // Bottom bar — date + char count (bottom right)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                            top: BorderSide(color: divider, width: 0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${formatDate(editDate)}  ·  $charCount симв.',
                            style: GoogleFonts.dmSans(
                                fontSize: 10, color: textSec),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Tag dropdown — top right ──
              Positioned(
                top: 12,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Tag chip button
                    GestureDetector(
                      onTap: () =>
                          setState(() => _tagMenuOpen = !_tagMenuOpen),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _category,
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
                    // Dropdown list with scroll, 10 tags
                    if (_tagMenuOpen)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 150,
                        constraints: const BoxConstraints(maxHeight: 300),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: divider, width: 0.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.4 : 0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListView(
                          padding:
                              const EdgeInsets.symmetric(vertical: 6),
                          shrinkWrap: true,
                          children: _allTags.map((tag) {
                            final sel = _category == tag;
                            final tColor = AppColors.categoryColor(tag);
                            return GestureDetector(
                              onTap: () => setState(() {
                                _category = tag;
                                _tagMenuOpen = false;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 9),
                                color: sel
                                    ? tColor.withValues(alpha: 0.1)
                                    : Colors.transparent,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 7, height: 7,
                                      decoration: BoxDecoration(
                                        color: tColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(tag,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          fontWeight: sel
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                          color: sel ? tColor : text,
                                        ),
                                      ),
                                    ),
                                    if (sel)
                                      Icon(Icons.check_rounded,
                                          size: 14, color: tColor),
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
    );
  }
}
