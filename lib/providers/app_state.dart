import 'package:flutter/material.dart';
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
  int notesView = 1;
  int todosView = 1;
  int eventsView = 1;

  // Tab
  int currentTab = 1; // 0=events,1=notes,2=todos,3=calendar

  // Active category filter
  String notesFilter = 'Все';
  String todosFilter = 'Все';
  String eventsFilter = 'Все';

  // Data
  List<Note> notes = [];
  List<TodoGroup> todos = [];
  List<AppEvent> events = [];

  // Categories
  static const noteCategories = ['Все', 'Работа', 'Личное', 'Идеи', 'Путешествия', 'Рецепты'];
  static const todoCategories = ['Все', 'Работа', 'Дом', 'Личное', 'Спорт'];
  static const eventCategories = ['Все', 'Работа', 'Личное', 'Праздники', 'Здоровье'];

  AppState() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool('darkMode') ?? true;
    _userName = prefs.getString('userName') ?? '';

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
      Note(id: '1', title: 'Идеи для стартапа', body: 'Добавить новый раздел навигации, переработать онбординг, интеграция с календарём', category: 'Работа', createdAt: DateTime.now()),
      Note(id: '2', title: 'Список покупок', body: 'Молоко · Авокадо · Кофе · Хлеб · Яйца · Масло', category: 'Личное', createdAt: DateTime.now().subtract(const Duration(days: 1))),
      Note(id: '3', title: 'План поездки', body: 'Стамбул · 20–25 мая · Отель Bosphorus · Экскурсии', category: 'Путешествия', createdAt: DateTime.now().subtract(const Duration(days: 6))),
      Note(id: '4', title: 'Рецепт карбонары', body: '200г спагетти · гуанчале · яйца · пекорино романо', category: 'Рецепты', createdAt: DateTime.now().subtract(const Duration(days: 10))),
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

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
    await prefs.setString('userName', _userName);
    await prefs.setString('notes', jsonEncode(notes.map((n) => n.toJson()).toList()));
    await prefs.setString('todos', jsonEncode(todos.map((t) => t.toJson()).toList()));
    await prefs.setString('events', jsonEncode(events.map((e) => e.toJson()).toList()));
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
    return notes.where((n) {
      final matchCat = notesFilter == 'Все' || n.category == notesFilter;
      final matchQ = query.isEmpty || n.title.toLowerCase().contains(query.toLowerCase()) || n.body.toLowerCase().contains(query.toLowerCase());
      return matchCat && matchQ;
    }).toList();
  }

  List<TodoGroup> filteredTodos(String query) {
    return todos.where((g) {
      final matchCat = todosFilter == 'Все' || g.category == todosFilter;
      final matchQ = query.isEmpty || g.name.toLowerCase().contains(query.toLowerCase());
      return matchCat && matchQ;
    }).toList();
  }

  List<AppEvent> filteredEvents(String query) {
    return events.where((e) {
      final matchCat = eventsFilter == 'Все' || e.category == eventsFilter;
      final matchQ = query.isEmpty || e.title.toLowerCase().contains(query.toLowerCase()) || e.body.toLowerCase().contains(query.toLowerCase());
      return matchCat && matchQ;
    }).toList();
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
