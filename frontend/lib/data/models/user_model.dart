class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['id'] ?? '',
    name: j['name'] ?? '',
    email: j['email'] ?? '',
    role: j['role'] ?? 'member',
    createdAt: j['created_at'] ?? '',
  );

  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager' || role == 'admin';
}
