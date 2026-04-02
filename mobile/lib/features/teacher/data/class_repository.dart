import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/constants/api_constants.dart';

class ClassRepository {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> createClass(String name, String subject) async {
    try {
      final response = await _api.post(ApiConstants.classes, data: {
        'name': name,
        'subject': subject,
      });
      return response.data['data'];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<dynamic>> getTeacherClasses() async {
    try {
      final response = await _api.get(ApiConstants.classes);
      return response.data['data'];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> getClassDetail(String classId) async {
    try {
      final response = await _api.get('${ApiConstants.classes}/$classId');
      return response.data['data'];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<dynamic>> getClassStudents(String classId) async {
    try {
      final response = await _api.get('${ApiConstants.classes}/$classId/students');
      return response.data['data'];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> getAttendanceReport(String classId) async {
    try {
      final response = await _api.get('${ApiConstants.attendanceReport}/$classId');
      return response.data['data'];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
