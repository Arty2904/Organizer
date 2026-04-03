// ─── Note ───────────────────────────────────────────────
class Note {
  String id;
  String title;
  String body;
  String category;
  DateTime createdAt;
  int colorIndex; // 0 = default, 1-21 = custom color

  Note({
    required this.id,
    required this.title,
    this.body = '',
    this.category = '',
    this.colorIndex = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'category': category,
    'colorIndex': colorIndex,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Note.fromJson(Map<String, dynamic> j) => Note(
    id: j['id'],
    title: j['title'],
    body: j['body'] ?? '',
    category: j['category'] ?? '',
    colorIndex: j['colorIndex'] ?? 0,
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
  int colorIndex;
  DateTime? dueDate;
  DateTime? reminderDate;
  RepeatInterval repeat;
  int? customDays;

  TodoGroup({
    required this.id,
    required this.name,
    this.category = '',
    List<TodoItem>? items,
    DateTime? createdAt,
    this.colorIndex = 0,
    this.dueDate,
    this.reminderDate,
    this.repeat = RepeatInterval.none,
    this.customDays,
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
    'colorIndex': colorIndex,
    'dueDate': dueDate?.toIso8601String(),
    'reminderDate': reminderDate?.toIso8601String(),
    'repeat': repeat.index,
    'customDays': customDays,
  };

  factory TodoGroup.fromJson(Map<String, dynamic> j) => TodoGroup(
    id: j['id'],
    name: j['name'],
    category: j['category'] ?? '',
    items: (j['items'] as List? ?? []).map((e) => TodoItem.fromJson(e)).toList(),
    createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
    colorIndex: j['colorIndex'] ?? 0,
    dueDate: j['dueDate'] != null ? DateTime.tryParse(j['dueDate']) : null,
    reminderDate: j['reminderDate'] != null ? DateTime.tryParse(j['reminderDate']) : null,
    repeat: RepeatInterval.values[j['repeat'] ?? 0],
    customDays: j['customDays'],
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
  int colorIndex;

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
    this.colorIndex = 0,
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
    'colorIndex': colorIndex,
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
    colorIndex: j['colorIndex'] ?? 0,
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
