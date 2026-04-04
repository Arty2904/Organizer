# Organizer Pro — Project Context

## Stack
- **Flutter** (Dart), targets Android (emulator: sdk gphone64 x86 64)
- **Provider** (`ChangeNotifier`) for state management
- **Google Fonts** for all typography
- **SharedPreferences** for persistence
- **uuid** for generating IDs
- **intl** for date formatting (`initializeDateFormatting('ru', null)` called in `main()`)
- **reorderable_grid_view** for drag-and-drop in grid view (manual sort mode)

## Project Structure
```
lib/
  main.dart                  # App entry point, MaterialApp with theme
  providers/
    app_state.dart           # Single AppState ChangeNotifier (all data + settings)
  models/
    models.dart              # Note, Event, TodoGroup, TodoItem, EventTask, RepeatInterval
  theme/
    app_theme.dart           # AppColors, buildTheme(), textColorFor helpers
    font_helper.dart         # appTitleStyle(), contentStyle(), kFontOptions, kContentFontOptions
    card_colors.dart         # kCardColors (21 colors), kNoteColors/kTodoColors/kEventColors aliases,
                             # cardColorFor(colorIndex)
  screens/
    home_shell.dart          # Main scaffold: AppBar, IndexedStack, _BottomNav,
                             # _BulkActionBar, _OptionsButton, _OptionsDropDown
    notes_screen.dart        # Notes list + NoteEditorScreen
                             # _NoteGrid: ReorderableGridView (manual) / static 2-col (date)
    events_screen.dart       # Events list + EventEditorDialog
                             # _EventsMasonryGrid: ReorderableGridView (manual) / static 2-col (date)
    todos_screen.dart        # Todos list + TodoEditorDialog
                             # _TodosMasonryGrid: ReorderableGridView (manual) / static 2-col (date)
    calendar_screen.dart     # Calendar view + CalendarSearchScreen
                             # + repeat helpers (top-level functions)
    folder_manager_screen.dart  # Folder CRUD per section
  widgets/
    sidebar.dart             # AppSidebar (drawer) + SettingsScreen
    shared_widgets.dart      # PageFoldCorner, CategoryDot, CategoryBadge,
                             # AppSearchBar, CategoryFilterRow,
                             # formatDate(), formatDateTime(), repeatLabel(),
                             # CustomDateTimePicker
    common_widgets.dart      # Shared UI components extracted from screen files:
                             # DeleteConfirmDialog, SwipableCard, EmptyState,
                             # ScreenHeader, ExpandCollapseBar, CategoryChip,
                             # ColorPickerGrid, DraggableListCard
                             # Re-exports shared_widgets.dart
    selection_state.dart     # SelectionState, SelectionScope,
                             # SelectableCardWrapper, SelectionHighlight
```

## Models (models.dart)

### Note
`id, title, body, category, createdAt, colorIndex` (0=default, 1-21=custom)

### TodoItem
`text, done`

### TodoGroup
`id, name, category, items (List<TodoItem>), createdAt, colorIndex, dueDate?, reminderDate?, repeat, customDays?`

### AppEvent
`id, title, body, category, reminderDate?, repeat, customDays?, tasks (List<EventTask>), createdAt, colorIndex`

### EventTask
`text, done` — subtasks inside an event

### RepeatInterval (enum)
`none, daily, weekly, monthly, yearly, custom`
- Defined once in `models.dart`, used by both `AppEvent` and `TodoGroup`
- Serialized as `'repeat': repeat.index` / deserialized as `RepeatInterval.values[j['repeat'] ?? 0]`

## AppState Key Fields & Methods

### Settings
- `darkMode` -> `toggleTheme()`
- `appFont` -> `setAppFont(String)`
- `contentFont` -> `setContentFont(String)`
- `userName` -> `setUserName(String)`
- `reminderOffsetMinutes` (default 30) -> `setReminderOffset(int minutes)` — saved to SharedPreferences

### View & Sort
- `notesView`, `todosView`, `eventsView` — int, 1=list 2=grid 3=compact, set via setters, persisted via `_saveViews()`
- `notesSort`, `todosSort`, `eventsSort` — `'date'` or `'manual'`, set via setters

