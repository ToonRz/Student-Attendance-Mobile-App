import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/constants/api_constants.dart';

class SessionRepository {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> openSession({
    required String classId,
    required int durationMin,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _api.post(ApiConstants.sessions, data: {
        'classId': classId,
        'durationMin': durationMin,
        'latitude': latitude,
        'longitude': longitude,
      });
      return response.data['data'];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> getSessionQr(String sessionId) async {
    try {
      final response = await _api.get('${ApiConstants.sessions}/$sessionId/qr');
      return response.data['data'];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> closeSession(String sessionId) async {
    try {
      await _api.put('${ApiConstants.sessions}/$sessionId/close');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<dynamic>> getClassSessions(String classId) async {
    try {
      final response = await _api.get('${ApiConstants.sessions}/class/$classId');
      return response.data['data'];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> getSessionAttendance(String sessionId) async {
    try {
      final response = await _api.get('${ApiConstants.attendanceSession}/$sessionId');
      return response.data['data'];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
