import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── Selection State ──────────────────────────────────────
class SelectionState extends ChangeNotifier {
  bool _active = false;
  final Set<String> _selected = {};

  bool get active => _active;
  Set<String> get selected => Set.unmodifiable(_selected);
  bool isSelected(String id) => _selected.contains(id);

  void enter() { _active = true; _selected.clear(); notifyListeners(); }
  void exit()  { _active = false; _selected.clear(); notifyListeners(); }

  void toggle(String id) {
    if (_selected.contains(id)) _selected.remove(id); else _selected.add(id);
    notifyListeners();
  }

  void selectAll(Iterable<String> ids) { _selected.addAll(ids); notifyListeners(); }
  void deselectAll() { _selected.clear(); notifyListeners(); }
}

// ─── Selection Scope ──────────────────────────────────────
class SelectionScope extends InheritedNotifier<SelectionState> {
  const SelectionScope({super.key, required SelectionState state, required super.child})
      : super(notifier: state);

  static SelectionState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SelectionScope>()!.notifier!;

  static SelectionState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SelectionScope>()?.notifier;
}

// ─── Selectable Card Wrapper ──────────────────────────────
// Оборачивает карточку: тап по всей области — переключает выбор.
// Подсветка передаётся в саму карточку через SelectionHighlight.
class SelectableCardWrapper extends StatelessWidget {
  final String itemId;
  final Widget child;

  const SelectableCardWrapper({
    super.key,
    required this.itemId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final sel = SelectionScope.maybeOf(context);
    if (sel == null || !sel.active) return child;

    final isSelected = sel.isSelected(itemId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => sel.toggle(itemId),
      child: _SelectionHighlightScope(
        isSelected: isSelected,
        isDark: isDark,
        child: Stack(
          children: [
            IgnorePointer(child: child),
            // Чекбокс поверх
            Positioned(
              top: 8, right: 8,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22, height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppColors.terracotta
                      : (isDark
                          ? Colors.black.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.85)),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.terracotta
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.25)
                            : Colors.black.withValues(alpha: 0.12)),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// InheritedWidget передаёт состояние выделения вниз по дереву
// чтобы сама карточка могла покрасить только свой контейнер
class _SelectionHighlightScope extends InheritedWidget {
  final bool isSelected;
  final bool isDark;

  const _SelectionHighlightScope({
    required this.isSelected,
    required this.isDark,
    required super.child,
  });

  static _SelectionHighlightScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SelectionHighlightScope>();

  @override
  bool updateShouldNotify(_SelectionHighlightScope old) =>
      isSelected != old.isSelected || isDark != old.isDark;
}

// Виджет-обёртка для самого контейнера карточки —
// использовать ВНУТРИ карточки вместо обычного Container там где нужна подсветка
class SelectionHighlight extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;

  const SelectionHighlight({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
  });

  @override
  Widget build(BuildContext context) {
    final scope = _SelectionHighlightScope.maybeOf(context);
    if (scope == null || !scope.isSelected) return child;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: AppColors.terracotta.withValues(alpha: 0.13),
                borderRadius: borderRadius,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