### Navigation
- `currentTab` — 0=Calendar, 1=Events, 2=Notes, 3=Todos

### Filters
- `notesFilter`, `todosFilter`, `eventsFilter` — active category string, `'Все'` = all
- `noteCategories`, `todoCategories`, `eventCategories` — computed lists for filter row

### Folders
- `noteFolders`, `eventFolders`, `todoFolders` — `List<String>`
- `noteHidden`, `todoHidden`, `eventHidden` — `Set<String>` of hidden folder names
- `folderColors` — `Map<String, String>` (hex string per folder name)
- `folderColor(String name)` -> `Color`
- `setFolderColor(String name, Color)`
- `noteFilterOrder`, `todoFilterOrder`, `eventFilterOrder` — display order incl. special items
- `fullNoteFilterOrder`, `fullTodoFilterOrder`, `fullEventFilterOrder` — for folder manager
- `addFolder(int tab, String name)`, `renameFolder(...)`, `deleteFolder(...)`, `reorderFilterItem(...)`
- `toggleFolderVisibility(int tab, String folder)`

### Sidebar collapse state
- `sidebarCollapsed` — `Set<String>` persisted to SharedPreferences

### Data CRUD
- `notes`, `events`, `todos` — lists
- `addNote/updateNote/deleteNote`, `addEvent/updateEvent/deleteEvent`, `addTodo/updateTodo/deleteTodo`
- `toggleTodoItem(groupId, idx)`
- `reorderNote/reorderNoteById`, `reorderTodo/reorderTodoById`, `reorderEvent/reorderEventById`

### Bulk operations
- `bulkDeleteNotes/Todos/Events(Set<String> ids)`
- `bulkMoveNotes/Todos/Events(Set<String> ids, String category)`
- `bulkColorNotes/Todos/Events(Set<String> ids, int colorIndex)`

### Queries
- `filteredNotes(String query)`, `filteredTodos(String query)`, `filteredEvents(String query)`
- `eventsInMonth(DateTime month)` — does NOT account for repeating events, use `eventOccurrenceDaysInMonth()` in calendar_screen instead
- `todosInMonth(DateTime month)`
- `refresh()` — calls `notifyListeners()`

## Typography System
All font usage must go through `font_helper.dart`:
- `appTitleStyle(font, size, weight, color, fontStyle?)` — UI elements, titles, navigation labels
- `contentStyle(font, size, weight, color, height)` — user-written content
- `kFontOptions` / `kContentFontOptions` — same list of `(key, displayName, description)` tuples
- Available fonts: `fraunces` (default), `playfair`, `lora`, `dm_sans`, `nunito`, `sacramento`, `dancing_script`
- `sacramento` and `dancing_script` always render as `FontWeight.w400` regardless of weight param
- Never hardcode `GoogleFonts.dmSans()` for titles or content — use the helpers
- `GoogleFonts.dmSans()` is fine for metadata, dates, tags, buttons, UI chrome

## Color System

### Theme colors — always use AppColors constants
Key pairs: `darkBg/lightBg`, `darkText/lightText`, `darkTextBody/lightTextBody`,
`darkTextDate/lightTextDate`, `darkDivider/lightDivider`, `darkCard/lightCard`,
`darkSurface/lightSurface`, `darkSearchBg/lightSearchBg`, etc.
Accents: `AppColors.terracotta` (dark), `AppColors.terracottaLight` (light)

### Card color palettes — single source of truth in `card_colors.dart`
All palettes are unified under `kCardColors` (21 muted warm tones) in `theme/card_colors.dart`.
`kNoteColors`, `kTodoColors`, `kEventColors` are backward-compat aliases pointing to the same list — migrate call-sites to `kCardColors` and remove aliases when convenient.
`cardColorFor(int colorIndex)` returns the `Color` for a given index (null for index 0).
No separate per-screen palette lists exist anymore; do not re-introduce them.

