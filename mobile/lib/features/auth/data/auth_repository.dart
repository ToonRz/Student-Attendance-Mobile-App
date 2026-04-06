import 'package:dio/dio.dart';
import 'package:student_attendance/core/network/api_client.dart';
import 'package:student_attendance/core/network/api_exceptions.dart';
import 'package:student_attendance/core/constants/api_constants.dart';

class AuthRepository {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> login(String email, String password, {String? deviceId}) async {
    try {
      final response = await _api.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
        'deviceId': deviceId,
      });
      final data = response.data['data'];
      await _api.saveToken(data['token']);
      return data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String role, {
    String? deviceId,
  }) async {
    try {
      final response = await _api.post(ApiConstants.register, data: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'deviceId': deviceId,
      });
      final data = response.data['data'];
      await _api.saveToken(data['token']);
      return data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _api.get(ApiConstants.me);
      return response.data['data'];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> logout() async {
    await _api.clearToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await _api.getToken();
    return token != null;
  }
}
