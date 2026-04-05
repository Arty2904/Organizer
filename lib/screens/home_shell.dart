import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../theme/card_colors.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/selection_state.dart';
import '../widgets/sidebar.dart';
import '../theme/font_helper.dart';
import '../screens/notes_screen.dart';
import '../screens/todos_screen.dart';
import '../screens/events_screen.dart';
import '../screens/calendar_screen.dart';



// ─── HomeShell ────────────────────────────────────────────
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _selectionState = SelectionState();
  static const _tabIcons = [
    Icons.calendar_month_outlined, Icons.event_outlined,
    Icons.description_outlined, Icons.checklist_rounded,
  ];
  static const _tabActiveIcons = [
    Icons.calendar_month_rounded, Icons.event_rounded,
    Icons.description_rounded, Icons.checklist_rounded,
  ];

  @override
  void dispose() { _selectionState.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.darkMode;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final text    = isDark ? AppColors.darkText    : AppColors.lightText;
    final textSec = isDark ? AppColors.darkNavDim  : AppColors.lightNavDim;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final accent  = isDark ? AppColors.terracotta  : AppColors.terracottaLight;
    final navBg   = isDark ? AppColors.darkNavBg   : AppColors.lightSurface;
    final tab     = state.currentTab;

    int currentView() {
      switch (tab) {
        case 1: return state.eventsView;
        case 2: return state.notesView;
        case 3: return state.todosView;
        default: return 1;
      }
    }

    void setView(int v) {
      switch (tab) {
        case 1: state.eventsView = v; break;
        case 2: state.notesView = v; break;
        case 3: state.todosView = v; break;
      }
      state.refresh();
    }

    List<String> allIds() {
      switch (tab) {
        case 1: return state.events.map((e) => e.id).toList();
        case 2: return state.notes.map((n) => n.id).toList();
        case 3: return state.todos.map((t) => t.id).toList();
        default: return [];
      }
    }

    List<String> folders() {
      switch (tab) {
        case 1: return state.eventFolders;
        case 2: return state.noteFolders;
        case 3: return state.todoFolders;
        default: return [];
      }
    }

    return SelectionScope(
      state: _selectionState,
      child: ListenableBuilder(
        listenable: _selectionState,
        builder: (context, _) {
          final inSelect   = _selectionState.active;
          final selectedIds = _selectionState.selected;
          final ids        = allIds();
          final allSel     = ids.isNotEmpty && ids.every(selectedIds.contains);

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
            child: Scaffold(
              key: _scaffoldKey,
              resizeToAvoidBottomInset: false,
              backgroundColor: isDark ? AppColors.darkBg2 : AppColors.lightBg2,
              drawer: const AppSidebar(),
              appBar: AppBar(
                backgroundColor: surface,
                elevation: 0,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                leading: inSelect
                    ? IconButton(
                        icon: Icon(Icons.close_rounded, size: 20, color: text),
                        onPressed: _selectionState.exit,
                      )
                    : IconButton(
                        icon: _HamburgerIcon(isDark: isDark),
                        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                title: inSelect
                    ? Text(
                        selectedIds.isEmpty ? state.s.select : '${selectedIds.length} ${state.s.select.toLowerCase()}',
                        style: appTitleStyle(state.appFont, size: 15, weight: FontWeight.w600, color: text),
                      )
                    : Text(
                        [state.s.calendar, state.s.events, state.s.notes, state.s.todos][tab],
                        style: appTitleStyle(state.appFont, size: 15, weight: FontWeight.w600, color: text),
                      ),
                centerTitle: true,
                actions: [
                  if (tab != 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: inSelect
                          ? GestureDetector(
                              onTap: () => allSel
                                  ? _selectionState.deselectAll()
                                  : _selectionState.selectAll(ids),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: allSel
                                      ? AppColors.terracotta.withValues(alpha: 0.15)
                                      : (isDark ? AppColors.darkCard : AppColors.lightCardAlt),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.checklist_rounded, size: 18,
                                    color: allSel
                                        ? AppColors.terracotta
                                        : AppColors.terracotta.withValues(alpha: 0.5)),
                              ),
                            )
                          : _OptionsButton(
                              isDark: isDark,
                              tab: tab,
                              currentView: currentView(),
                              onViewChanged: setView,
                              onEnterSelect: _selectionState.enter,
                            ),
                    ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Divider(color: divider, height: 1),
                ),
              ),
              body: SafeArea(
                bottom: false,
                child: GestureDetector(
                  onTap: inSelect ? _selectionState.exit : null,
                  behavior: HitTestBehavior.translucent,
                  child: IndexedStack(
                    index: tab,
                    children: const [
                      CalendarScreen(),
                      EventsScreen(),
                      NotesScreen(),
                      TodosScreen(),
                    ],
                  ),
                ),
              ),
              floatingActionButton: (!inSelect)
                  ? SizedBox(
                      width: 44, height: 44,
                      child: FloatingActionButton(
                        onPressed: () => _handleFab(context, state),
                        backgroundColor: accent,
                        elevation: 6,
                        shape: const CircleBorder(),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                      ),
                    )
                  : null,
              bottomNavigationBar: inSelect
                  ? _BulkActionBar(
                      isDark: isDark,
                      tab: tab,
                      selectedIds: selectedIds,
                      folders: folders(),
                      onDone: _selectionState.exit,
                    )
                  : _BottomNav(
                      isDark: isDark, navBg: navBg, divider: divider,
                      accent: accent, textSec: textSec, tab: tab,
                      appFont: state.appFont,
                      s: state.s,
                      onTabChanged: (i) { state.currentTab = i; state.refresh(); },
                    ),
            ),
          );
        },
      ),
    );
  }

  void _handleFab(BuildContext context, AppState state) {
    final notesInit  = state.notesFilter  == state.s.all ? '' : state.notesFilter;
    final todosInit  = state.todosFilter  == state.s.all ? '' : state.todosFilter;
    final eventsInit = state.eventsFilter == state.s.all ? '' : state.eventsFilter;

    switch (state.currentTab) {
      case 0:
        showDialog(context: context, barrierColor: Colors.black.withValues(alpha: 0.4),
            builder: (_) => EventEditorDialog());
        break;
      case 1:
        showDialog(context: context, barrierColor: Colors.black.withValues(alpha: 0.4),
            builder: (_) => EventEditorDialog(initialCategory: eventsInit));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => NoteEditorScreen(initialCategory: notesInit)));
        break;
      case 3:
        showDialog(context: context, barrierColor: Colors.black.withValues(alpha: 0.4),
            builder: (_) => TodoEditorDialog(initialCategory: todosInit));
        break;
    }
  }
}

