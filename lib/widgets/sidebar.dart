import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../screens/folder_manager_screen.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.darkMode;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextDate : AppColors.lightTextDate;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    final tabLabel = ['Календарь', 'События', 'Заметки', 'Задачи'][state.currentTab];
    final cats = [
      <String>[],             // 0=Календарь — нет фильтра
      state.eventCategories,  // 1=События
      state.noteCategories,   // 2=Заметки
      state.todoCategories,   // 3=Задачи
    ][state.currentTab].skip(1).toList(); // skip 'Все'

    String currentFilter() {
      switch (state.currentTab) {
        case 1: return state.eventsFilter;
        case 2: return state.notesFilter;
        case 3: return state.todosFilter;
        default: return '';
      }
    }

    void setFilter(String cat) {
      switch (state.currentTab) {
        case 1: state.eventsFilter = cat; break;
        case 2: state.notesFilter = cat; break;
        case 3: state.todosFilter = cat; break;
      }
      state.refresh();
      Navigator.pop(context);
    }

    final initials = state.userName.isNotEmpty
        ? state.userName.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '?';

    return Drawer(
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _showProfileSheet(context, state);
              },
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCardAlt,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.terracotta,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: GoogleFonts.fraunces(
                          fontSize: 17, fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.userName.isEmpty ? 'Профиль' : state.userName,
                            style: GoogleFonts.dmSans(
                              fontSize: 14, fontWeight: FontWeight.w600, color: text,
                            ),
                          ),
                          Text(
                            'Изменить имя',
                            style: GoogleFonts.dmSans(fontSize: 11, color: textSec),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: textSec, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Settings
            _sidebarItem(
              context,
              icon: Icons.settings_outlined,
              label: 'Настройки',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                _showSettingsSheet(context, state);
              },
            ),

            // Folders
            _sidebarItem(
              context,
              icon: Icons.folder_outlined,
              label: 'Папки',
              isDark: isDark,
              onTap: () {
                final tab = state.currentTab;
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => FolderManagerScreen(initialTab: tab),
                ));
              },
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Divider(color: divider, height: 1),
            ),

            // Current section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Text(
                tabLabel.toUpperCase(),
                style: GoogleFonts.dmSans(
                  fontSize: 9, fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppColors.terracotta,
                ),
              ),
            ),

            // All items
            _sidebarItem(
              context,
              icon: Icons.apps_rounded,
              label: 'Все',
              isDark: isDark,
              active: currentFilter() == 'Все',
              onTap: () => setFilter('Все'),
            ),

            // Category items
            ...cats.map((cat) => _sidebarItem(
              context,
              dotColor: AppColors.categoryColor(cat),
              label: cat,
              isDark: isDark,
              active: currentFilter() == cat,
              onTap: () => setFilter(cat),
            )),
          ],
        ),
      ),
    );
  }

  Widget _sidebarItem(
    BuildContext context, {
    IconData? icon,
    Color? dotColor,
    required String label,
    required bool isDark,
    bool active = false,
    required VoidCallback onTap,
  }) {
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextDate : AppColors.lightTextDate;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? AppColors.terracotta.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (icon != null)
              Icon(icon, size: 16, color: active ? AppColors.terracotta : textSec)
            else if (dotColor != null)
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? AppColors.terracotta : text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileSheet(BuildContext context, AppState state) {
    final ctrl = TextEditingController(text: state.userName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BottomSheet(
        title: 'Профиль',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ваше имя',
              style: GoogleFonts.dmSans(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: state.darkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(hintText: 'Введите имя...'),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: _PrimaryButton(
                label: 'Сохранить',
                onTap: () {
                  state.setUserName(ctrl.text.trim());
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BottomSheet(
        title: 'Настройки',
        child: StatefulBuilder(builder: (ctx2, setSt) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Тема оформления',
                style: GoogleFonts.dmSans(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: state.darkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ThemeOption(
                    label: 'Тёмная',
                    icon: Icons.dark_mode_rounded,
                    selected: state.darkMode,
                    onTap: () {
                      if (!state.darkMode) { state.toggleTheme(); setSt(() {}); }
                    },
                  ),
                  const SizedBox(width: 10),
                  _ThemeOption(
                    label: 'Светлая',
                    icon: Icons.light_mode_rounded,
                    selected: !state.darkMode,
                    onTap: () {
                      if (state.darkMode) { state.toggleTheme(); setSt(() {}); }
                    },
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _BottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  const _BottomSheet({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.darkMode;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final text = isDark ? AppColors.darkText : AppColors.lightText;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.fraunces(
                fontSize: 20, fontWeight: FontWeight.w600,
                color: text, fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeOption({
    required this.label, required this.icon,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.darkMode;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.terracotta
                : (isDark ? AppColors.darkCard : AppColors.lightCardAlt),
            borderRadius: BorderRadius.circular(14),
            border: selected
                ? Border.all(color: AppColors.terracotta)
                : Border.all(color: Colors.transparent),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : AppColors.terracotta.withValues(alpha: 0.5),
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.terracotta,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white,
          ),
        ),
      ),
    );
  }
}
