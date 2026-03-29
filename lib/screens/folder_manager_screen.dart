import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

const _kPaletteColors = [
  Color(0xFFE53935), Color(0xFFE91E63), Color(0xFF9C27B0),
  Color(0xFF673AB7), Color(0xFF3F51B5), Color(0xFF2196F3),
  Color(0xFF03A9F4), Color(0xFF00BCD4), Color(0xFF009688),
  Color(0xFF4CAF50), Color(0xFF8BC34A), Color(0xFFCDDC39),
  Color(0xFFFFEB3B), Color(0xFFFFC107), Color(0xFFFF9800),
  Color(0xFFFF5722), Color(0xFFD07840), Color(0xFF795548),
  Color(0xFF607D8B), Color(0xFF9E9E9E), Color(0xFF37474F),
];

class FolderManagerScreen extends StatefulWidget {
  final int initialTab;
  const FolderManagerScreen({super.key, this.initialTab = 2});
  @override
  State<FolderManagerScreen> createState() => _FolderManagerScreenState();
}

class _FolderManagerScreenState extends State<FolderManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  static const _appToUiTab = {1: 0, 2: 1, 3: 2};
  static const _tabLabels = ['События', 'Заметки', 'Задачи'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: 3, vsync: this,
      initialIndex: _appToUiTab[widget.initialTab] ?? 1,
    );
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  List<String> _fullOrder(AppState s, int ui) {
    if (ui == 0) return s.fullEventFilterOrder;
    if (ui == 1) return s.fullNoteFilterOrder;
    return s.fullTodoFilterOrder;
  }

  int _appTab(int ui) => ui == 0 ? 0 : (ui == 1 ? 1 : 2);

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final dark = s.darkMode;
    final bg   = dark ? AppColors.darkBg   : AppColors.lightBg;
    final bg2  = dark ? AppColors.darkBg2  : AppColors.lightBg2;
    final text = dark ? AppColors.darkText : AppColors.lightText;
    final sec  = dark ? AppColors.darkTextDate : AppColors.lightTextDate;
    final div  = dark ? AppColors.darkDivider  : AppColors.lightDivider;
    final acc  = dark ? AppColors.terracotta   : AppColors.terracottaLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg, surfaceTintColor: Colors.transparent,
        title: Text('Папки', style: GoogleFonts.fraunces(
          fontSize: 15, fontWeight: FontWeight.w600, color: text)),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: acc, unselectedLabelColor: sec,
          indicatorColor: acc, indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 12),
          tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: List.generate(3, (ui) => _FolderTab(
          appTab: _appTab(ui), isDark: dark,
          bg: bg, bg2: bg2, text: text, sec: sec, div: div, acc: acc,
          fullOrder: _fullOrder(s, ui), state: s,
        )),
      ),
    );
  }
}

class _FolderTab extends StatefulWidget {
  final int appTab;
  final bool isDark;
  final Color bg, bg2, text, sec, div, acc;
  final List<String> fullOrder;
  final AppState state;

  const _FolderTab({
    required this.appTab, required this.isDark,
    required this.bg, required this.bg2,
    required this.text, required this.sec, required this.div, required this.acc,
    required this.fullOrder, required this.state,
  });

  @override
  State<_FolderTab> createState() => _FolderTabState();
}

