# Organizer Pro — Project Context

## Stack
- **Flutter** (Dart), targets Android (emulator: sdk gphone64 x86 64)
- **Provider** (`ChangeNotifier`) for state management
- **Google Fonts** for all typography
- **SharedPreferences** for persistence
- **uuid** for generating IDs

## Project Structure
```
lib/
  main.dart                  # App entry point, MaterialApp with theme
  providers/
    app_state.dart           # Single AppState ChangeNotifier (all data + settings)
  models/
    models.dart              # Note, Event, TodoGroup, TodoItem data classes
  theme/
    app_theme.dart           # AppColors, buildTheme()
    font_helper.dart         # appTitleStyle(), contentStyle(), kFontOptions, kContentFontOptions
  screens/
    home_shell.dart          # Main scaffold: AppBar, IndexedStack, _BottomNav
    notes_screen.dart        # Notes list + NoteEditorScreen
    events_screen.dart       # Events list + EventEditorDialog
    todos_screen.dart        # Todos list + TodoEditorDialog
    calendar_screen.dart     # Calendar view
    folder_manager_screen.dart
  widgets/
    sidebar.dart             # AppSidebar (drawer) + SettingsScreen
    shared_widgets.dart      # Reusable widgets
    selection_state.dart     # Multi-select state
```

## AppState Key Fields
- `darkMode` — bool, toggled via `toggleTheme()`
- `appFont` — String key for UI/title font, set via `setAppFont()`
- `contentFont` — String key for user content font, set via `setContentFont()`
- `userName` — set via `setUserName()`
- `currentTab` — 0=Calendar, 1=Events, 2=Notes, 3=Todos
- `notes`, `events`, `todos` — lists, CRUD via `addNote/updateNote/deleteNote` etc.
- `noteFolders`, `eventFolders`, `todoFolders` — folder lists per section

## Typography System
All font usage must go through `font_helper.dart`:
- `appTitleStyle(state.appFont, size, weight, color)` — UI elements, titles, navigation labels
- `contentStyle(state.contentFont, size, weight, color, height)` — user-written content (note bodies, todo items, event descriptions)
- `kFontOptions` — list of `(key, displayName, description)` for UI font picker
- `kContentFontOptions` — list for content font picker
- **Never hardcode** `GoogleFonts.dmSans()` for titles or content — use the helpers above
- `GoogleFonts.dmSans()` is acceptable for metadata, dates, tags, buttons, and UI chrome

## Settings Screen (in sidebar.dart → SettingsScreen)
- **Name field**: single-line TextField, no inline save button
- **Save button**: fixed at bottom, inactive (opacity 0.35) until name differs from saved value
- **UI font picker**: dropdown using `kFontOptions`, applies immediately via `state.setAppFont()`
- **Content font picker**: dropdown using `kContentFontOptions`, applies immediately via `state.setContentFont()`
- **Theme picker**: dropdown, applies immediately via `state.toggleTheme()` — no Save needed

## Key Conventions
- Colors always from `AppColors` — never hardcoded hex values
- Dark/light theme checked via `state.darkMode`, colors selected from `AppColors.dark*/light*`
- `context.watch<AppState>()` for reactive reads, `context.read<AppState>()` in initState/callbacks
- Screens use `IndexedStack` — all 4 tabs are always mounted
- Navigation: `Navigator.push` for notes editor, `showDialog` for events/todos editors

## Common Pitfalls Fixed
- `appTitleStyle` was duplicated in both `sidebar.dart` and `font_helper.dart` — resolved by removing it from `sidebar.dart` and importing `font_helper.dart`
- `_BottomNav` is a `StatelessWidget` — must receive `appFont` as a parameter from parent (which watches state), otherwise tab labels stay hardcoded `dmSans`
- `TextPainter` for overflow detection must use the same font as the displayed text (`contentStyle`), otherwise the «Ещё/Свернуть» button behaves incorrectly

## GitHub
- Repo: `Arty2904/Organizer`
- Main branch: `master`
