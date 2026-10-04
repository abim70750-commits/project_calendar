import 'subtask.dart';

/// A project with a date range, markdown notes and checklist.
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
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Row for the projects table (subtasks live in their own table).
  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'startDate': startDate.toIso8601String(),
        'deadline': deadline.toIso8601String(),
        'progress': progress,
        'notes': notes,
        'isCompleted': isCompleted ? 1 : 0,
        'isOverdue': isOverdue ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  Map<String, Object?> toJson() => {
        ...toMap(),
        'subtasks': subtasks.map((s) => s.toMap()).toList(),
      };

  factory Project.fromMap(Map<String, Object?> m, List<Subtask> subtasks) =>
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
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
      );

  factory Project.fromJson(Map<String, dynamic> j) {
    final raw = (j['subtasks'] as List?) ?? const [];
    final subs = raw
        .map((e) => Subtask.fromMap(Map<String, Object?>.from(e as Map)))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return Project.fromMap(Map<String, Object?>.from(j), subs);
  }
}
