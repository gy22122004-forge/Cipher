import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user_model.dart';
import '../data/services/api_service.dart';
import '../core/constants/api_constants.dart';

class AuthState {
  final UserModel? user;
  final String? token;
  final bool loading;
  final String? error;

  const AuthState({this.user, this.token, this.loading = false, this.error});

  bool get isAuthenticated => token != null && user != null;

  AuthState copyWith({UserModel? user, String? token, bool? loading, String? error}) =>
      AuthState(
        user: user ?? this.user,
        token: token ?? this.token,
        loading: loading ?? this.loading,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  final _api = ApiService();

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      try {
        final res = await _api.get(Endpoints.me);
        if (res.statusCode == 200) {
          final user = UserModel.fromJson(res.data['data']);
          state = AuthState(user: user, token: token);
        }
      } catch (_) {
        await prefs.remove('token');
      }
    }
  }

  Future<String?> login(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await _api.post(Endpoints.login, {'email': email, 'password': password});
      final data = res.data['data'];
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      state = AuthState(user: user, token: token);
      return null;
    } catch (e) {
      final msg = _parseError(e);
      state = state.copyWith(loading: false, error: msg);
      return msg;
    }
  }

  Future<String?> register(String name, String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await _api.post(Endpoints.register, {'name': name, 'email': email, 'password': password});
      final data = res.data['data'];
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      state = AuthState(user: user, token: token);
      return null;
    } catch (e) {
      final msg = _parseError(e);
      state = state.copyWith(loading: false, error: msg);
      return msg;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    state = const AuthState();
  }

  String _parseError(dynamic e) {
    if (e is Exception) {
      final str = e.toString();
      if (str.contains('error:')) return str.split('error:').last.trim();
    }
    return 'Something went wrong. Please try again.';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((_) => AuthNotifier());
