// API base URL — update this after deploying the backend to Render.
// For local dev:  http://localhost:8080/api/v1
// For production: https://cipher-api.onrender.com/api/v1
const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://cipher-api.onrender.com/api/v1',
);

class Endpoints {
  static const String register     = '$baseUrl/auth/register';
  static const String login        = '$baseUrl/auth/login';
  static const String me           = '$baseUrl/users/me';
  static const String users        = '$baseUrl/users';
  static const String projects     = '$baseUrl/projects';
  static const String dashboard    = '$baseUrl/dashboard/stats';

  static String project(String id)      => '$baseUrl/projects/$id';
  static String projectTasks(String id) => '$baseUrl/projects/$id/tasks';
  static String task(String id)         => '$baseUrl/tasks/$id';
  static String userRole(String id)     => '$baseUrl/users/$id/role';
}
