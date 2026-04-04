// lib/widgets/common_widgets.dart
//
// Виджеты, используемые в нескольких экранах.
// Всё что дублировалось в notes/todos/events — здесь.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'shared_widgets.dart';
import '../theme/app_theme.dart';
import '../theme/font_helper.dart';
import '../theme/card_colors.dart';

export 'shared_widgets.dart';

// ─── Delete Confirm Dialog ────────────────────────────────
/// Стандартный диалог подтверждения удаления.
/// Возвращает true если пользователь нажал «Удалить».
class DeleteConfirmDialog extends StatelessWidget {
  final bool isDark;
  final String title;
  final String? subtitle;

  const DeleteConfirmDialog({
    super.key,
    required this.isDark,
    required this.title,
    this.subtitle,
  });

  /// Удобный helper: показать диалог и вернуть bool.
  static Future<bool> show(
    BuildContext context, {
    required bool isDark,
    required String title,
    String? subtitle,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.4),
          builder: (_) => DeleteConfirmDialog(
            isDark: isDark,
            title: title,
            subtitle: subtitle,
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final bg     = isDark ? AppColors.darkSurface  : AppColors.lightSurface;
    final text   = isDark ? AppColors.darkText      : AppColors.lightText;
    final textSec= isDark ? AppColors.darkTextBody  : AppColors.lightTextBody;
    final btnBg  = isDark ? AppColors.darkBg2       : AppColors.lightBg2;
    final appFont= context.watch<AppState>().appFont;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Удалить?',
              style: appTitleStyle(appFont, size: 18, weight: FontWeight.w600, color: text),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!.isEmpty ? 'Без названия' : subtitle!,
                style: GoogleFonts.dmSans(fontSize: 13, color: textSec),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'Это действие нельзя отменить.',
                style: GoogleFonts.dmSans(fontSize: 13, color: textSec),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: 'Отмена',
                    color: btnBg,
                    textColor: textSec,
                    onTap: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DialogButton(
                    label: 'Удалить',
                    color: Colors.red.shade400,
                    textColor: Colors.white,
                    bold: true,
                    onTap: () => Navigator.pop(context, true),
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

class _DialogButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  final bool bold;

  const _DialogButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

// ─── Swipable Card ────────────────────────────────────────
/// Обёртка-свайп для карточек: свайп влево → диалог удаления.
/// Заменяет дублирующиеся _SwipableCard в notes/todos/events.
class SwipableCard extends StatelessWidget {
  final Key dismissKey;
  final Widget child;
  final VoidCallback onDelete;
  final EdgeInsets padding;
  /// Краткое название элемента для диалога (опционально).
  final String? itemName;

  const SwipableCard({
    super.key,
    required this.dismissKey,
    required this.child,
    required this.onDelete,
    this.padding = EdgeInsets.zero,
    this.itemName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().darkMode;
    return Dismissible(
      key: dismissKey,
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => DeleteConfirmDialog.show(
        context,
        isDark: isDark,
        title: 'Удалить?',
        subtitle: itemName,
      ),
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

// ─── Empty State ──────────────────────────────────────────
/// Стандартное пустое состояние: иконка + текст по центру.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;

  const EmptyState({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.darkMode;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.terracotta.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            label,
            style: appTitleStyle(
              state.appFont,
              size: 16,
              weight: FontWeight.w600,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Screen Header ────────────────────────────────────────
/// Шапка экрана: поиск + фильтр по категориям.
/// Одинакова для Notes, Events, Todos.
class ScreenHeader extends StatelessWidget {
  final String searchHint;
  final ValueChanged<String> onSearch;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelectCategory;
  final Color Function(String) colorResolver;

  const ScreenHeader({
    super.key,
    required this.searchHint,
    required this.onSearch,
    required this.categories,
    required this.selectedCategory,
    required this.onSelectCategory,
    required this.colorResolver,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSearchBar(onChanged: onSearch, hint: searchHint),
          const SizedBox(height: 10),
          CategoryFilterRow(
            categories: categories,
            selected: selectedCategory,
            onSelect: onSelectCategory,
            colorResolver: colorResolver,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ─── Expand / Collapse Bar ────────────────────────────────
/// Строка «Развернуть все» / «Свернуть все» над списком.
class ExpandCollapseBar extends StatelessWidget {
  final bool allExpanded;
  final VoidCallback onToggle;

  const ExpandCollapseBar({
    super.key,
    required this.allExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Row(
              children: [
                Icon(
                  allExpanded
                      ? Icons.unfold_less_rounded
                      : Icons.unfold_more_rounded,
                  size: 14,
                  color: AppColors.terracotta,
                ),
                const SizedBox(width: 4),
                Text(
                  allExpanded ? 'Свернуть все' : 'Развернуть все',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.terracotta,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category Folder Chip ─────────────────────────────────
/// Чип выбора категории внутри редакторов (заметки/события/задачи).
class CategoryChip extends StatelessWidget {
  final String category;
  final Color color;
  final bool menuOpen;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.category,
    required this.color,
    required this.menuOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              category.isEmpty ? '–' : category,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              menuOpen
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Color Picker Grid ────────────────────────────────────
/// Универсальный выбор цвета из kCardColors.
/// Используется в редакторах заметок, событий, задач.
class ColorPickerGrid extends StatefulWidget {
  final int selectedIndex;
  final bool isDark;
  final bool large; // true = dialog-size (36px), false = inline (26px)
  final ValueChanged<int> onSelect;

  const ColorPickerGrid({
    super.key,
    required this.selectedIndex,
    required this.isDark,
    required this.onSelect,
    this.large = true,
  });

  @override
  State<ColorPickerGrid> createState() => _ColorPickerGridState();
}

class _ColorPickerGridState extends State<ColorPickerGrid> {
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.large ? 36.0 : 26.0;
    final iconSize = widget.large ? 16.0 : 12.0;
    final checkSize = widget.large ? 18.0 : 13.0;
    final borderSel = widget.large ? 2.5 : 2.0;

    return Wrap(
      spacing: widget.large ? 8 : 6,
      runSpacing: widget.large ? 8 : 6,
      children: List.generate(22, (i) {
        final sel = _current == i;
        if (i == 0) {
          // Reset button
          return GestureDetector(
            onTap: () {
              setState(() => _current = 0);
              widget.onSelect(0);
            },
            child: Container(
              width: size, height: size,
              decoration: BoxDecoration(
                color: widget.isDark ? AppColors.darkCard : AppColors.lightCardAlt,
                shape: BoxShape.circle,
                border: Border.all(
                  color: sel
                      ? AppColors.terracotta
                      : (widget.isDark ? AppColors.darkDivider : AppColors.lightDivider),
                  width: sel ? borderSel : 1,
                ),
              ),
              child: Icon(
                Icons.block_rounded,
                size: iconSize,
                color: widget.isDark ? AppColors.darkDivider : AppColors.lightDivider,
              ),
            ),
          );
        }
        final color = kCardColors[i - 1];
        return GestureDetector(
          onTap: () {
            setState(() => _current = i);
            widget.onSelect(i);
          },
          child: Container(
            width: size, height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: sel ? Colors.white : Colors.transparent,
                width: borderSel,
              ),
              boxShadow: sel
                  ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: widget.large ? 6 : 4)]
                  : null,
            ),
            child: sel
                ? Icon(Icons.check_rounded, size: checkSize, color: Colors.white)
                : null,
          ),
        );
      }),
    );
  }
}

// ─── Draggable List Card ──────────────────────────────────
/// Карточка с drag-and-drop для списка (list view).
/// Notion-стиль: ghost placeholder + haptic + плавные анимации.
class DraggableListCard extends StatefulWidget {
  final String itemId;
  final void Function(String fromId, String toId) onReorder;
  final ValueNotifier<String?> dragState;
  final Widget child;

  const DraggableListCard({
    super.key,
    required this.itemId,
    required this.onReorder,
    required this.dragState,
    required this.child,
  });

  @override
  State<DraggableListCard> createState() => _DraggableListCardState();
}

class _DraggableListCardState extends State<DraggableListCard> {
  static String? _fromId(String? v) => v?.split('->')[0];
  static String? _toId(String? v) =>
      (v != null && v.contains('->')) ? v.split('->')[1] : null;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: widget.dragState,
      builder: (ctx, dragVal, _) {
        final isMe     = _fromId(dragVal) == widget.itemId;
        final isTarget = _toId(dragVal)   == widget.itemId;

        return DragTarget<String>(
          onWillAcceptWithDetails: (d) {
            if (d.data == widget.itemId) return false;
            widget.dragState.value = '${d.data}->${widget.itemId}';
            return true;
          },
          onLeave: (fromId) {
            if (fromId != null) widget.dragState.value = fromId;
          },
          onAcceptWithDetails: (d) {
            final from = d.data;
            final to   = widget.itemId;
            widget.dragState.value = null;
            if (from != to) {
              HapticFeedback.lightImpact();
              Future.delayed(const Duration(milliseconds: 180), () {
                widget.onReorder(from, to);
              });
            }
          },
          builder: (ctx, _, __) {
            return LongPressDraggable<String>(
              data: widget.itemId,
              delay: const Duration(milliseconds: 300),
              onDragStarted: () {
                HapticFeedback.mediumImpact();
                widget.dragState.value = widget.itemId;
              },
              onDragEnd: (_) => widget.dragState.value = null,
              onDraggableCanceled: (_, __) => widget.dragState.value = null,
              feedback: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: MediaQuery.of(ctx).size.width - 32,
                  child: Transform.scale(
                    scale: 1.03,
                    child: Opacity(opacity: 0.92, child: widget.child),
                  ),
                ),
              ),
              childWhenDragging: const SizedBox.shrink(),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: isMe ? 0.0 : 1.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ghost placeholder появляется плавно над целевой карточкой
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: isTarget
                          ? _DropIndicator(child: widget.child)
                          : const SizedBox.shrink(),
                    ),
                    // Подсветка целевой карточки
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      decoration: isTarget
                          ? BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppColors.terracotta.withValues(alpha: 0.45),
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

class _DropIndicator extends StatelessWidget {
  final Widget child;
  const _DropIndicator({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: 0.2,
        child: child,
      ),
    );
  }
}
