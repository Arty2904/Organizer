import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/models.dart';

class AppState extends ChangeNotifier {
  // Theme
  bool _darkMode = true;
  bool get darkMode => _darkMode;

  // User
  String _userName = '';
  String get userName => _userName;

  // View modes: 1=list, 2=grid, 3=compact
  int _notesView = 1;
  int _todosView = 1;
  int _eventsView = 1;

  int get notesView => _notesView;
  int get todosView => _todosView;
  int get eventsView => _eventsView;

  set notesView(int v) { _notesView = v; _saveViews(); }
  set todosView(int v) { _todosView = v; _saveViews(); }
  set eventsView(int v) { _eventsView = v; _saveViews(); }

  // Sort modes: 'date' or 'manual'
  String _notesSort = 'date';
  String get notesSort => _notesSort;
  set notesSort(String v) { _notesSort = v; _saveViews(); notifyListeners(); }

  String _todosSort = 'date';
  String get todosSort => _todosSort;
  set todosSort(String v) { _todosSort = v; _saveViews(); notifyListeners(); }

  String _eventsSort = 'date';
  String get eventsSort => _eventsSort;
  set eventsSort(String v) { _eventsSort = v; _saveViews(); notifyListeners(); }

  // Manual order stored as list of ids
  List<String> _notesOrder = [];
  List<String> get notesOrder => _notesOrder;

  List<String> _todosOrder = [];
  List<String> get todosOrder => _todosOrder;

  List<String> _eventsOrder = [];
  List<String> get eventsOrder => _eventsOrder;

  void reorderNote(int oldIndex, int newIndex) {
    if (_notesOrder.isEmpty) _notesOrder = notes.map((n) => n.id).toList();
    if (newIndex > oldIndex) newIndex -= 1;
    final id = _notesOrder.removeAt(oldIndex);
    _notesOrder.insert(newIndex, id);
    _save(); notifyListeners();
  }

  void reorderNoteById(String fromId, String toId) {
    if (_notesOrder.isEmpty) _notesOrder = notes.map((n) => n.id).toList();
    for (final id in [fromId, toId]) {
      if (!_notesOrder.contains(id)) _notesOrder.add(id);
    }
    final fromIdx = _notesOrder.indexOf(fromId);
    _notesOrder.removeAt(fromIdx);
    final toIdx = _notesOrder.indexOf(toId);
    _notesOrder.insert(toIdx, fromId);
    _save(); notifyListeners();
  }

  void reorderTodo(int oldIndex, int newIndex) {
    if (_todosOrder.isEmpty) _todosOrder = todos.map((t) => t.id).toList();
    if (newIndex > oldIndex) newIndex -= 1;
    final id = _todosOrder.removeAt(oldIndex);
    _todosOrder.insert(newIndex, id);
    _save(); notifyListeners();
  }

  void reorderTodoById(String fromId, String toId) {
    if (_todosOrder.isEmpty) _todosOrder = todos.map((t) => t.id).toList();
    for (final id in [fromId, toId]) {
      if (!_todosOrder.contains(id)) _todosOrder.add(id);
    }
    final fromIdx = _todosOrder.indexOf(fromId);
    _todosOrder.removeAt(fromIdx);
    final toIdx = _todosOrder.indexOf(toId);
    _todosOrder.insert(toIdx, fromId);
    _save(); notifyListeners();
  }

  void reorderEvent(int oldIndex, int newIndex) {
    if (_eventsOrder.isEmpty) _eventsOrder = events.map((e) => e.id).toList();
    if (newIndex > oldIndex) newIndex -= 1;
    final id = _eventsOrder.removeAt(oldIndex);
    _eventsOrder.insert(newIndex, id);
    _save(); notifyListeners();
  }

  void reorderEventById(String fromId, String toId) {
    if (_eventsOrder.isEmpty) _eventsOrder = events.map((e) => e.id).toList();
    for (final id in [fromId, toId]) {
      if (!_eventsOrder.contains(id)) _eventsOrder.add(id);
    }
    final fromIdx = _eventsOrder.indexOf(fromId);
    _eventsOrder.removeAt(fromIdx);
    final toIdx = _eventsOrder.indexOf(toId);
    _eventsOrder.insert(toIdx, fromId);
    _save(); notifyListeners();
  }

