import 'user_model.dart';
import 'task_model.dart';

class ProjectModel {
  final String id;
  final String name;
  final String description;
  final String status;
  final String ownerId;
  final UserModel? owner;
  final String? deadline;
  final List<TaskModel> tasks;
  final String createdAt;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.ownerId,
    this.owner,
    this.deadline,
    this.tasks = const [],
    required this.createdAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> j) => ProjectModel(
    id: j['id'] ?? '',
    name: j['name'] ?? '',
    description: j['description'] ?? '',
    status: j['status'] ?? 'active',
    ownerId: j['owner_id'] ?? '',
    owner: j['owner'] != null ? UserModel.fromJson(j['owner']) : null,
    deadline: j['deadline'],
    tasks: (j['tasks'] as List<dynamic>? ?? []).map((t) => TaskModel.fromJson(t)).toList(),
    createdAt: j['created_at'] ?? '',
  );
}
