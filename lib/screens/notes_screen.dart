import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
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
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Заметки',
                style: GoogleFonts.fraunces(
                  fontSize: 26, fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${notes.length} заметок',
                style: GoogleFonts.dmSans(
                  fontSize: 11, fontStyle: FontStyle.italic,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 10),
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
                  ? _listView(context, notes, state, isDark)
                  : v == 2
                      ? _gridView(context, notes, state, isDark)
                      : _compactView(context, notes, state, isDark),
        ),
      ],
    );
  }

  Widget _emptyState(bool isDark) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.note_add_outlined, size: 48, color: AppColors.terracotta.withOpacity(0.3)),
        const SizedBox(height: 12),
        Text('Нет заметок', style: GoogleFonts.fraunces(
          fontSize: 16, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        )),
      ],
    ),
  );

  Widget _listView(BuildContext context, List<Note> notes, AppState state, bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: notes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _NoteCard(
        note: notes[i],
        showTag: state.notesFilter == 'Все',
        compact: false,
        onTap: () => _openEditor(context, notes[i]),
      ),
    );
  }

  Widget _gridView(BuildContext context, List<Note> notes, AppState state, bool isDark) {
    return MasonryGridView.count(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      itemCount: notes.length,
      itemBuilder: (ctx, i) => _NoteCard(
        note: notes[i],
        showTag: state.notesFilter == 'Все',
        compact: false,
        grid: true,
        onTap: () => _openEditor(context, notes[i]),
      ),
    );
  }

  Widget _compactView(BuildContext context, List<Note> notes, AppState state, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: notes.length,
      itemBuilder: (ctx, i) => _NoteCard(
        note: notes[i],
        showTag: false,
        compact: true,
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
    required this.note,
    required this.showTag,
    required this.compact,
    this.grid = false,
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

    if (compact) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(color: catColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  note.title,
                  style: GoogleFonts.fraunces(
                    fontSize: 13, fontWeight: FontWeight.w600, color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formatDate(note.createdAt),
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
        padding: EdgeInsets.all(grid ? 12 : 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(grid ? 16 : 18),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            width: 0.5,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(color: catColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          note.title,
                          style: GoogleFonts.fraunces(
                            fontSize: grid ? 13 : 15,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (note.body.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      note.body,
                      style: GoogleFonts.dmSans(
                        fontSize: grid ? 11 : 12,
                        color: textSec,
                        height: 1.4,
                      ),
                      maxLines: grid ? 4 : null,
                      overflow: grid ? TextOverflow.ellipsis : null,
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              top: 0, right: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (showTag) CategoryBadge(label: note.category),
                  const SizedBox(height: 4),
                  Text(
                    formatDate(note.createdAt),
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
    if (widget.note != null) {
      widget.note!.title = _titleCtrl.text.trim().isEmpty ? 'Без названия' : _titleCtrl.text.trim();
      widget.note!.body = _bodyCtrl.text;
      widget.note!.category = _category;
      state.updateNote(widget.note!);
    } else {
      state.addNote(Note(
        id: const Uuid().v4(),
        title: _titleCtrl.text.trim().isEmpty ? 'Без названия' : _titleCtrl.text.trim(),
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

    return Theme(
      data: buildTheme(isDark),
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: surface,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, size: 18, color: text),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Органайзер',
            style: GoogleFonts.fraunces(
              fontSize: 17, fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic, color: text,
            ),
          ),
          actions: [
            if (widget.note != null)
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: Colors.red.withOpacity(0.7), size: 20),
                onPressed: _delete,
              ),
            TextButton(
              onPressed: _save,
              child: Text(
                'ГОТОВО',
                style: GoogleFonts.dmSans(
                  fontSize: 12, fontWeight: FontWeight.w800,
                  color: AppColors.terracotta,
                ),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: AppState.noteCategories.skip(1).map((cat) {
                    final sel = _category == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _category = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.categoryColor(cat) : (isDark ? AppColors.darkCard : AppColors.lightCardAlt),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            cat,
                            style: GoogleFonts.dmSans(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: sel ? Colors.white : textSec,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleCtrl,
                style: GoogleFonts.fraunces(
                  fontSize: 24, fontWeight: FontWeight.w600, color: text,
                ),
                decoration: InputDecoration(
                  filled: false,
                  border: InputBorder.none,
                  hintText: 'Заголовок',
                  hintStyle: GoogleFonts.fraunces(
                    fontSize: 24, fontWeight: FontWeight.w600,
                    color: textSec.withOpacity(0.4),
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _bodyCtrl,
                  maxLines: null,
                  expands: true,
                  style: GoogleFonts.dmSans(fontSize: 15, color: text, height: 1.6),
                  decoration: InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    hintText: 'Текст заметки...',
                    hintStyle: GoogleFonts.dmSans(
                      fontSize: 15, color: textSec.withOpacity(0.4),
                    ),
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