  // Tab
  int currentTab = 2; // 0=calendar,1=events,2=notes,3=todos

  // Active category filter
  String notesFilter = 'Все';
  String todosFilter = 'Все';
  String eventsFilter = 'Все';

  // Data
  List<Note> notes = [];
  List<TodoGroup> todos = [];
  List<AppEvent> events = [];

  // Folders (tags) — dynamic, per section, user-managed order
  List<String> noteFolders  = ['Работа', 'Личное', 'Идеи', 'Путешествия', 'Рецепты'];
  List<String> todoFolders  = ['Работа', 'Дом', 'Личное', 'Спорт'];
  List<String> eventFolders = ['Работа', 'Личное', 'Праздники', 'Здоровье'];

  // Hidden folders (not shown in filter rows)
  Set<String> noteHidden  = {};
  Set<String> todoHidden  = {};
  Set<String> eventHidden = {};

  // Custom folder colors: key = folderName, value = color hex string e.g. '#FF5733'
  Map<String, String> folderColors = {};

  Color folderColor(String name) {
    if (folderColors.containsKey(name)) {
      final hex = folderColors[name]!.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    }
    return AppColors.categoryColor(name);
  }

  void setFolderColor(String name, Color color) {
    final hex = color.value.toRadixString(16).substring(2).toUpperCase();
    folderColors[name] = '#$hex';
    _saveFolders(); notifyListeners();
  }

  // Special items order: list of ('Все','','<folder>',...)
  // '' = no-tag (shown as '–')
  List<String> noteFilterOrder  = ['Все', ''];
  List<String> todoFilterOrder  = ['Все', ''];
  List<String> eventFilterOrder = ['Все', ''];

  List<String> get noteCategories  => _buildCategories(noteFilterOrder, noteFolders, noteHidden);
  List<String> get todoCategories  => _buildCategories(todoFilterOrder, todoFolders, todoHidden);
  List<String> get eventCategories => _buildCategories(eventFilterOrder, eventFolders, eventHidden);

  List<String> _buildCategories(List<String> order, List<String> folders, Set<String> hidden) {
    final result = <String>[];
    // First add items in order that are not hidden
    for (final item in order) {
      if (!hidden.contains(item)) result.add(item);
    }
    // Then add any folders not yet in order and not hidden
    for (final f in folders) {
      if (!order.contains(f) && !hidden.contains(f)) result.add(f);
    }
    return result;
  }

  // Full list for manager (including hidden, including special)
  List<String> get fullNoteFilterOrder  => [...noteFilterOrder,  ...noteFolders.where((f) => !noteFilterOrder.contains(f))];
  List<String> get fullTodoFilterOrder  => [...todoFilterOrder,  ...todoFolders.where((f) => !todoFilterOrder.contains(f))];
  List<String> get fullEventFilterOrder => [...eventFilterOrder, ...eventFolders.where((f) => !eventFilterOrder.contains(f))];

  Set<String> hiddenFor(int tab) {
    if (tab == 1) return noteHidden;
    if (tab == 2) return todoHidden;
    return eventHidden;
  }

  void toggleFolderVisibility(int tab, String folder) {
    final h = hiddenFor(tab);
    if (h.contains(folder)) {
      h.remove(folder);
    } else {
      h.add(folder);
    }
    _saveFolders(); notifyListeners();
  }

  void reorderFilterItem(int tab, int oldIndex, int newIndex) {
    List<String> order;
    List<String> folders;
    if (tab == 1) { order = noteFilterOrder; folders = noteFolders; }
    else if (tab == 2) { order = todoFilterOrder; folders = todoFolders; }
    else { order = eventFilterOrder; folders = eventFolders; }
    // Build full list
    final full = [...order, ...folders.where((f) => !order.contains(f))];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = full.removeAt(oldIndex);
    full.insert(newIndex, item);
    // Save back: special items go to order, folders stay in folders
    order.clear();
    for (final f in full) {
      if (f == 'Все' || f == '') {
        order.add(f);
      } else if (folders.contains(f)) order.add(f);
    }
    _saveFolders(); notifyListeners();
  }