class _FolderTabState extends State<_FolderTab> {
  String? _editing;
  late TextEditingController _ctrl;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    _focus.addListener(() { if (!_focus.hasFocus) _commit(); });
  }

  @override
  void dispose() { _ctrl.dispose(); _focus.dispose(); super.dispose(); }

  bool _special(String f) => f == 'Все' || f == '';

  Set<String> get _hidden {
    if (widget.appTab == 0) return widget.state.eventHidden;
    if (widget.appTab == 1) return widget.state.noteHidden;
    return widget.state.todoHidden;
  }

  void _startEdit(String f) {
    if (_special(f)) return;
    setState(() { _editing = f; _ctrl.text = f; });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
      _ctrl.selection = TextSelection(baseOffset: 0, extentOffset: _ctrl.text.length);
    });
  }

  void _commit() {
    if (_editing == null) return;
    final v = _ctrl.text.trim();
    if (v.isNotEmpty && v != _editing) {
      widget.state.renameFolder(widget.appTab, _editing!, v);
    }
    setState(() => _editing = null);
  }

  void _showColorPicker(BuildContext ctx, String folder) {
    final bg   = widget.isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final text = widget.isDark ? AppColors.darkText    : AppColors.lightText;
    final cur  = widget.state.folderColor(folder);

    showDialog(
      context: ctx,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => Dialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Цвет папки', style: GoogleFonts.fraunces(
                fontSize: 16, fontWeight: FontWeight.w600, color: text)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10, runSpacing: 10,
                children: _kPaletteColors.map((c) {
                  final sel = c.value == cur.value;
                  return GestureDetector(
                    onTap: () { widget.state.setFolderColor(folder, c); Navigator.pop(ctx); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: c, shape: BoxShape.circle,
                        border: Border.all(
                          color: sel ? text : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: sel
                            ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 8)]
                            : null,
                      ),
                      child: sel
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdd(BuildContext ctx) {
    final ctrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: widget.bg,
        title: Text('Новая папка', style: GoogleFonts.fraunces(
          fontSize: 17, color: widget.text, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: ctrl, autofocus: true,
          style: GoogleFonts.dmSans(fontSize: 14, color: widget.text),
          decoration: InputDecoration(
            hintText: 'Название...',
            hintStyle: GoogleFonts.dmSans(fontSize: 14, color: widget.sec),
            filled: true,
            fillColor: widget.isDark ? AppColors.darkSearchBg : AppColors.lightSearchBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          onSubmitted: (v) {
            widget.state.addFolder(widget.appTab, v);
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text('Отмена', style: GoogleFonts.dmSans(color: widget.sec))),
          TextButton(
            onPressed: () {
              widget.state.addFolder(widget.appTab, ctrl.text);
              Navigator.pop(ctx);
            },
            child: Text('Добавить', style: GoogleFonts.dmSans(
              color: widget.acc, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext ctx, String name) async {
    final result = await showDialog<bool>(
      context: ctx,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => Dialog(
        backgroundColor: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Удалить папку?', style: GoogleFonts.fraunces(
                fontSize: 17, fontWeight: FontWeight.w600, color: widget.text)),
              const SizedBox(height: 8),
              Text('Папка «$name» будет удалена. Связанные элементы станут без тега.',
                  style: GoogleFonts.dmSans(fontSize: 13, color: widget.sec)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () => Navigator.pop(ctx, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: widget.bg2, borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: Text('Отмена', style: GoogleFonts.dmSans(
                      fontSize: 13, fontWeight: FontWeight.w600, color: widget.sec)),
                  ),
                )),
                const SizedBox(width: 10),
                Expanded(child: GestureDetector(
                  onTap: () => Navigator.pop(ctx, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: Text('Удалить', style: GoogleFonts.dmSans(
                      fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: widget.fullOrder.isEmpty
              ? Center(child: Text('Нет папок',
                  style: GoogleFonts.dmSans(fontSize: 14, color: widget.sec)))
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: widget.fullOrder.length,
                  onReorder: (o, n) => widget.state.reorderFilterItem(widget.appTab, o, n),
                  proxyDecorator: (child, _, __) =>
                      Material(color: Colors.transparent, child: child),
                  itemBuilder: (ctx, i) {
                    final folder  = widget.fullOrder[i];
                    final hidden  = _hidden.contains(folder);
                    final special = _special(folder);
                    final color   = widget.state.folderColor(folder);
                    final label   = folder.isEmpty ? '–' : folder;
                    final isEdit  = _editing == folder;

                    final cardContent = Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: widget.isDark ? const Color(0x0DFFFFFF) : const Color(0x40FFFFFF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: widget.isDark
                              ? AppColors.darkCardBorder
                              : AppColors.lightCardBorder,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          // drag handle
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Icon(Icons.drag_indicator_rounded,
                                size: 18, color: widget.sec),
                          ),
                          // цветной круг
                          GestureDetector(
                            onTap: special ? null : () => _showColorPicker(context, folder),
                            child: Container(
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                color: hidden ? color.withValues(alpha: 0.25) : color,
                                shape: BoxShape.circle,
                                border: special ? null : Border.all(
                                  color: widget.isDark
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Colors.black.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // название
                          Expanded(
                            child: isEdit
                                ? TextField(
                                    controller: _ctrl,
                                    focusNode: _focus,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 14, fontWeight: FontWeight.w500,
                                      color: widget.text,
                                    ),
                                    decoration: const InputDecoration(
                                      filled: false, border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero, isDense: true,
                                    ),
                                    onSubmitted: (_) => _commit(),
                                  )
                                : GestureDetector(
                                    onTap: special ? null : () => _startEdit(folder),
                                    child: Text(label, style: GoogleFonts.dmSans(
                                      fontSize: 14, fontWeight: FontWeight.w500,
                                      color: hidden
                                          ? widget.sec.withValues(alpha: 0.4)
                                          : widget.text,
                                    )),
                                  ),
                          ),
                          // видимость
                          GestureDetector(
                            onTap: () => widget.state.toggleFolderVisibility(
                                widget.appTab, folder),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Icon(
                                hidden
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 18,
                                color: hidden
                                    ? widget.sec.withValues(alpha: 0.4)
                                    : widget.sec,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );

                    // свайп только для не-специальных
                    final child = special
                        ? cardContent
                        : Dismissible(
                            key: ValueKey('d-$folder-$i'),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) => _confirmDelete(context, folder),
                            onDismissed: (_) =>
                                widget.state.deleteFolder(widget.appTab, folder),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.delete_outline_rounded,
                                      color: Colors.white, size: 20),
                                  const SizedBox(height: 2),
                                  Text('Удалить', style: GoogleFonts.dmSans(
                                    fontSize: 10, color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            child: cardContent,
                          );

                    return KeyedSubtree(
                      key: ValueKey('ks-$i-$folder'),
                      child: child,
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: GestureDetector(
            onTap: () => _showAdd(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                  color: widget.acc, borderRadius: BorderRadius.circular(14)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('Новая папка', style: GoogleFonts.dmSans(
                    fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
