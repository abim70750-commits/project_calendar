/// A checklist item belonging to a project.
class Subtask {
  final String id;
  final String projectId;
  final String title;
  final bool isDone;
  final int order;

  const Subtask({
    required this.id,
    required this.projectId,
    required this.title,
    this.isDone = false,
    this.order = 0,
  });

  Subtask copyWith({String? title, bool? isDone, int? order}) => Subtask(
        id: id,
        projectId: projectId,
        title: title ?? this.title,
        isDone: isDone ?? this.isDone,
        order: order ?? this.order,
      );

  // "order" is a reserved SQL word, so the column/key is sortOrder.
  Map<String, Object?> toMap() => {
        'id': id,
        'projectId': projectId,
        'title': title,
        'isDone': isDone ? 1 : 0,
        'sortOrder': order,
      };

  factory Subtask.fromMap(Map<String, Object?> m) => Subtask(
        id: m['id'] as String,
        projectId: m['projectId'] as String,
        title: m['title'] as String,
        isDone: m['isDone'] == 1 || m['isDone'] == true,
        order: (m['sortOrder'] as num?)?.toInt() ?? 0,
      );
}
