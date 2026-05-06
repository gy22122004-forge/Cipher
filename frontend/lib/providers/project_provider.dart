import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/project_model.dart';
import '../data/services/api_service.dart';
import '../core/constants/api_constants.dart';

final projectsProvider = FutureProvider<List<ProjectModel>>((ref) async {
  final res = await ApiService().get(Endpoints.projects);
  final list = res.data['data'] as List<dynamic>;
  return list.map((j) => ProjectModel.fromJson(j)).toList();
});

final projectDetailProvider = FutureProvider.family<ProjectModel, String>((ref, id) async {
  final res = await ApiService().get(Endpoints.project(id));
  return ProjectModel.fromJson(res.data['data']);
});

final dashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ApiService().get(Endpoints.dashboard);
  return Map<String, dynamic>.from(res.data['data']);
});
