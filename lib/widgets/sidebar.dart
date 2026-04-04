import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/font_helper.dart';
import '../screens/folder_manager_screen.dart';
import '../screens/notes_screen.dart';
import '../screens/events_screen.dart';
import '../screens/todos_screen.dart';

// ─── Data models ──────────────────────────────────────────
class _SectionData {
  final int tab;
  final String label;
  final List<String> folders;
  final List<_ItemData> items;
  const _SectionData({required this.tab, required this.label, required this.folders, required this.items});
}

class _ItemData {
  final String id;
  final String title;
  final String category;
  const _ItemData({required this.id, required this.title, required this.category});
}

// ─── AppSidebar ───────────────────────────────────────────
class AppSidebar extends StatefulWidget {
  const AppSidebar({super.key});
  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  final Set<String> _collapsed = {};
  bool _allCollapsed = false;

  void _toggleFolder(String key) {
    setState(() {
      if (_collapsed.contains(key)) _collapsed.remove(key);
      else _collapsed.add(key);
    });
  }

  void _toggleAll(List<String> allKeys) {
    setState(() {
      if (_allCollapsed) {
        _collapsed.clear();
        _allCollapsed = false;
      } else {
        _collapsed.addAll(allKeys);
        _allCollapsed = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.darkMode;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextDate : AppColors.lightTextDate;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCardAlt;

    final initials = state.userName.isNotEmpty
        ? state.userName.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '?';

    final sections = [
      _SectionData(
        tab: 3, label: 'ЗАДАЧИ',
        folders: state.todoFolders,
        items: state.todos.map((t) => _ItemData(id: t.id, title: t.name.isEmpty ? 'Без названия' : t.name, category: t.category)).toList(),
      ),
      _SectionData(
        tab: 2, label: 'ЗАМЕТКИ',
        folders: state.noteFolders,
        items: state.notes.map((n) => _ItemData(id: n.id, title: n.title.isEmpty ? 'Без названия' : n.title, category: n.category)).toList(),
      ),
      _SectionData(
        tab: 1, label: 'СОБЫТИЯ',
        folders: state.eventFolders,
        items: state.events.map((e) => _ItemData(id: e.id, title: e.title.isEmpty ? 'Событие' : e.title, category: e.category)).toList(),
      ),
    ];

    final allKeys = <String>[];
    for (final s in sections) {
      allKeys.add('__sec_${s.label}');
      for (final f in s.folders) allKeys.add('${s.label}__$f');
      allKeys.add('${s.label}____uncategorized');
    }

    return Drawer(
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile / Settings ──
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: const BoxDecoration(color: AppColors.terracotta, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(initials, style: GoogleFonts.fraunces(
                        fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white, fontStyle: FontStyle.normal,
                      )),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(state.userName.isEmpty ? 'Профиль' : state.userName,
                          style: appTitleStyle(state.appFont, size: 14, weight: FontWeight.w600, color: text)),
                        Text('Настройки', style: appTitleStyle(state.appFont, size: 11, color: textSec)),
                      ]),
                    ),
                    Icon(Icons.chevron_right_rounded, color: textSec, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            // ── Управление папками ──
            _navItem(
              icon: Icons.folder_outlined, label: 'Управление папками',
              isDark: isDark, text: text, textSec: textSec,
              onTap: () {
                final tab = state.currentTab;
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => FolderManagerScreen(initialTab: tab)));
              },
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(color: divider, height: 1),
            ),

            // ── Hierarchy header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 6),
              child: Row(children: [
                Expanded(child: Text('СОДЕРЖИМОЕ', style: appTitleStyle(
                  state.appFont,
                  size: 9, weight: FontWeight.w800, color: AppColors.terracotta,
                ))),
                GestureDetector(
                  onTap: () => _toggleAll(allKeys),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.terracotta.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                        _allCollapsed ? Icons.unfold_more_rounded : Icons.unfold_less_rounded,
                        size: 12, color: AppColors.terracotta,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _allCollapsed ? 'Развернуть' : 'Свернуть',
                        style: appTitleStyle(state.appFont, size: 10, weight: FontWeight.w600, color: AppColors.terracotta),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),

            // ── Hierarchy ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 20),
                children: sections.map((section) {
                  final secKey = '__sec_${section.label}';
                  final secCollapsed = _collapsed.contains(secKey);
                  final uncategorized = section.items.where((i) => i.category.isEmpty).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section header
                      GestureDetector(
                        onTap: () => _toggleFolder(secKey),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Row(children: [
                            Icon(
                              secCollapsed ? Icons.chevron_right_rounded : Icons.expand_more_rounded,
                              size: 14, color: AppColors.terracotta,
                            ),
                            const SizedBox(width: 4),
                            Text(section.label, style: appTitleStyle(
                              state.appFont,
                              size: 9, weight: FontWeight.w800, color: AppColors.terracotta,
                            )),
                            const SizedBox(width: 6),
                            Text('${section.items.length}', style: GoogleFonts.dmSans(
                              fontSize: 9, color: AppColors.terracotta.withValues(alpha: 0.5),
                            )),
                          ]),
                        ),
                      ),

                      if (!secCollapsed) ...[
                        ...section.folders.map((folder) {
                          final fKey = '${section.label}__$folder';
                          final fCollapsed = _collapsed.contains(fKey);
                          final fItems = section.items.where((i) => i.category == folder).toList();
                          final fColor = state.folderColor(folder);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () => _toggleFolder(fKey),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(28, 3, 16, 3),
                                  child: Row(children: [
                                    Icon(
                                      fCollapsed ? Icons.chevron_right_rounded : Icons.expand_more_rounded,
                                      size: 16, color: fColor,
                                    ),
                                    const SizedBox(width: 7),
                                    Expanded(child: Text(folder, style: appTitleStyle(
                                      state.appFont,
                                      size: 12, weight: FontWeight.w600,
                                      color: fCollapsed ? text : fColor,
                                    ))),
                                    if (fItems.isNotEmpty)
                                      Text('${fItems.length}', style: GoogleFonts.dmSans(fontSize: 10, color: textSec)),
                                  ]),
                                ),
                              ),
                              if (!fCollapsed)
                                ...fItems.map((item) => _ItemTile(
                                  item: item, isDark: isDark, text: text, textSec: textSec,
                                  onTap: () => _openItem(context, state, section.tab, item),
                                )),
                            ],
                          );
                        }),

                        if (uncategorized.isNotEmpty) ...[
                          () {
                            final uKey = '${section.label}____uncategorized';
                            final uCollapsed = _collapsed.contains(uKey);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () => _toggleFolder(uKey),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(28, 3, 16, 3),
                                    child: Row(children: [
                                      Icon(
                                        uCollapsed ? Icons.chevron_right_rounded : Icons.expand_more_rounded,
                                        size: 16, color: textSec,
                                      ),
                                      const SizedBox(width: 7),
                                      Expanded(child: Text('без папки', style: appTitleStyle(
                                        state.appFont,
                                        size: 12, weight: FontWeight.w600,
                                        color: uCollapsed ? text : textSec,
                                      ))),
                                      Text('${uncategorized.length}', style: GoogleFonts.dmSans(fontSize: 10, color: textSec)),
                                    ]),
                                  ),
                                ),
                                if (!uCollapsed)
                                  ...uncategorized.map((item) => _ItemTile(
                                    item: item, isDark: isDark, text: text, textSec: textSec,
                                    onTap: () => _openItem(context, state, section.tab, item),
                                  )),
                              ],
                            );
                          }(),
                        ],
                      ],

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Divider(color: divider.withValues(alpha: 0.5), height: 1),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openItem(BuildContext context, AppState state, int tab, _ItemData item) {
    Navigator.pop(context);
    state.currentTab = tab;
    state.refresh();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (tab == 2) {
        final note = state.notes.firstWhere((n) => n.id == item.id, orElse: () => state.notes.first);
        Navigator.push(context, MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)));
      } else if (tab == 1) {
        final event = state.events.firstWhere((e) => e.id == item.id, orElse: () => state.events.first);
        showDialog(context: context, barrierColor: Colors.black.withValues(alpha: 0.4),
          builder: (_) => EventEditorDialog(event: event));
      } else if (tab == 3) {
        final todo = state.todos.firstWhere((t) => t.id == item.id, orElse: () => state.todos.first);
        showDialog(context: context, barrierColor: Colors.black.withValues(alpha: 0.4),
          builder: (_) => TodoEditorDialog(initialCategory: todo.category));
      }
    });
  }

  Widget _navItem({IconData? icon, required String label, required bool isDark,
      required Color text, required Color textSec, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          if (icon != null) Icon(icon, size: 16, color: textSec),
          const SizedBox(width: 12),
          Text(label, style: appTitleStyle(context.watch<AppState>().appFont, size: 13, color: text)),
        ]),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final _ItemData item;
  final bool isDark;
  final Color text, textSec;
  final VoidCallback onTap;
  const _ItemTile({required this.item, required this.isDark, required this.text, required this.textSec, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(48, 5, 16, 5),
        child: Row(children: [
          Container(width: 3, height: 3, decoration: BoxDecoration(color: textSec, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(item.title, style: appTitleStyle(context.watch<AppState>().appFont, size: 12, color: text),
            overflow: TextOverflow.ellipsis, maxLines: 1)),
        ]),
      ),
    );
  }
}