### Text on colored cards — CRITICAL
When `colorIndex > 0`, never hardcode text/divider colors. Always:
```dart
final textColor = hasColor ? AppColors.textColorFor(cardBg)    : (isDark ? AppColors.darkText     : AppColors.lightText);
final textSec   = hasColor ? AppColors.textSecColorFor(cardBg) : (isDark ? AppColors.darkTextBody : AppColors.lightTextBody);
final divider   = hasColor ? AppColors.dividerColorFor(cardBg) : (isDark ? AppColors.darkDivider  : AppColors.lightDivider);
```
Helpers in `app_theme.dart`:
- `AppColors.textColorFor(bg)` — black or white via `bg.computeLuminance() > 0.35`
- `AppColors.textSecColorFor(bg)` — semi-transparent secondary
- `AppColors.dividerColorFor(bg)` — dividers and checkbox borders

Apply to ALL text on the card: title, body, secondary text, dividers, checkboxes.
Never use `AppColors.lightTextDate` as fallback on colored cards.

### Category colors
`AppColors.categoryColor(String category)` -> `Color` for known category names.
`AppColors.cardBgDark/cardBgLight(String category)` — tinted card bg by category.

## Settings Screen (sidebar.dart -> SettingsScreen)
- Name field — single-line TextField, no inline save button
- Save button — fixed at bottom, opacity 0.35 until `hasChanges`; saves name + appFont + contentFont
- UI font picker — dropdown, applies immediately via `state.setAppFont()`
- Content font picker — dropdown, applies immediately via `state.setContentFont()`
- Theme picker — dropdown, applies immediately via `state.toggleTheme()`
- Reminder picker — dropdown, 8 options (5/10/15/30 min, 1h, 1d, 2d, 1w), applies immediately via `state.setReminderOffset()`

### _Section widget
Accepts optional `tooltip` parameter. Shows tappable info icon next to title:
```dart
_Section(title: 'НАПОМИНАНИЯ', tooltip: 'За сколько до начала события...', child: ...)
```
Tooltip strings must be single-line — no literal newlines in single-quoted strings.

## Repeat Feature (Events & Todos)
Both `_EventEditorDialogState` and `_TodoEditorDialogState` have:
- `_repeat` (RepeatInterval), `_customDays` (int?)
- `_customDaysCtrl` (TextEditingController) — for inline N input
- `_customDaysFocus` (FocusNode) — declared as State field, NOT inside dialog builder
- `_showRepeatPicker()` — Dialog with StatefulBuilder. "Через N дней" row has inline IntrinsicWidth TextField. Checkmark shows when valid number entered. No separate popup.
- On save: `customDays = _repeat == RepeatInterval.custom ? int.tryParse(_customDaysCtrl.text) : null`
- `.then()` on dialog syncs `_customDays = int.tryParse(_customDaysCtrl.text)`

`repeatLabel(RepeatInterval r, int? days)` in `shared_widgets.dart` returns display string.

## Calendar Screen (calendar_screen.dart)

### Top-level repeat helpers
- `eventOccurrenceDaysInMonth(event, month)` -> `Set<int>` — all days in month (respects repeat)
- `nextOccurrence(event, after)` -> `DateTime?` — next occurrence after given date
- `_advanceTo(event, cur, target)` — fast-forward helper (perf)
- `_nextOccurrenceAfter(event, cur)` — one step per repeat rule

### _EffEvent
```dart
class _EffEvent { final AppEvent event; final DateTime date; }
```
Used in Сегодня/Ближайшие — repeating events appear once with next occurrence date.

### _CalDayGroup
Groups events+todos by day for CalendarSearchScreen.

### Header
- Tap title -> toggle month/year view
- `more_vert_rounded` -> overlay dropdown -> Поиск -> pushes CalendarSearchScreen
- No chevron arrow next to title

### CalendarSearchScreen
Full-screen push. Shows events+todos grouped by day for next 70 days. Live text search.
Repeating events expanded into individual occurrences within the range.

