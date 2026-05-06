import 'user_model.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String projectId;
  final String? assigneeId;
  final UserModel? assignee;
  final String createdAt;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.projectId,
    this.assigneeId,
    this.assignee,
    required this.createdAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> j) => TaskModel(
    id: j['id'] ?? '',
    title: j['title'] ?? '',
    description: j['description'] ?? '',
    status: j['status'] ?? 'todo',
    priority: j['priority'] ?? 'medium',
    projectId: j['project_id'] ?? '',
    assigneeId: j['assignee_id'],
    assignee: j['assignee'] != null ? UserModel.fromJson(j['assignee']) : null,
    createdAt: j['created_at'] ?? '',
  );
}
