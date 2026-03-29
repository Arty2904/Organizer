import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/sidebar.dart';
import '../screens/notes_screen.dart';
import '../screens/todos_screen.dart';
import '../screens/events_screen.dart';
import '../screens/calendar_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _tabLabels = ['Календарь', 'События', 'Заметки', 'Задачи'];
  static const _tabIcons = [
    Icons.calendar_month_outlined,
    Icons.event_outlined,
    Icons.description_outlined,
    Icons.checklist_rounded,
  ];
  static const _tabActiveIcons = [
    Icons.calendar_month_rounded,
    Icons.event_rounded,
    Icons.description_rounded,
    Icons.checklist_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.darkMode;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final textSec = isDark ? AppColors.darkNavDim : AppColors.lightNavDim;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final accent = isDark ? AppColors.terracotta : AppColors.terracottaLight;
    final navBg = isDark ? AppColors.darkNavBg : AppColors.lightSurface;
    final tab = state.currentTab;

    // Current view mode for the active tab
    int currentView() {
      switch (tab) {
        case 0: return 1; // calendar
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: isDark ? AppColors.darkBg2 : AppColors.lightBg2,
        drawer: const AppSidebar(),
        appBar: AppBar(
          backgroundColor: surface,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: _HamburgerIcon(isDark: isDark),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          title: Text(
            _tabLabels[tab],
            style: GoogleFonts.fraunces(
              fontSize: 15, fontWeight: FontWeight.w600,
              fontStyle: FontStyle.normal, color: text,
            ),
          ),
          centerTitle: true,
          actions: [
            if (tab != 0)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (tab == 2 || tab == 3)
                      _FilterButton(isDark: isDark, text: text, textSec: textSec, surface: surface, tab: tab),
                    const SizedBox(width: 4),
                    ViewSwitcher(current: currentView(), onChanged: setView),
                  ],
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
        floatingActionButton: tab != 0
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
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: navBg,
            border: Border(top: BorderSide(color: divider, width: 0.5)),
          ),
          child: SafeArea(
            child: SizedBox(
              height: 56,
              child: Row(
                children: List.generate(4, (i) {
                  final active = state.currentTab == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        state.currentTab = i;
                        state.refresh();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            active ? _tabActiveIcons[i] : _tabIcons[i],
                            size: 22,
                            color: active ? accent : textSec,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _tabLabels[i],
                            style: GoogleFonts.dmSans(
                              fontSize: 9.5,
                              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                              color: active ? AppColors.terracotta : textSec,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleFab(BuildContext context, AppState state) {
    // Pass the active filter as initial category (null if 'Все')
    final notesInit  = state.notesFilter  == 'Все' ? '' : state.notesFilter;
    final todosInit  = state.todosFilter  == 'Все' ? '' : state.todosFilter;
    final eventsInit = state.eventsFilter == 'Все' ? '' : state.eventsFilter;

    switch (state.currentTab) {
      case 1:
        showDialog(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.4),
          builder: (_) => EventEditorDialog(initialCategory: eventsInit),
        );
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => NoteEditorScreen(initialCategory: notesInit),
        ));
        break;
      case 3:
        showDialog(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.4),
          builder: (_) => TodoEditorDialog(initialCategory: todosInit),
        );
        break;
    }
  }
}

// ─── Hamburger Icon ────────────────────────────────────────
class _HamburgerIcon extends StatelessWidget {
  final bool isDark;
  const _HamburgerIcon({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg  = isDark ? AppColors.darkHamBg  : AppColors.lightHamBg;
    final bd  = isDark ? AppColors.darkHamBd  : AppColors.lightHamBd;
    final sp  = isDark ? AppColors.darkHamSp  : AppColors.lightHamSp;
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: bd, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _bar(sp, 15),
          const SizedBox(height: 4),
          _bar(sp, 10),
          const SizedBox(height: 4),
          _bar(sp, 15),
        ],
      ),
    );
  }

  Widget _bar(Color color, double width) => Container(
    width: width, height: 2,
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1)),
  );
}

// ─── Filter Button ─────────────────────────────────────────
class _FilterButton extends StatelessWidget {
  final bool isDark;
  final Color text;
  final Color textSec;
  final Color surface;
  final int tab; // 2=notes, 3=todos
  const _FilterButton({
    required this.isDark,
    required this.text,
    required this.textSec,
    required this.surface,
    required this.tab,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCardAlt;
    final currentSort = tab == 3 ? state.todosSort : state.notesSort;
    final isManual = currentSort == 'manual';

    return GestureDetector(
      onTapDown: (details) async {
        final RenderBox button = context.findRenderObject() as RenderBox;
        final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
        final RelativeRect position = RelativeRect.fromRect(
          Rect.fromPoints(
            button.localToGlobal(Offset(0, button.size.height + 4), ancestor: overlay),
            button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
          ),
          Offset.zero & overlay.size,
        );
        final selected = await showMenu<String>(
          context: context,
          color: surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          position: position,
          items: [
            _menuItem('date', 'По дате', Icons.calendar_today_rounded,
                currentSort == 'date', isDark, text, textSec, surface),
            _menuItem('manual', 'Вручную', Icons.drag_indicator_rounded,
                currentSort == 'manual', isDark, text, textSec, surface),
          ],
        );
        if (selected != null) {
          if (tab == 3) {
            state.todosSort = selected;
          } else {
            state.notesSort = selected;
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isManual
              ? AppColors.terracotta.withValues(alpha: 0.15)
              : cardBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.swap_vert_rounded,
          size: 16,
          color: isManual ? AppColors.terracotta : AppColors.terracotta.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
    String value, String label, IconData icon, bool sel,
    bool isDark, Color text, Color textSec, Color surface,
  ) {
    return PopupMenuItem<String>(
      value: value,
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: sel
            ? AppColors.terracotta.withValues(alpha: 0.1)
            : Colors.transparent,
        child: Row(
          children: [
            Icon(icon, size: 15,
                color: sel ? AppColors.terracotta : textSec),
            const SizedBox(width: 10),
            Text(label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                color: sel ? AppColors.terracotta : text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
