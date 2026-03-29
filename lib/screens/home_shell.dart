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

  static const _tabLabels = ['События', 'Заметки', 'Дела', 'Календарь'];
  static const _tabIcons = [
    Icons.event_outlined,
    Icons.description_outlined,
    Icons.checklist_rounded,
    Icons.calendar_month_outlined,
  ];
  static const _tabActiveIcons = [
    Icons.event_rounded,
    Icons.description_rounded,
    Icons.checklist_rounded,
    Icons.calendar_month_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.darkMode;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final tab = state.currentTab;

    // Current view mode for the active tab
    int currentView() {
      switch (tab) {
        case 0: return state.eventsView;
        case 1: return state.notesView;
        case 2: return state.todosView;
        default: return 1;
      }
    }

    void setView(int v) {
      switch (tab) {
        case 0: state.eventsView = v; break;
        case 1: state.notesView = v; break;
        case 2: state.todosView = v; break;
      }
      state.refresh();
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
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
              fontSize: 17, fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic, color: text,
            ),
          ),
          centerTitle: true,
          actions: [
            if (tab != 3) // No view switcher on calendar
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ViewSwitcher(current: currentView(), onChanged: setView),
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
              EventsScreen(),
              NotesScreen(),
              TodosScreen(),
              CalendarScreen(),
            ],
          ),
        ),
        floatingActionButton: tab != 3
            ? FloatingActionButton(
                onPressed: () => _handleFab(context, state),
                backgroundColor: AppColors.terracotta,
                elevation: 3,
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
              )
            : null,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: surface,
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
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: active ? AppColors.terracotta.withOpacity(0.12) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              active ? _tabActiveIcons[i] : _tabIcons[i],
                              size: 20,
                              color: active ? AppColors.terracotta : textSec,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _tabLabels[i],
                            style: GoogleFonts.dmSans(
                              fontSize: 9,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
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
    switch (state.currentTab) {
      case 0:
        showModalBottomSheet(
          context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
          builder: (_) => const EventEditorSheet(),
        );
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const NoteEditorScreen()));
        break;
      case 2:
        showModalBottomSheet(
          context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
          builder: (_) => const TodoEditorSheet(),
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
    final color = isDark ? AppColors.darkText : AppColors.lightText;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _bar(color, 15),
        const SizedBox(height: 4),
        _bar(color, 10),
        const SizedBox(height: 4),
        _bar(color, 15),
      ],
    );
  }

  Widget _bar(Color color, double width) => Container(
    width: width, height: 2,
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1)),
  );
}