## home_shell.dart Structure
- `HomeShell` -> `_HomeShellState` wraps everything in `SelectionScope`
- `_selectionState` (SelectionState) — multi-select ChangeNotifier
- `_BottomNav` — StatelessWidget, receives `appFont` as param (must not watch state internally)
- `_OptionsButton` / `_OptionsDropDown` — view switcher (list/grid/compact) + sort (date/manual) + Выделить entry. Shown in AppBar for tabs 1-3.
- `_BulkActionBar` — replaces BottomNav when `inSelect`. Actions: delete, move, color. Color picker in `_showColorSheet()`.
- `_handleFab()` — tab 0 -> EventEditorDialog, 1 -> EventEditorDialog(initialCategory), 2 -> NoteEditorScreen, 3 -> TodoEditorDialog
- `resizeToAvoidBottomInset: false` — keyboard overlays content, FAB stays fixed

## Sidebar (sidebar.dart -> AppSidebar)
- Three sections: ЗАДАЧИ, ЗАМЕТКИ, СОБЫТИЯ — each collapsible
- Named folders collapsible per section
- "без папки" section also collapsible, key: `'${section.label}____uncategorized'`
- Global collapse/expand uses `allKeys` which includes all folder keys + uncategorized keys
- `sidebarCollapsed` persisted in AppState

## folder_manager_screen.dart
- FAB triggers `_showAddFolderDialog(...)` — top-level function, not static method on State
- `resizeToAvoidBottomInset: false`
- Tab mapping: UI 0=Events(appTab 0), UI 1=Notes(appTab 1), UI 2=Todos(appTab 2)

## selection_state.dart
- `SelectionState` extends ChangeNotifier — `enter/exit/toggle/selectAll/deselectAll`
- `SelectionScope` — InheritedNotifier, provides `SelectionState.of(context)`
- `SelectableCardWrapper` — wraps any card; shows checkbox overlay when selection active
- `SelectionHighlight` — use inside the card container for terracotta tint overlay when selected

## shared_widgets.dart Public API
- `PageFoldCorner` — expand/collapse corner on list-view cards
- `CategoryDot` — small colored circle
- `CategoryBadge` — tag chip shown on cards
- `AppSearchBar` — search input with clear button
- `CategoryFilterRow` — horizontal scrollable filter chips
- `formatDate(DateTime)` — localized date string
- `formatDateTime(DateTime?)` — date+time string
- `repeatLabel(RepeatInterval, int?)` — human-readable repeat string
- `CustomDateTimePicker` — drum-style date+time picker dialog

## common_widgets.dart Public API
Re-exports `shared_widgets.dart` — screens only need to import `common_widgets.dart`.
- `DeleteConfirmDialog` — standard delete confirmation dialog; use `DeleteConfirmDialog.show(context, ...)` helper
- `SwipableCard` — Dismissible wrapper (swipe left → delete confirm dialog)
- `EmptyState` — centered icon + label for empty lists
- `ScreenHeader` — search bar + category filter row (used by Notes, Events, Todos)
- `ExpandCollapseBar` — «Развернуть все» / «Свернуть все» row above lists
- `CategoryChip` — folder/category selector chip for editors
- `ColorPickerGrid` — 21-color + reset picker grid; `large` param toggles dialog vs inline size
- `DraggableListCard` — LongPressDraggable + DragTarget for manual sort in list/compact view.
  Requires `ValueNotifier<String?> dragState` shared across all cards in the list.
  Features: `HapticFeedback.mediumImpact()` on drag start, `lightImpact()` on drop,
  `Transform.scale(1.03)` on feedback widget, `delay: 300ms`, `Curves.easeOutCubic` animations.

## Grid View (view 2)

### Fixed card height
All grid cards are **148px tall** across all three entities. This eliminates column height imbalance and enables smooth `ReorderableGridView` animation.

### Drag in grid (manual sort only)
- Uses `ReorderableGridView.count` from `reorderable_grid_view` package
- `childAspectRatio: colWidth / 148` — always precise, no overflow
- `dragWidgetBuilder` applies `Transform.scale(1.03)` + `Opacity(0.92)` for lift effect
- `onReorder` calls `reorderNoteById` / `reorderEventById` / `reorderTodoById`
- When sort = `'date'`, `ReorderableGridView` is replaced by a plain 2-column static layout

### Note grid card (`_GridCard`, `_NoteCard` grid branch)
- Title: 1 line. Body: `maxLines: 4`. No date, no dot.

