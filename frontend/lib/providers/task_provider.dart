import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/task_model.dart';
import '../data/services/api_service.dart';
import '../core/constants/api_constants.dart';

final tasksByProjectProvider = FutureProvider.family<List<TaskModel>, String>((ref, projectId) async {
  final res = await ApiService().get(Endpoints.projectTasks(projectId));
  final list = res.data['data'] as List<dynamic>;
  return list.map((j) => TaskModel.fromJson(j)).toList();
});