// ─── Bottom Nav ───────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final bool isDark;
  final Color navBg, divider, accent, textSec;
  final int tab;
  final String appFont;
  final ValueChanged<int> onTabChanged;
  final S s;

  static const _icons = [
    Icons.calendar_month_outlined, Icons.event_outlined,
    Icons.description_outlined, Icons.checklist_rounded,
  ];
  static const _activeIcons = [
    Icons.calendar_month_rounded, Icons.event_rounded,
    Icons.description_rounded, Icons.checklist_rounded,
  ];

  const _BottomNav({
    required this.isDark, required this.navBg, required this.divider,
    required this.accent, required this.textSec, required this.tab,
    required this.appFont, required this.onTabChanged, required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: navBg,
        border: Border(top: BorderSide(color: divider, width: 0.5)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(4, (i) {
              final active = tab == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTabChanged(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(active ? _activeIcons[i] : _icons[i], size: 22,
                          color: active ? accent : textSec),
                      const SizedBox(height: 2),
                      Text([s.calendar, s.events, s.notes, s.todos][i], style: appTitleStyle(appFont,
                        size: 9.5,
                        weight: active ? FontWeight.w600 : FontWeight.w400,
                        color: active ? AppColors.terracotta : textSec,
                      )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}


// ─── Toast helper ─────────────────────────────────────────
void _showFolderToast(BuildContext context, String folderName, bool isDark) {
  final overlay = Overlay.of(context);
  final label = folderName.isEmpty ? context.read<AppState>().s.noCategory : folderName;
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _FolderToast(
      label: label,
      isDark: isDark,
      onDismiss: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _FolderToast extends StatefulWidget {
  final String label;
  final bool isDark;
  final VoidCallback onDismiss;
  const _FolderToast({required this.label, required this.isDark, required this.onDismiss});

  @override
  State<_FolderToast> createState() => _FolderToastState();
}

class _FolderToastState extends State<_FolderToast> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 3), _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    _ctrl.reverse().then((_) { if (mounted) widget.onDismiss(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      left: 0, right: 0,
      child: Center(
        child: FadeTransition(
          opacity: _anim,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(_anim),
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFF2E2620) : const Color(0xFF3D2B1F),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_rounded, size: 15, color: AppColors.terracotta),
                    const SizedBox(width: 8),
                    Text(
                      '${context.read<AppState>().s.movedTo} «${widget.label}»',
                      style: appTitleStyle(context.read<AppState>().appFont, size: 13, weight: FontWeight.w500, color: Colors.white, fontStyle: null),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Bulk Action Bar ──────────────────────────────────────
class _BulkActionBar extends StatelessWidget {
  final bool isDark;
  final int tab;
  final Set<String> selectedIds;
  final List<String> folders;
  final VoidCallback onDone;

  const _BulkActionBar({
    required this.isDark, required this.tab,
    required this.selectedIds, required this.folders, required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final bg      = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final textSec = isDark ? AppColors.darkTextBody : AppColors.lightTextBody;
    final enabled = selectedIds.isNotEmpty;
    final s = context.watch<AppState>().s;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: divider, width: 0.5)),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
          blurRadius: 12, offset: const Offset(0, -3),
        )],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            Expanded(child: _BulkBtn(
              icon: Icons.delete_outline_rounded, label: s.delete,
              color: enabled ? Colors.red.shade400 : textSec,
              enabled: enabled, onTap: () => _confirmDelete(context),
            )),
            Expanded(child: _BulkBtn(
              icon: Icons.drive_file_move_outline, label: s.move,
              color: enabled ? AppColors.terracotta : textSec,
              enabled: enabled, onTap: () => _showMoveSheet(context),
            )),
            Expanded(child: _BulkBtn(
              icon: Icons.palette_outlined, label: s.color,
              color: enabled ? AppColors.terracotta : textSec,
              enabled: enabled, onTap: () => _showColorSheet(context),
            )),
          ]),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    if (selectedIds.isEmpty) return;
    final state   = context.read<AppState>();
    final isDarkL = state.darkMode;
    final bg      = isDarkL ? AppColors.darkSurface : AppColors.lightSurface;
    final text    = isDarkL ? AppColors.darkText    : AppColors.lightText;
    final textSec = isDarkL ? AppColors.darkTextBody : AppColors.lightTextBody;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => Dialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${context.read<AppState>().s.delete} ${selectedIds.length} ${context.read<AppState>().s.deleteN}',
                  style: appTitleStyle(context.read<AppState>().appFont, size: 18, weight: FontWeight.w600, color: text)),
              const SizedBox(height: 8),
              Text(context.read<AppState>().s.deleteCannotUndo,
                  style: appTitleStyle(context.read<AppState>().appFont, size: 13, color: textSec)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isDarkL ? AppColors.darkBg2 : AppColors.lightBg2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(context.read<AppState>().s.cancel, style: appTitleStyle(
                        context.read<AppState>().appFont, size: 13, weight: FontWeight.w600, color: textSec)),
                  ),
                )),
                const SizedBox(width: 10),
                Expanded(child: GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    final ids = Set<String>.from(selectedIds);
                    if (tab == 1) state.bulkDeleteEvents(ids);
                    else if (tab == 2) state.bulkDeleteNotes(ids);
                    else state.bulkDeleteTodos(ids);
                    onDone();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: Text(context.read<AppState>().s.delete, style: appTitleStyle(
                        context.read<AppState>().appFont, size: 13, weight: FontWeight.w700, color: Colors.white)),
                  ),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoveSheet(BuildContext context) {
    if (selectedIds.isEmpty || folders.isEmpty) return;
    final state      = context.read<AppState>();
    final isDarkL    = state.darkMode;
    final bg         = isDarkL ? AppColors.darkSurface : AppColors.lightSurface;
    final text       = isDarkL ? AppColors.darkText    : AppColors.lightText;
    final dividerCol = isDarkL ? AppColors.darkDivider : AppColors.lightDivider;

    void doMove(String cat) {
      final ids = Set<String>.from(selectedIds);
      if (tab == 1) state.bulkMoveEvents(ids, cat);
      else if (tab == 2) state.bulkMoveNotes(ids, cat);
      else state.bulkMoveTodos(ids, cat);
      onDone();
      _showFolderToast(context, cat, isDarkL);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4,
            decoration: BoxDecoration(color: dividerCol, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(context.read<AppState>().s.moveToFolder,
              style: appTitleStyle(context.read<AppState>().appFont, size: 16, weight: FontWeight.w600, color: text)),
          ),
          const SizedBox(height: 6),
          _FolderTile(
            label: '— Без категории',
            color: isDarkL ? AppColors.darkTextDate : AppColors.lightTextDate,
            isDark: isDarkL,
            onTap: () { Navigator.pop(ctx); doMove(''); },
          ),
          ...folders.map((f) => _FolderTile(
            label: f, color: state.folderColor(f), isDark: isDarkL,
            onTap: () { Navigator.pop(ctx); doMove(f); },
          )),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showColorSheet(BuildContext context) {
    if (selectedIds.isEmpty) return;
    final state      = context.read<AppState>();
    final isDarkL    = state.darkMode;
    final bg         = isDarkL ? AppColors.darkSurface : AppColors.lightSurface;
    final text       = isDarkL ? AppColors.darkText    : AppColors.lightText;
    final dividerCol = isDarkL ? AppColors.darkDivider : AppColors.lightDivider;

    const colors = kCardColors;

    void doColor(int idx) {
      final ids = Set<String>.from(selectedIds);
      if (tab == 1) state.bulkColorEvents(ids, idx);
      else if (tab == 2) state.bulkColorNotes(ids, idx);
      else state.bulkColorTodos(ids, idx);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4,
                decoration: BoxDecoration(color: dividerCol, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 14),
              Text(state.s.cardColor,
                style: appTitleStyle(state.appFont, size: 16, weight: FontWeight.w600, color: text)),
              const SizedBox(height: 14),
              Wrap(spacing: 10, runSpacing: 10,
                children: List.generate(22, (i) {
                  if (i == 0) {
                    return GestureDetector(
                      onTap: () { Navigator.pop(ctx); doColor(0); },
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: isDarkL ? AppColors.darkCard : AppColors.lightCardAlt,
                          shape: BoxShape.circle,
                          border: Border.all(color: dividerCol, width: 1),
                        ),
                        child: Icon(Icons.block_rounded, size: 16, color: dividerCol),
                      ),
                    );
                  }
                  return GestureDetector(
                    onTap: () { Navigator.pop(ctx); doColor(i); },
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(color: colors[i - 1], shape: BoxShape.circle),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulkBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _BulkBtn({required this.icon, required this.label,
      required this.color, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 22, color: color),
      const SizedBox(height: 4),
      Text(label, style: appTitleStyle(context.watch<AppState>().appFont,
          size: 11, weight: FontWeight.w500, color: color)),
    ]),
  );
}

class _FolderTile extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _FolderTile({required this.label, required this.color,
      required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final appFont = context.watch<AppState>().appFont;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(children: [
          Container(width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text(label, style: appTitleStyle(appFont, size: 14, color: text)),
        ]),
      ),
    );
  }
}

// ─── Hamburger Icon ────────────────────────────────────────
class _HamburgerIcon extends StatelessWidget {
  final bool isDark;
  const _HamburgerIcon({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkHamBg : AppColors.lightHamBg;
    final bd = isDark ? AppColors.darkHamBd : AppColors.lightHamBd;
    final sp = isDark ? AppColors.darkHamSp : AppColors.lightHamSp;
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(11),
        border: Border.all(color: bd, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bar(sp, 16), const SizedBox(height: 4),
            _bar(sp, 11), const SizedBox(height: 4),
            _bar(sp, 7),
          ],
        ),
      ),
    );
  }

  Widget _bar(Color color, double width) => Container(
    width: width, height: 2,
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1)),
  );
}

// ─── Options Button ────────────────────────────────────────
class _OptionsButton extends StatefulWidget {
  final bool isDark;
  final int tab;
  final int currentView;
  final ValueChanged<int> onViewChanged;
  final VoidCallback onEnterSelect;

  const _OptionsButton({
    required this.isDark, required this.tab, required this.currentView,
    required this.onViewChanged, required this.onEnterSelect,
  });

  @override
  State<_OptionsButton> createState() => _OptionsButtonState();
}

class _OptionsButtonState extends State<_OptionsButton> {
  OverlayEntry? _entry;
  final LayerLink _link = LayerLink();

  void _close() { _entry?.remove(); _entry = null; }

  void _open(BuildContext context, AppState state) {
    if (_entry != null) { _close(); return; }
    final currentSort = widget.tab == 1 ? state.eventsSort
        : widget.tab == 2 ? state.notesSort : state.todosSort;

    _entry = OverlayEntry(builder: (_) => _OptionsDropDown(
      link: _link,
      isDark: widget.isDark,
      currentView: widget.currentView,
      currentSort: currentSort,
      onViewChanged: (v) { widget.onViewChanged(v); _close(); },
      onSortChanged: (s) {
        if (widget.tab == 1) state.eventsSort = s;
        else if (widget.tab == 2) state.notesSort = s;
        else state.todosSort = s;
        state.refresh();
        _close();
      },
      onEnterSelect: () { widget.onEnterSelect(); _close(); },
      onDismiss: _close,
    ));
    Overlay.of(context).insert(_entry!);
  }

  @override
  void dispose() { _close(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state  = context.watch<AppState>();
    final cardBg = widget.isDark ? AppColors.darkCard : AppColors.lightCardAlt;

    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        onTap: () => _open(context, state),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.more_vert_rounded, size: 18,
              color: AppColors.terracotta.withValues(alpha: 0.7)),
        ),
      ),
    );
  }
}

