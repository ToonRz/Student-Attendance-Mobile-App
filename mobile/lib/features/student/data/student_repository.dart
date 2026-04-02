import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/constants/api_constants.dart';

class StudentRepository {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> joinClass(String code) async {
    try {
      final response = await _api.post(ApiConstants.joinClass, data: {'code': code});
      return response.data['data'];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<dynamic>> getMyClasses() async {
    try {
      final response = await _api.get(ApiConstants.myClasses);
      return response.data['data'];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> checkIn({
    required String sessionId,
    required String qrToken,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _api.post(ApiConstants.checkIn, data: {
        'sessionId': sessionId,
        'qrToken': qrToken,
        'latitude': latitude,
        'longitude': longitude,
      });
      return response.data['data'];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> getMyAttendance(String classId) async {
    try {
      final response = await _api.get('${ApiConstants.attendanceStudent}/$classId');
      return response.data['data'];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
