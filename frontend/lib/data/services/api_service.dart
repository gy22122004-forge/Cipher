import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _authHeader() async {
    final token = await _getToken();
    if (token == null) return {};
    return {'Authorization': 'Bearer $token'};
  }

  Future<Response> get(String url) async =>
      _dio.get(url, options: Options(headers: await _authHeader()));

  Future<Response> post(String url, Map<String, dynamic> data) async =>
      _dio.post(url, data: jsonEncode(data), options: Options(headers: await _authHeader()));

  Future<Response> put(String url, Map<String, dynamic> data) async =>
      _dio.put(url, data: jsonEncode(data), options: Options(headers: await _authHeader()));

  Future<Response> delete(String url) async =>
      _dio.delete(url, options: Options(headers: await _authHeader()));
}