### Event grid card (`_EventGridCard`)
- Title: `maxLines: 2`. Body: `maxLines: 4`.
- Reminder/repeat chip always pinned to bottom via `Positioned(bottom: 10)`.
  Shows date only (no repeat text) when `reminderDate != null`; shows repeat label only when no date.
- Content area uses `Positioned` with explicit bottom offset (`hasChip ? 38 : 12`) so chip never overlaps text.

### Todo grid card (`_TodoCard` view 2 branch — separate early return)
- Always shows title (name). If name is empty — top area is blank (no fallback text).
- Progress bar shown when `group.total > 0`.
- Tasks: exactly `maxItems` rows computed from available height before render — no overflow possible.
  Formula: `available = 124 - chipReserve - titleH - progressH`, `maxItems = (available / 18).floor().clamp(0, 4)`.
- Each task row is `SizedBox(height: 18)` — fixed, no padding.
- Reminder/repeat chip pinned to bottom via `Positioned(bottom: 10)`. Grid builds a separate
  `gridChip` widget (date only, no repeat text alongside date) distinct from the list `reminderChip`.
- Layout uses `Stack` + `Positioned` (not Column) to guarantee no RenderFlex overflow.

### Drag pattern — list & compact views
All three screens use `DraggableListCard` from `common_widgets.dart` (not `ReorderableListView`).
Each screen State holds `final ValueNotifier<String?> _listDragState = ValueNotifier(null)` — disposed in `dispose()`.
Pattern:
```dart
if (sort != 'manual') return swipableOrPlain;
return DraggableListCard(
  key: ValueKey(item.id),
  itemId: item.id,
  dragState: _listDragState,
  onReorder: (f, t) => state.reorderXxxById(f, t),
  child: card,
);
```

### Todo default name on save
When `_nameCtrl` is empty: `validItems.length == 1 ? 'Задача' : 'Список'`.
- Colors always from AppColors — never hardcoded hex
- `context.watch<AppState>()` for reactive reads, `context.read<AppState>()` in callbacks/initState
- IndexedStack — all 4 tabs always mounted
- Navigation: `Navigator.push` for note editor, `showDialog` for event/todo editors
- FAB shown on all tabs including Calendar (tab 0)

## Common Pitfalls
- `appTitleStyle` must not be defined locally — import from `font_helper.dart`
- `_BottomNav` is StatelessWidget — pass `appFont` as constructor param, never watch inside
- `TextPainter` for overflow — use same `contentStyle` as displayed text
- FocusNode in dialogs — never create inside StatefulBuilder builder; declare as State field and dispose in `dispose()`. Local creation causes `_dependents.isEmpty` assertion on rebuild.
- Multiline strings — literal newline inside single-quoted Dart string breaks compilation; use single-line or triple-quote
- Static methods on State — not accessible via StatefulWidget class name; move to top-level functions
- Duplicate variable declarations — inserting code near existing `final cardBg = ...` creates duplicate; check surrounding lines
- `eventsInMonth()` ignores repeat — for calendar dots/lists use `eventOccurrenceDaysInMonth()` helpers
- Card color palette — single source is `kCardColors` in `card_colors.dart`. Do not define separate per-screen lists. `kNoteColors`/`kTodoColors`/`kEventColors` are aliases; prefer `kCardColors` in new code.
- Swipe-to-delete, empty states, screen headers, expand/collapse bar, category chip, color picker grid, draggable list cards — use components from `common_widgets.dart`, not inline duplicates
- Grid cards are fixed 148px — never use `mainAxisSize: MainAxisSize.min` or unbounded Column inside a `Positioned` with both `top` and `bottom` set; it causes RenderFlex overflow. Use `height:` on `Positioned` or pre-compute item counts.
- `ReorderableGridView` requires all children to have the same aspect ratio — always derive `childAspectRatio` from `colWidth / 148`.
- `DraggableListCard` needs a shared `ValueNotifier<String?>` per screen — never create it inside `build()`, always declare as State field and dispose.
- Todo grid chip (`gridChip`) is built separately from the list `reminderChip` — they differ: grid shows date only, list shows date + repeat.

## GitHub
- Repo: `Arty2904/Organizer`
- Main branch: `master`
