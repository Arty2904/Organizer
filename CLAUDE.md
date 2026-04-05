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
    card_colors.dart         # kCardColors (21 colors), cardColorFor(colorIndex)
  l10n/
    translations.dart        # kTranslations — Map<locale, Map<key, String>> for 10 languages
    app_strings.dart         # S class, kLanguageOptions, systemLocale()
  screens/
    home_shell.dart          # Main scaffold: AppBar, IndexedStack, _BottomNav,
                             # _BulkActionBar, _OptionsButton, _OptionsDropDown
    notes_screen.dart        # Notes list + NoteEditorScreen
    events_screen.dart       # Events list + EventEditorDialog
    todos_screen.dart        # Todos list + TodoEditorDialog
    calendar_screen.dart     # Calendar view + CalendarSearchScreen
    folder_manager_screen.dart  # Folder CRUD per section
  widgets/
    sidebar.dart             # AppSidebar (drawer) + SettingsScreen
    shared_widgets.dart      # PageFoldCorner, CategoryDot, CategoryBadge,
                             # AppSearchBar, CategoryFilterRow,
                             # formatDate(), formatDateTime(), repeatLabel(),
                             # CustomDateTimePicker
    common_widgets.dart      # DeleteConfirmDialog, SwipableCard, EmptyState,
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
- `locale` -> `setLocale(String)` — saved to SharedPreferences, default = `systemLocale()`
- `s` — getter returning `S.of(locale)`, shortcut to all UI strings
- `reminderOffsetMinutes` (default 30) -> `setReminderOffset(int minutes)`

### View & Sort
- `notesView`, `todosView`, `eventsView` — int, 1=list 2=grid 3=compact
- `notesSort`, `todosSort`, `eventsSort` — `'date'` or `'manual'`

### Navigation
- `currentTab` — 0=Calendar, 1=Events, 2=Notes, 3=Todos

### Filters
- `notesFilter`, `todosFilter`, `eventsFilter` — active category string; `state.s.all` = show all
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
- `eventsInMonth(DateTime month)` — does NOT account for repeating events
- `todosInMonth(DateTime month)`
- `refresh()` — calls `notifyListeners()`

## Localisation System (lib/l10n/)

### Architecture
No flutter_localizations / .arb files. Simple custom Map-based system.

**`translations.dart`** — `kTranslations: Map<String, Map<String, String>>` with 10 locales:
`ru`, `en`, `es`, `de`, `fr`, `it`, `pt`, `zh`, `ja`, `hi`

**`app_strings.dart`** — exports:
- `kLanguageOptions` — list of `(code, displayName, flagEmoji)` tuples
- `systemLocale()` — reads `Platform.localeName`, maps to supported locale, falls back to `'ru'`
- `S` class — typed accessors: `S.of(locale).save`, `.cancel`, `.today`, `.monthsCapital`, etc.

**`AppState.s`** — getter `S.of(_locale)`, available everywhere via `state.s`

### Accessing strings
```dart
// In build() — reactive, updates when locale changes
final state = context.watch<AppState>();
Text(state.s.save)

// In non-build methods (overlays, callbacks)
context.read<AppState>().s.save

// Helper functions with optional S
formatDate(dt, s: state.s)
formatDateTime(dt, s: state.s)
repeatLabel(r, days, s: state.s)
```

### Adding a new string
1. Add key + value to all 10 locales in `translations.dart`
2. Add getter to `S` class in `app_strings.dart`
3. Use via `state.s.newKey`

### kLanguageOptions format
```dart
const kLanguageOptions = [
  ('ru', 'Русский',   '🇷🇺'),
  ('en', 'English',   '🇬🇧'),
  // ... (code, displayName, flagEmoji)
];
```
Flag emoji shown left of name in both the dropdown and the current-value field.

### Settings UI
SettingsScreen has language dropdown (`_showLangDropdown`) with `_pendingLocale` — changes apply on «Save». `hasChanges` includes locale diff.

## Typography System

### Two font tokens
All font usage must go through `font_helper.dart`:

**`appTitleStyle(font, {size, weight, color, fontStyle})`** — UI elements:
- Titles, section headers, navigation, buttons, dialogs, search fields, filter chips
- Card titles (Note.title, AppEvent.title, TodoGroup.name)
- Everything the user sees as interface — not content they wrote