  // Folder CRUD
  void addFolder(int tab, String name) {
    if (name.trim().isEmpty) return;
    final n = name.trim();
    if (tab == 1 && !noteFolders.contains(n))  { noteFolders.add(n); }
    if (tab == 2 && !todoFolders.contains(n))  { todoFolders.add(n); }
    if (tab == 0 && !eventFolders.contains(n)) { eventFolders.add(n); }
    _saveFolders(); notifyListeners();
  }

  void renameFolder(int tab, String old, String newName) {
    if (newName.trim().isEmpty) return;
    final n = newName.trim();
    void rename(List<String> list) {
      final i = list.indexOf(old);
      if (i >= 0) list[i] = n;
    }
    // Also rename in existing items
    if (tab == 1) {
      rename(noteFolders); rename(noteFilterOrder);
      for (var note in notes) { if (note.category == old) note.category = n; }
    }
    if (tab == 2) {
      rename(todoFolders); rename(todoFilterOrder);
      for (var t in todos) { if (t.category == old) t.category = n; }
    }
    if (tab == 0) {
      rename(eventFolders); rename(eventFilterOrder);
      for (var e in events) { if (e.category == old) e.category = n; }
    }
    _saveFolders(); _save(); notifyListeners();
  }

  void deleteFolder(int tab, String name) {
    if (tab == 1) {
      noteFolders.remove(name);
      noteFilterOrder.remove(name);
      for (var n in notes) { if (n.category == name) n.category = ''; }
    }
    if (tab == 2) {
      todoFolders.remove(name);
      todoFilterOrder.remove(name);
      for (var t in todos) { if (t.category == name) t.category = ''; }
    }
    if (tab == 0) {
      eventFolders.remove(name);
      eventFilterOrder.remove(name);
      for (var e in events) { if (e.category == name) e.category = ''; }
    }
    folderColors.remove(name);
    if (notesFilter == name)  notesFilter = 'Все';
    if (todosFilter == name)  todosFilter = 'Все';
    if (eventsFilter == name) eventsFilter = 'Все';
    _saveFolders(); _save(); notifyListeners();
  }

  void reorderFolders(int tab, int oldIndex, int newIndex) {
    // reorderFolders теперь делегирует reorderFilterItem
    reorderFilterItem(tab, oldIndex, newIndex);
  }

