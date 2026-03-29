// ─── Note ───────────────────────────────────────────────
class Note {
  String id;
  String title;
  String body;
  String category;
  DateTime createdAt;

  Note({
    required this.id,
    required this.title,
    this.body = '',
    this.category = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'category': category,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Note.fromJson(Map<String, dynamic> j) => Note(
    id: j['id'],
    title: j['title'],
    body: j['body'] ?? '',
    category: j['category'] ?? '',
    createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
  );
}

// ─── TodoItem ────────────────────────────────────────────
class TodoItem {
  String text;
  bool done;
  TodoItem({required this.text, this.done = false});

  Map<String, dynamic> toJson() => {'text': text, 'done': done};
  factory TodoItem.fromJson(Map<String, dynamic> j) =>
      TodoItem(text: j['text'] ?? '', done: j['done'] ?? false);
}

class TodoGroup {
  String id;
  String name;
  String category;
  List<TodoItem> items;
  DateTime createdAt;

  TodoGroup({
    required this.id,
    required this.name,
    this.category = '',
    List<TodoItem>? items,
    DateTime? createdAt,
  })  : items = items ?? [],
        createdAt = createdAt ?? DateTime.now();

  int get total => items.length;
  int get doneCount => items.where((i) => i.done).length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'items': items.map((i) => i.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory TodoGroup.fromJson(Map<String, dynamic> j) => TodoGroup(
    id: j['id'],
    name: j['name'],
    category: j['category'] ?? '',
    items: (j['items'] as List? ?? []).map((e) => TodoItem.fromJson(e)).toList(),
    createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
  );
}

// ─── Event ───────────────────────────────────────────────
enum RepeatInterval { none, daily, weekly, monthly, yearly, custom }

class AppEvent {
  String id;
  String title;
  String body;
  String category;
  DateTime? reminderDate;
  RepeatInterval repeat;
  int? customDays; // for repeat == custom
  List<EventTask> tasks;
  DateTime createdAt;

  AppEvent({
    required this.id,
    required this.title,
    this.body = '',
    this.category = '',
    this.reminderDate,
    this.repeat = RepeatInterval.none,
    this.customDays,
    List<EventTask>? tasks,
    DateTime? createdAt,
  })  : tasks = tasks ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'category': category,
    'reminderDate': reminderDate?.toIso8601String(),
    'repeat': repeat.index,
    'customDays': customDays,
    'tasks': tasks.map((t) => t.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory AppEvent.fromJson(Map<String, dynamic> j) => AppEvent(
    id: j['id'],
    title: j['title'],
    body: j['body'] ?? '',
    category: j['category'] ?? '',
    reminderDate: j['reminderDate'] != null ? DateTime.tryParse(j['reminderDate']) : null,
    repeat: RepeatInterval.values[j['repeat'] ?? 0],
    customDays: j['customDays'],
    tasks: (j['tasks'] as List? ?? []).map((e) => EventTask.fromJson(e)).toList(),
    createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
  );
}

class EventTask {
  String text;
  bool done;
  EventTask({required this.text, this.done = false});
  Map<String, dynamic> toJson() => {'text': text, 'done': done};
  factory EventTask.fromJson(Map<String, dynamic> j) =>
      EventTask(text: j['text'] ?? '', done: j['done'] ?? false);
}
