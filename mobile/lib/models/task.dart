enum TaskStatus {
  todo('TODO', 'À faire'),
  inProgress('IN_PROGRESS', 'En cours'),
  done('DONE', 'Terminée');

  const TaskStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static TaskStatus fromApi(String value) => values.firstWhere(
    (status) => status.apiValue == value,
    orElse: () => TaskStatus.todo,
  );
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String? description;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
    id: (json['id'] as num).toInt(),
    title: json['title'] as String,
    description: json['description'] as String?,
    status: TaskStatus.fromApi(json['status'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.description,
    required this.status,
  });

  final String title;
  final String description;
  final TaskStatus status;

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description.trim().isEmpty ? null : description.trim(),
    'status': status.apiValue,
  };
}