**`contentStyle(font, {size, weight, color, height})`** — user-written content only:
- `Note.body`, `AppEvent.body`, `EventTask.text`, `TodoItem.text`
- Body TextFields in editors

**Always `GoogleFonts.dmSans()` — never changes:**
- Dates, times, counters, numbers
- Reminder/repeat chips (terracotta pills)
- Calendar numbers (day of month, month name, weekday headers)

### Available fonts (10 total, all support Cyrillic)
```
fraunces      — Выразительный serif (default)
playfair      — Playfair Display, NYT-стиль
lora          — Мягкий книжный serif
dm_sans       — Чистый гротеск
nunito        — Округлый дружелюбный
lobster       — Декоративный ретро
caveat        — Быстрый почерк
bad_script    — Школьная пропись
shantell_sans — Маркер-рукопись
marck_script  — Каллиграфический
```
- `lobster`, `bad_script`, `marck_script` → always `FontWeight.w400` (no bold), via `_fixedWeight()`
- Sacramento / Dancing Script removed — no Cyrillic support

### Font access rules
- In `build()`: `final state = context.watch<AppState>(); state.appFont`
- In non-build methods: `context.read<AppState>().appFont`
- **Never** hardcode `GoogleFonts.fraunces()` for UI titles or `GoogleFonts.dmSans()` for content

### Font dropdowns (SettingsScreen)
Both font pickers use overlay dropdowns:
- `ConstrainedBox(maxHeight: 320)` + `SingleChildScrollView` + `ClipRRect`
- `Divider(height: 1, thickness: 0.5)` via `items.add()`
- `vertical: 9` padding, name only (no description subtitle)

### _Section widget (SettingsScreen)
```
_Section(title: state.s.settingReminders, tooltip: '...', child: ...)
```
Tooltip strings must be single-line.

## Color System

### Theme colors — always use AppColors constants
Key pairs: `darkBg/lightBg`, `darkText/lightText`, `darkTextBody/lightTextBody`,
`darkTextDate/lightTextDate`, `darkDivider/lightDivider`, `darkCard/lightCard`,
`darkSurface/lightSurface`, `darkSearchBg/lightSearchBg`, etc.
Accent: `AppColors.terracotta`

### Card color palettes
`kCardColors` (21 muted warm tones) in `card_colors.dart` — single source.
`kNoteColors`/`kTodoColors`/`kEventColors` aliases removed.
`cardColorFor(int colorIndex)` returns Color (null for index 0).

### Text on colored cards — CRITICAL
```dart
final textColor = hasColor ? AppColors.textColorFor(cardBg)    : (isDark ? AppColors.darkText     : AppColors.lightText);
final textSec   = hasColor ? AppColors.textSecColorFor(cardBg) : (isDark ? AppColors.darkTextBody : AppColors.lightTextBody);
final divider   = hasColor ? AppColors.dividerColorFor(cardBg) : (isDark ? AppColors.darkDivider  : AppColors.lightDivider);
```

## Repeat Feature (Events & Todos)
Both editors have `_showRepeatPicker()` — non-build method:
```dart
void _showRepeatPicker() {
  final appState = context.read<AppState>();
  final appFont = appState.appFont;
  final staticLabels = {
    RepeatInterval.none: appState.s.repeatNone,
    ...
  };
```
`_repeatLabel` getter uses `context.read<AppState>().s`.

## Calendar Screen

### Key types
- `_EffEvent` — event + computed occurrence date (for repeating events)
- `_CalDayGroup` — events+todos grouped by day for search results

### Header
- Tap title → toggle month/year view; title uses `_titleText(state.s)` (method, not getter)
- `more_vert_rounded` → `_showMenu(context, isDark)` (non-build) → `context.read<AppState>().s.search`

### Year view (_YearGrid, _MiniMonth)
- Month names from `state.s.monthsCapital` — full names, `FittedBox(fit: BoxFit.scaleDown)` auto-shrinks if needed
- Single-letter weekdays from `s.weekdays1` (localised)

### CalendarSearchScreen
- `dayLabel()` uses `state.s.weekdaysShort` and `state.s.monthsLower`
- Search field uses `appTitleStyle` (UI font)