  Future<void> _saveFolders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('noteFolders',     jsonEncode(noteFolders));
    await prefs.setString('todoFolders',     jsonEncode(todoFolders));
    await prefs.setString('eventFolders',    jsonEncode(eventFolders));
    await prefs.setString('noteFilterOrder', jsonEncode(noteFilterOrder));
    await prefs.setString('todoFilterOrder', jsonEncode(todoFilterOrder));
    await prefs.setString('eventFilterOrder',jsonEncode(eventFilterOrder));
    await prefs.setString('folderColors', jsonEncode(folderColors));
    await prefs.setString('noteHidden',  jsonEncode(noteHidden.toList()));
    await prefs.setString('todoHidden',  jsonEncode(todoHidden.toList()));
    await prefs.setString('eventHidden', jsonEncode(eventHidden.toList()));
  }

  AppState() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool('darkMode') ?? true;
    _userName = prefs.getString('userName') ?? '';
    _notesView = prefs.getInt('notesView') ?? 1;
    _todosView = prefs.getInt('todosView') ?? 1;
    _eventsView = prefs.getInt('eventsView') ?? 1;
    _notesSort = prefs.getString('notesSort') ?? 'date';
    _todosSort = prefs.getString('todosSort') ?? 'date';
    _eventsSort = prefs.getString('eventsSort') ?? 'date';
    final orderJson = prefs.getString('notesOrder');
    if (orderJson != null) _notesOrder = List<String>.from(jsonDecode(orderJson));
    final todosOrderJson = prefs.getString('todosOrder');
    if (todosOrderJson != null) _todosOrder = List<String>.from(jsonDecode(todosOrderJson));
    final eventsOrderJson = prefs.getString('eventsOrder');
    if (eventsOrderJson != null) _eventsOrder = List<String>.from(jsonDecode(eventsOrderJson));
    final nfJson = prefs.getString('noteFolders');
    if (nfJson != null) noteFolders = List<String>.from(jsonDecode(nfJson));
    final tfJson = prefs.getString('todoFolders');
    if (tfJson != null) todoFolders = List<String>.from(jsonDecode(tfJson));
    final efJson = prefs.getString('eventFolders');
    if (efJson != null) eventFolders = List<String>.from(jsonDecode(efJson));
    final nfoJson = prefs.getString('noteFilterOrder');
    if (nfoJson != null) noteFilterOrder = List<String>.from(jsonDecode(nfoJson));
    final tfoJson = prefs.getString('todoFilterOrder');
    if (tfoJson != null) todoFilterOrder = List<String>.from(jsonDecode(tfoJson));
    final efoJson = prefs.getString('eventFilterOrder');
    if (efoJson != null) eventFilterOrder = List<String>.from(jsonDecode(efoJson));
    final fcJson = prefs.getString('folderColors');
    if (fcJson != null) folderColors = Map<String, String>.from(jsonDecode(fcJson));
    final nhJson = prefs.getString('noteHidden');
    if (nhJson != null) noteHidden = Set<String>.from(jsonDecode(nhJson));
    final thJson = prefs.getString('todoHidden');
    if (thJson != null) todoHidden = Set<String>.from(jsonDecode(thJson));
    final ehJson = prefs.getString('eventHidden');
    if (ehJson != null) eventHidden = Set<String>.from(jsonDecode(ehJson));

    final notesJson = prefs.getString('notes');
    if (notesJson != null) {
      final list = jsonDecode(notesJson) as List;
      notes = list.map((e) => Note.fromJson(e)).toList();
    } else {
      _seedNotes();
    }

    final todosJson = prefs.getString('todos');
    if (todosJson != null) {
      final list = jsonDecode(todosJson) as List;
      todos = list.map((e) => TodoGroup.fromJson(e)).toList();
    } else {
      _seedTodos();
    }

    final eventsJson = prefs.getString('events');
    if (eventsJson != null) {
      final list = jsonDecode(eventsJson) as List;
      events = list.map((e) => AppEvent.fromJson(e)).toList();
    } else {
      _seedEvents();
    }

    notifyListeners();
  }

  void _seedNotes() {
    notes = [
      Note(
        id: '0',
        title: 'Добро пожаловать в Органайзер 👋',
        body: 'Это пример заметки. Здесь можно писать всё что угодно — идеи, планы, рецепты, впечатления.\n\nИспользуй три режима просмотра в правом верхнем углу:\n• Крупный список — максимум деталей\n• Сетка — две колонки, быстрый обзор\n• Мелкий список — только заголовки\n\nНажми на любую заметку чтобы открыть и отредактировать её. Тег выбирается в правом верхнем углу редактора.',
        category: 'Личное',
        createdAt: DateTime.now(),
      ),
      Note(id: '1', title: 'Идеи для стартапа', body: 'Добавить новый раздел навигации, переработать онбординг, интеграция с календарём', category: 'Работа', createdAt: DateTime.now()),
      Note(id: '2', title: 'Список покупок', body: 'Молоко · Авокадо · Кофе · Хлеб · Яйца · Масло', category: 'Личное', createdAt: DateTime.now().subtract(const Duration(days: 1))),
      Note(id: '3', title: 'План поездки', body: 'Стамбул · 20–25 мая · Отель Bosphorus · Экскурсии', category: 'Путешествия', createdAt: DateTime.now().subtract(const Duration(days: 6))),
      Note(id: '4', title: 'Рецепт карбонары', body: '200г спагетти · гуанчале · яйца · пекорино романо', category: 'Рецепты', createdAt: DateTime(2023, 11, 15)),
    ];
  }

  void _seedTodos() {
    todos = [
      TodoGroup(id: '1', name: 'Рабочий проект', category: 'Работа', items: [
        TodoItem(text: 'Дизайн макетов', done: true),
        TodoItem(text: 'Вёрстка'),
        TodoItem(text: 'Тестирование'),
        TodoItem(text: 'Деплой'),
      ]),
      TodoGroup(id: '2', name: 'Домашние дела', category: 'Дом', items: [
        TodoItem(text: 'Уборка'),
        TodoItem(text: 'Полить цветы'),
        TodoItem(text: 'Оплатить счета'),
      ]),
    ];
  }

  void _seedEvents() {
    final now = DateTime.now();
    events = [
      AppEvent(
        id: '1',
        title: 'Встреча с командой',
        body: 'Обсудить прогресс по проекту',
        category: 'Работа',
        reminderDate: now.add(const Duration(days: 2)),
        repeat: RepeatInterval.weekly,
        tasks: [EventTask(text: 'Подготовить презентацию'), EventTask(text: 'Собрать метрики')],
      ),
      AppEvent(
        id: '2',
        title: 'День рождения Маши',
        body: 'Не забыть купить подарок',
        category: 'Личное',
        reminderDate: now.add(const Duration(days: 5)),
        repeat: RepeatInterval.yearly,
      ),
      AppEvent(
        id: '3',
        title: 'Врач — осмотр',
        category: 'Здоровье',
        reminderDate: now.add(const Duration(days: 14)),
        repeat: RepeatInterval.none,
      ),
    ];
  }

  void toggleHidden(int tab, String key) {
    final set = tab == 0 ? eventHidden : (tab == 1 ? noteHidden : todoHidden);
    if (set.contains(key)) {
      set.remove(key);
    } else {
      set.add(key);
    }
    refresh();
    _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
    await prefs.setString('userName', _userName);
    await prefs.setString('notes', jsonEncode(notes.map((n) => n.toJson()).toList()));
    await prefs.setString('todos', jsonEncode(todos.map((t) => t.toJson()).toList()));
    await prefs.setString('events', jsonEncode(events.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveViews() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notesView', _notesView);
    await prefs.setInt('todosView', _todosView);
    await prefs.setInt('eventsView', _eventsView);
    await prefs.setString('notesSort', _notesSort);
    await prefs.setString('todosSort', _todosSort);
    await prefs.setString('eventsSort', _eventsSort);
    await prefs.setString('notesOrder', jsonEncode(_notesOrder));
    await prefs.setString('todosOrder', jsonEncode(_todosOrder));
    await prefs.setString('eventsOrder', jsonEncode(_eventsOrder));
  }

  void refresh() {
    notifyListeners();
  }

  void toggleTheme() {
    _darkMode = !_darkMode;
    _save();
    notifyListeners();
  }

  void setUserName(String name) {
    _userName = name;
    _save();
    notifyListeners();
  }

  // Notes CRUD
  void addNote(Note n) { notes.insert(0, n); _save(); notifyListeners(); }
  void updateNote(Note n) {
    final i = notes.indexWhere((x) => x.id == n.id);
    if (i >= 0) notes[i] = n;
    _save(); notifyListeners();
  }
  void deleteNote(String id) { notes.removeWhere((n) => n.id == id); _save(); notifyListeners(); }

  // Todos CRUD
  void addTodo(TodoGroup g) { todos.insert(0, g); _save(); notifyListeners(); }
  void updateTodo(TodoGroup g) {
    final i = todos.indexWhere((x) => x.id == g.id);
    if (i >= 0) todos[i] = g;
    _save(); notifyListeners();
  }
  void deleteTodo(String id) { todos.removeWhere((t) => t.id == id); _save(); notifyListeners(); }
  void toggleTodoItem(String groupId, int idx) {
    final matches = todos.where((t) => t.id == groupId);
    if (matches.isEmpty) return;
    final g = matches.first;
    if (idx < 0 || idx >= g.items.length) return;
    g.items[idx].done = !g.items[idx].done;
    _save(); notifyListeners();
  }

  // Events CRUD
  void addEvent(AppEvent e) { events.insert(0, e); _save(); notifyListeners(); }
  void updateEvent(AppEvent e) {
    final i = events.indexWhere((x) => x.id == e.id);
    if (i >= 0) events[i] = e;
    _save(); notifyListeners();
  }
  void deleteEvent(String id) { events.removeWhere((e) => e.id == id); _save(); notifyListeners(); }
  void toggleEventTask(String eventId, int idx) {
    final matches = events.where((x) => x.id == eventId);
    if (matches.isEmpty) return;
    final e = matches.first;
    if (idx < 0 || idx >= e.tasks.length) return;
    e.tasks[idx].done = !e.tasks[idx].done;
    _save(); notifyListeners();
  }

  List<Note> filteredNotes(String query) {
    var result = notes.where((n) {
      final matchCat = notesFilter == 'Все' || (notesFilter == '' ? n.category.isEmpty : n.category == notesFilter);
      final matchQ = query.isEmpty ||
          n.title.toLowerCase().contains(query.toLowerCase()) ||
          n.body.toLowerCase().contains(query.toLowerCase());
      return matchCat && matchQ;
    }).toList();

    if (_notesSort == 'manual' && _notesOrder.isNotEmpty) {
      result.sort((a, b) {
        final ai = _notesOrder.indexOf(a.id);
        final bi = _notesOrder.indexOf(b.id);
        if (ai == -1 && bi == -1) return 0;
        if (ai == -1) return 1;
        if (bi == -1) return -1;
        return ai.compareTo(bi);
      });
    } else {
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return result;
  }

  List<TodoGroup> filteredTodos(String query) {
    var result = todos.where((g) {
      final matchCat = todosFilter == 'Все' || (todosFilter == '' ? g.category.isEmpty : g.category == todosFilter);
      final matchQ = query.isEmpty || g.name.toLowerCase().contains(query.toLowerCase());
      return matchCat && matchQ;
    }).toList();
    if (_todosSort == 'manual' && _todosOrder.isNotEmpty) {
      result.sort((a, b) {
        final ai = _todosOrder.indexOf(a.id);
        final bi = _todosOrder.indexOf(b.id);
        if (ai == -1 && bi == -1) return 0;
        if (ai == -1) return 1;
        if (bi == -1) return -1;
        return ai.compareTo(bi);
      });
    } else {
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return result;
  }

  List<AppEvent> filteredEvents(String query) {
    var result = events.where((e) {
      final matchCat = eventsFilter == 'Все' || (eventsFilter == '' ? e.category.isEmpty : e.category == eventsFilter);
      final matchQ = query.isEmpty || e.title.toLowerCase().contains(query.toLowerCase()) || e.body.toLowerCase().contains(query.toLowerCase());
      return matchCat && matchQ;
    }).toList();
    if (_eventsSort == 'manual' && _eventsOrder.isNotEmpty) {
      result.sort((a, b) {
        final ai = _eventsOrder.indexOf(a.id);
        final bi = _eventsOrder.indexOf(b.id);
        if (ai == -1 && bi == -1) return 0;
        if (ai == -1) return 1;
        if (bi == -1) return -1;
        return ai.compareTo(bi);
      });
    } else {
      result.sort((a, b) {
        final ad = a.reminderDate;
        final bd = b.reminderDate;
        if (ad == null && bd == null) return b.createdAt.compareTo(a.createdAt);
        if (ad == null) return 1;
        if (bd == null) return -1;
        return ad.compareTo(bd);
      });
    }
    return result;
  }

  List<AppEvent> eventsInMonth(DateTime month) {
    return events.where((e) {
      if (e.reminderDate == null) return false;
      return e.reminderDate!.year == month.year && e.reminderDate!.month == month.month;
    }).toList();
  }

  List<TodoGroup> todosInMonth(DateTime month) {
    return todos.where((t) {
      return t.createdAt.year == month.year && t.createdAt.month == month.month;
    }).toList();
  }
}