// ─── Compact Drop-Down ─────────────────────────────────────
class _OptionsDropDown extends StatelessWidget {
  final LayerLink link;
  final bool isDark;
  final int currentView;
  final String currentSort;
  final ValueChanged<int> onViewChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onEnterSelect;
  final VoidCallback onDismiss;

  const _OptionsDropDown({
    required this.link, required this.isDark, required this.currentView,
    required this.currentSort, required this.onViewChanged,
    required this.onSortChanged, required this.onEnterSelect, required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final bg      = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final text    = isDark ? AppColors.darkText    : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextBody : AppColors.lightTextBody;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final state   = context.watch<AppState>();

    final headerStyle = appTitleStyle(
      state.appFont,
      size: 9, weight: FontWeight.w700, color: AppColors.terracotta.withValues(alpha: 0.8),
    );

    Widget item(IconData icon, String label, bool sel, VoidCallback onTap) =>
        GestureDetector(
          onTap: onTap,
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              Icon(icon, size: 14, color: sel ? AppColors.terracotta : textSec),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: appTitleStyle(
                state.appFont,
                size: 12,
                weight: sel ? FontWeight.w600 : FontWeight.w400,
                color: sel ? AppColors.terracotta : text,
              ))),
              if (sel) Icon(Icons.check_rounded, size: 12, color: AppColors.terracotta),
            ]),
          ),
        );

    Widget header(String label) => Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
      child: Text(label, style: headerStyle),
    );

    return Stack(children: [
      Positioned.fill(child: GestureDetector(
        onTap: onDismiss, behavior: HitTestBehavior.translucent,
        child: const SizedBox.expand(),
      )),
      CompositedTransformFollower(
        link: link,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomRight,
        followerAnchor: Alignment.topRight,
        offset: const Offset(0, 6),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 195,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                width: 0.5,
              ),
              boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                blurRadius: 16, offset: const Offset(0, 4),
              )],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header(state.s.sectionDisplay),
                item(Icons.view_agenda_rounded,  state.s.viewList,    currentView == 1, () => onViewChanged(1)),
                item(Icons.grid_view_rounded,    state.s.viewGrid,    currentView == 2, () => onViewChanged(2)),
                item(Icons.view_headline_rounded,state.s.viewCompact, currentView == 3, () => onViewChanged(3)),
                Divider(height: 1, color: divider),
                header(state.s.sectionSort),
                item(Icons.calendar_today_rounded,  state.s.sortDate, currentSort == 'date',   () => onSortChanged('date')),
                item(Icons.drag_indicator_rounded,  state.s.sortManual, currentSort == 'manual', () => onSortChanged('manual')),
                Divider(height: 1, color: divider),
                item(Icons.checklist_rounded, state.s.select, false, onEnterSelect),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    ]);
  }
}
