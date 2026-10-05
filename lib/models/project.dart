import 'subtask.dart';
import 'tag.dart';

/// Sorted by importance; [weight] is what sorting uses.
/// Display names live in l10n_extensions.dart so they can be translated.
enum Priority {
  high(3),
  medium(2),
  low(1),
  none(0);

  const Priority(this.weight);

  final int weight;

  static Priority parse(Object? raw) => Priority.values
      .firstWhere((p) => p.name == raw, orElse: () => Priority.none);
}

/// Days-before-deadline used when a project has no custom reminders: H-1 and day H.
const List<int> kDefaultReminders = [1, 0];

const int kMaxReminders = 3;

/// A missing value (old rows / old backups) means "defaults"; an empty string
/// means the user deliberately removed every reminder.
List<int> parseReminders(Object? raw) {
  if (raw is! String) return List<int>.of(kDefaultReminders);
  final out = <int>[];
  for (final part in raw.split(',')) {
    final n = int.tryParse(part.trim());
    if (n != null && n >= 0 && n <= 365 && !out.contains(n)) out.add(n);
  }
  return out.take(kMaxReminders).toList();
}

/// A project with a date range, markdown notes, checklist, priority and tags.
class Project {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime deadline;
  final int progress;
  final String notes;
  final List<Subtask> subtasks;
  final bool isCompleted;
  final bool isOverdue;
  final Priority priority;
  final List<Tag> tags;
  final bool isArchived;
  final List<int> reminderDays;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Project({
    required this.id,
    required this.name,
    required this.startDate,
    required this.deadline,
    this.progress = 0,
    this.notes = '',
    this.subtasks = const [],
    this.isCompleted = false,
    this.isOverdue = false,
    this.priority = Priority.none,
    this.tags = const [],
    this.isArchived = false,
    this.reminderDays = kDefaultReminders,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Project copyWith({
    String? name,
    DateTime? startDate,
    DateTime? deadline,
    int? progress,
    String? notes,
    List<Subtask>? subtasks,
    bool? isCompleted,
    bool? isOverdue,
    Priority? priority,
    List<Tag>? tags,
    bool? isArchived,
    List<int>? reminderDays,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? updatedAt,
  }) =>
      Project(
        id: id,
        name: name ?? this.name,
        startDate: startDate ?? this.startDate,
        deadline: deadline ?? this.deadline,
        progress: progress ?? this.progress,
        notes: notes ?? this.notes,
        subtasks: subtasks ?? this.subtasks,
        isCompleted: isCompleted ?? this.isCompleted,
        isOverdue: isOverdue ?? this.isOverdue,
        priority: priority ?? this.priority,
        tags: tags ?? this.tags,
        isArchived: isArchived ?? this.isArchived,
        reminderDays: reminderDays ?? this.reminderDays,
        // A nullable field needs an explicit "clear" switch, otherwise null means "keep".
        completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Row for the projects table. Subtasks and tags live in their own tables.
  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'startDate': startDate.toIso8601String(),
        'deadline': deadline.toIso8601String(),
        'progress': progress,
        'notes': notes,
        'isCompleted': isCompleted ? 1 : 0,
        'isOverdue': isOverdue ? 1 : 0,
        'priority': priority.name,
        'isArchived': isArchived ? 1 : 0,
        'customReminder': reminderDays.join(','),
        'completedAt': completedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  Map<String, Object?> toJson() => {
        ...toMap(),
        'subtasks': subtasks.map((s) => s.toMap()).toList(),
        'tags': tags.map((t) => t.toMap()).toList(),
      };

  factory Project.fromMap(
    Map<String, Object?> m,
    List<Subtask> subtasks, [
    List<Tag> tags = const [],
  ]) =>
      Project(
        id: m['id'] as String,
        name: m['name'] as String,
        startDate: DateTime.parse(m['startDate'] as String),
        deadline: DateTime.parse(m['deadline'] as String),
        progress: ((m['progress'] as num?)?.toInt() ?? 0).clamp(0, 100),
        notes: (m['notes'] as String?) ?? '',
        subtasks: subtasks,
        isCompleted: m['isCompleted'] == 1 || m['isCompleted'] == true,
        isOverdue: m['isOverdue'] == 1 || m['isOverdue'] == true,
        priority: Priority.parse(m['priority']),
        tags: tags,
        isArchived: m['isArchived'] == 1 || m['isArchived'] == true,
        reminderDays: parseReminders(m['customReminder']),
        completedAt: DateTime.tryParse((m['completedAt'] as String?) ?? ''),
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
      );

  factory Project.fromJson(Map<String, dynamic> j) {
    final rawSubs = (j['subtasks'] as List?) ?? const [];
    final subs = rawSubs
        .map((e) => Subtask.fromMap(Map<String, Object?>.from(e as Map)))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final rawTags = (j['tags'] as List?) ?? const [];
    final tags = rawTags
        .map((e) => Tag.fromMap(Map<String, Object?>.from(e as Map)))
        .toList();
    return Project.fromMap(Map<String, Object?>.from(j), subs, tags);
  }
}