// ─── Settings Screen ──────────────────────────────────────
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameCtrl;
  late String _pendingAppFont;
  late String _pendingContentFont;
  OverlayEntry? _fontOverlay;
  OverlayEntry? _contentFontOverlay;
  OverlayEntry? _themeOverlay;
  OverlayEntry? _reminderOverlay;
  final LayerLink _fontLink = LayerLink();
  final LayerLink _contentFontLink = LayerLink();
  final LayerLink _themeLink = LayerLink();
  final LayerLink _reminderLink = LayerLink();

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _nameCtrl = TextEditingController(text: state.userName);
    _nameCtrl.addListener(() => setState(() {}));
    _pendingAppFont = state.appFont;
    _pendingContentFont = state.contentFont;
  }

  @override
  void dispose() {
    _closeOverlays();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _closeOverlays() {
    _fontOverlay?.remove(); _fontOverlay = null;
    _contentFontOverlay?.remove(); _contentFontOverlay = null;
    _themeOverlay?.remove(); _themeOverlay = null;
    _reminderOverlay?.remove(); _reminderOverlay = null;
  }

  void _showFontDropdown(BuildContext ctx, AppState state) {
    _closeOverlays();
    final isDark = state.darkMode;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    _fontOverlay = OverlayEntry(builder: (_) => GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _closeOverlays,
      child: Stack(children: [
        Positioned.fill(child: Container(color: Colors.transparent)),
        CompositedTransformFollower(
          link: _fontLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 4),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: divider, width: 0.5),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min,
                      children: () {
                        final items = <Widget>[];
                        for (int i = 0; i < kFontOptions.length; i++) {
                          final f = kFontOptions[i];
                          final sel = _pendingAppFont == f.$1;
                          items.add(GestureDetector(
                            onTap: () { setState(() => _pendingAppFont = f.$1); _closeOverlays(); },
                            child: Container(
                              color: sel ? AppColors.terracotta.withValues(alpha: 0.08) : Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                              child: Row(children: [
                                Expanded(child: Text(f.$2, style: appTitleStyle(f.$1, size: 14, color: sel ? AppColors.terracotta : text))),
                                if (sel) Icon(Icons.check_rounded, size: 14, color: AppColors.terracotta),
                              ]),
                            ),
                          ));
                          if (i < kFontOptions.length - 1)
                            items.add(Divider(height: 1, thickness: 0.5, color: divider, indent: 16, endIndent: 16));
                        }
                        return items;
                      }(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    ));
    Overlay.of(ctx).insert(_fontOverlay!);
    setState(() {});
  }

  void _showContentFontDropdown(BuildContext ctx, AppState state) {
    _closeOverlays();
    final isDark = state.darkMode;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    _contentFontOverlay = OverlayEntry(builder: (_) => GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _closeOverlays,
      child: Stack(children: [
        Positioned.fill(child: Container(color: Colors.transparent)),
        CompositedTransformFollower(
          link: _contentFontLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 4),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: divider, width: 0.5),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min,
                      children: () {
                        final items = <Widget>[];
                        for (int i = 0; i < kContentFontOptions.length; i++) {
                          final f = kContentFontOptions[i];
                          final sel = _pendingContentFont == f.$1;
                          items.add(GestureDetector(
                            onTap: () { setState(() => _pendingContentFont = f.$1); _closeOverlays(); },
                            child: Container(
                              color: sel ? AppColors.terracotta.withValues(alpha: 0.08) : Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                              child: Row(children: [
                                Expanded(child: Text(f.$2, style: contentStyle(f.$1, size: 14, color: sel ? AppColors.terracotta : text))),
                                if (sel) Icon(Icons.check_rounded, size: 14, color: AppColors.terracotta),
                              ]),
                            ),
                          ));
                          if (i < kContentFontOptions.length - 1)
                            items.add(Divider(height: 1, thickness: 0.5, color: divider, indent: 16, endIndent: 16));
                        }
                        return items;
                      }(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    ));
    Overlay.of(ctx).insert(_contentFontOverlay!);
    setState(() {});
  }

  void _showThemeDropdown(BuildContext ctx, AppState state) {
    _closeOverlays();
    final isDark = state.darkMode;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    _themeOverlay = OverlayEntry(builder: (_) => GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _closeOverlays,
      child: Stack(children: [
        Positioned.fill(child: Container(color: Colors.transparent)),
        CompositedTransformFollower(
          link: _themeLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 4),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: divider, width: 0.5),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: Column(mainAxisSize: MainAxisSize.min,
                children: [
                  ('dark', Icons.dark_mode_rounded, 'Тёмная'),
                  ('light', Icons.light_mode_rounded, 'Светлая'),
                ].map((t) {
                  final sel = isDark ? t.$1 == 'dark' : t.$1 == 'light';
                  return GestureDetector(
                    onTap: () {
                      if ((t.$1 == 'dark') != isDark) state.toggleTheme();
                      setState(() {}); _closeOverlays();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.terracotta.withValues(alpha: 0.08) : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(children: [
                        Icon(t.$2, size: 16, color: sel ? AppColors.terracotta : text),
                        const SizedBox(width: 10),
                        Expanded(child: Text(t.$3, style: appTitleStyle(
                          _pendingAppFont,
                          size: 13, weight: sel ? FontWeight.w600 : FontWeight.w400,
                          color: sel ? AppColors.terracotta : text,
                        ))),
                        if (sel) Icon(Icons.check_rounded, size: 14, color: AppColors.terracotta),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ]),
    ));
    Overlay.of(ctx).insert(_themeOverlay!);
    setState(() {});
  }

  String _reminderLabel(int minutes) {
    switch (minutes) {
      case 5:     return 'За 5 минут';
      case 10:    return 'За 10 минут';
      case 15:    return 'За 15 минут';
      case 30:    return 'За 30 минут';
      case 60:    return 'За час';
      case 1440:  return 'За день';
      case 2880:  return 'За 2 дня';
      case 10080: return 'За неделю';
      default:    return 'За $minutes минут';
    }
  }

  void _showReminderDropdown(BuildContext ctx, AppState state) {
    _closeOverlays();
    final isDark = state.darkMode;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextBody : AppColors.lightTextBody;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    const options = [
      (5,    'За 5 минут'),
      (10,   'За 10 минут'),
      (15,   'За 15 минут'),
      (30,   'За 30 минут'),
      (60,   'За час'),
      (1440, 'За день'),
      (2880, 'За 2 дня'),
      (10080,'За неделю'),
    ];

    _reminderOverlay = OverlayEntry(builder: (_) => GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _closeOverlays,
      child: Stack(children: [
        Positioned.fill(child: Container(color: Colors.transparent)),
        CompositedTransformFollower(
          link: _reminderLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 4),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: divider, width: 0.5),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: options.map((o) {
                  final sel = state.reminderOffsetMinutes == o.$1;
                  return GestureDetector(
                    onTap: () { state.setReminderOffset(o.$1); _closeOverlays(); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.terracotta.withValues(alpha: 0.08) : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(children: [
                        Expanded(child: Text(o.$2, style: appTitleStyle(
                          state.appFont,
                          size: 14,
                          weight: sel ? FontWeight.w600 : FontWeight.w400,
                          color: sel ? AppColors.terracotta : text,
                        ))),
                        if (sel) Icon(Icons.check_rounded, size: 14, color: AppColors.terracotta),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ]),
    ));
    Overlay.of(ctx).insert(_reminderOverlay!);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.darkMode;
    final bg = isDark ? AppColors.darkBg2 : AppColors.lightBg2;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final textSec = isDark ? AppColors.darkTextBody : AppColors.lightTextBody;
    final textHint = isDark ? const Color(0x4DE6AF78) : const Color(0x6E785028);
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final fieldBg = isDark ? AppColors.darkCard : AppColors.lightCardAlt;

    final currentFont = kFontOptions.firstWhere((f) => f.$1 == _pendingAppFont, orElse: () => kFontOptions.first);
    final currentContentFont = kContentFontOptions.firstWhere((f) => f.$1 == _pendingContentFont, orElse: () => kContentFontOptions.first);
    final hasChanges = _nameCtrl.text.trim() != state.userName
        || _pendingAppFont != state.appFont
        || _pendingContentFont != state.contentFont;

    return GestureDetector(
      onTap: _closeOverlays,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: surface,
          elevation: 0, shadowColor: Colors.transparent, surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, size: 18, color: text),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Настройки', style: appTitleStyle(
            _pendingAppFont, size: 15, weight: FontWeight.w600, color: text,
          )),
          centerTitle: true,
          bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(color: divider, height: 1)),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 8),

                  // ── Имя ──
                  _Section(title: 'ИМЯ', child: TextField(
                    controller: _nameCtrl,
                    maxLines: 1,
                    style: appTitleStyle(_pendingAppFont, size: 14, color: text),
                    decoration: InputDecoration(
                      filled: true, fillColor: fieldBg,
                      hintText: 'Введите имя...',
                      hintStyle: appTitleStyle(_pendingAppFont, size: 14, color: textHint),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      isDense: true,
                    ),
                  )),

                  const SizedBox(height: 20),

                  // ── Шрифт элементов интерфейса ──
                  _Section(title: 'ШРИФТ ЭЛЕМЕНТОВ ИНТЕРФЕЙСА', child: CompositedTransformTarget(
                    link: _fontLink,
                    child: GestureDetector(
                      onTap: () => _showFontDropdown(context, state),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(color: fieldBg, borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(currentFont.$2, style: appTitleStyle(_pendingAppFont, size: 15, color: text)),
                            Text(currentFont.$3, style: GoogleFonts.dmSans(fontSize: 11, color: textSec)),
                          ])),
                          Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: textSec),
                        ]),
                      ),
                    ),
                  )),

                  const SizedBox(height: 16),

                  // ── Шрифт пользовательского контента ──
                  _Section(title: 'ШРИФТ ПОЛЬЗОВАТЕЛЬСКОГО КОНТЕНТА', child: CompositedTransformTarget(
                    link: _contentFontLink,
                    child: GestureDetector(
                      onTap: () => _showContentFontDropdown(context, state),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(color: fieldBg, borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(currentContentFont.$2, style: contentStyle(_pendingContentFont, size: 14, color: text)),
                            Text(currentContentFont.$3, style: GoogleFonts.dmSans(fontSize: 11, color: textSec)),
                          ])),
                          Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: textSec),
                        ]),
                      ),
                    ),
                  )),

                  const SizedBox(height: 20),

                  // ── Тема ──
                  _Section(title: 'ТЕМА ОФОРМЛЕНИЯ', child: CompositedTransformTarget(
                    link: _themeLink,
                    child: GestureDetector(
                      onTap: () => _showThemeDropdown(context, state),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(color: fieldBg, borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, size: 16, color: AppColors.terracotta),
                          const SizedBox(width: 10),
                          Expanded(child: Text(isDark ? 'Тёмная' : 'Светлая', style: appTitleStyle(_pendingAppFont, size: 14, color: text))),
                          Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: textSec),
                        ]),
                      ),
                    ),
                  )),

                  const SizedBox(height: 20),

                  // ── Напоминания ──
                  _Section(
                    title: 'НАПОМИНАНИЯ',
                    tooltip: 'За сколько до начала события приходит уведомление на телефон',
                    child: CompositedTransformTarget(
                      link: _reminderLink,
                      child: GestureDetector(
                        onTap: () => _showReminderDropdown(context, state),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(color: fieldBg, borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            Icon(Icons.notifications_none_rounded, size: 16, color: AppColors.terracotta),
                            const SizedBox(width: 10),
                            Expanded(child: Text(
                              _reminderLabel(state.reminderOffsetMinutes),
                              style: appTitleStyle(_pendingAppFont, size: 14, color: text),
                            )),
                            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: textSec),
                          ]),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),

            // ── Кнопка Сохранить ──
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: AnimatedOpacity(
                  opacity: hasChanges ? 1.0 : 0.35,
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    onTap: hasChanges
                        ? () {
                            state.setUserName(_nameCtrl.text.trim());
                            state.setAppFont(_pendingAppFont);
                            state.setContentFont(_pendingContentFont);
                            FocusScope.of(context).unfocus();
                          }
                        : null,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.terracotta,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text('Сохранить', style: appTitleStyle(
                        _pendingAppFont,
                        size: 14, weight: FontWeight.w700, color: Colors.white,
                      )),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? tooltip;
  final Widget child;
  const _Section({required this.title, required this.child, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final appFont = context.watch<AppState>().appFont;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Text(title, style: appTitleStyle(
          appFont,
          size: 9, weight: FontWeight.w800, color: AppColors.terracotta.withValues(alpha: 0.8),
        )),
        if (tooltip != null) ...[
          const SizedBox(width: 5),
          Tooltip(
            message: tooltip!,
            preferBelow: false,
            triggerMode: TooltipTriggerMode.tap,
            decoration: BoxDecoration(
              color: AppColors.terracotta.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: appTitleStyle(appFont, size: 11, color: Colors.white),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Icon(
              Icons.info_outline_rounded,
              size: 13,
              color: AppColors.terracotta.withValues(alpha: 0.7),
            ),
          ),
        ],
      ]),
      const SizedBox(height: 8),
      child,
    ]);
  }
}