## home_shell.dart Structure
- `_BottomNav` — StatelessWidget, receives `appFont` + `s` (S) as constructor params
- `_OptionsDropDown.build()` declares `final state = context.watch<AppState>()`
- `_BulkActionBar.build()` declares `final s = context.watch<AppState>().s`
- Tab labels built inline: `[state.s.calendar, state.s.events, state.s.notes, state.s.todos][tab]`

## Sidebar (sidebar.dart → AppSidebar + SettingsScreen)
- Three sections collapsible; folders collapsible; "без папки" collapsible
- Settings: Name, UI Font, Content Font, Theme, Reminders, Language
- Language dropdown: `_showLangDropdown()`, `_pendingLocale`, `currentLang.$3` = flag emoji

## folder_manager_screen.dart
- `_showAddFolderDialog(ctx, state, ...)` — top-level function; uses `state.s` directly
- Tab mapping: UI 0=Events, UI 1=Notes, UI 2=Todos

## shared_widgets.dart Public API
- `formatDate(DateTime, {S? s})` — localised; uses `s.today/yesterday/tomorrow/monthsLower`
- `formatDateTime(DateTime?, {S? s})` — date + HH:mm
- `repeatLabel(RepeatInterval, int?, {S? s})` — localised repeat string
- `CustomDateTimePicker` — drum picker, uses `state.s.monthsCapital` and `state.s.done`
- `ViewSwitcher` — builds labels from `state.s.viewList/viewGrid/viewCompact`
- `CategoryFilterRow` — `isAll` check uses `allLabel = context.watch<AppState>().s.all`

## common_widgets.dart Public API
Re-exports `shared_widgets.dart`.
- `DeleteConfirmDialog` — `DeleteConfirmDialog.show(context, ...)`
- `SwipableCard`, `EmptyState`, `ScreenHeader`, `ExpandCollapseBar`
- `CategoryChip`, `ColorPickerGrid`, `DraggableListCard`

## Grid View (view 2)

### Fixed 148px card height
- `ReorderableGridView.count` (manual sort) / static 2-col (date sort)
- `childAspectRatio: colWidth / 148`
- `dragWidgetBuilder`: `Transform.scale(1.03)` + `Opacity(0.92)`

### Todo grid card
- `gridChip: Widget = SizedBox.shrink(); bool hasChip = false;` — non-nullable pattern
- Same for `reminderChip` / `hasReminderChip` in list view
- Layout: `Stack` + `Positioned`, never Column

### Drag pattern — list & compact
```
if (sort != 'manual') return swipableOrPlain;
return DraggableListCard(
  key: ValueKey(item.id), itemId: item.id,
  dragState: _listDragState,
  onReorder: (f, t) => state.reorderXxxById(f, t),
  child: card,
);
```

### Todo default name on save
`context.read<AppState>().s.defaultTask` or `.defaultList`

## Key Conventions
- Colors always from AppColors — never hardcoded hex
- `context.watch<AppState>()` in build; `context.read<AppState>()` in callbacks/non-build
- All UI strings via `state.s.xxx` — never hardcode Russian
- `formatDate/formatDateTime/repeatLabel` always pass `s: state.s`
- IndexedStack — all 4 tabs always mounted
- Navigation: `Navigator.push` for note editor, `showDialog` for event/todo editors

## Common Pitfalls
- **state.s in non-build methods** — `_showMenu`, `_showRepeatPicker`, overlay builders, top-level functions do NOT have `state` in scope. Use `context.read<AppState>().s` or pass `state`/`s` as parameter.
- **static const with runtime values** — `static const _labels = [state.s.calendar, ...]` won't compile. Make it a local variable in `build()` or pass as constructor param.
- **`_showAddFolderDialog` is top-level** — `context` is not available; use `ctx` (BuildContext param) and `state` (AppState param).
- **Filter comparison** — compare with `state.s.all`, not hardcoded `'Все'`.
- **EmptyState is not const** when label is `state.s.xxx` — remove `const`.
- appFont in non-build: use `context.read<AppState>().appFont`
- FocusNode in dialogs: declare as State field, never inside StatefulBuilder
- Grid chips: non-nullable Widget + bool flag pattern, never Widget? + !
- Font dropdowns: Divider via `items.add()`, not bare statement
- Sacramento/Dancing Script: removed, do not re-add

## GitHub
- Repo: `Arty2904/Organizer`
- Main branch: `master`
