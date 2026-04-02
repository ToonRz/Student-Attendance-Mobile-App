import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  factory ApiException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('Connection timed out. Please try again.');
      case DioExceptionType.connectionError:
        return ApiException('Cannot connect to server. Check your internet connection.');
      case DioExceptionType.badResponse:
        final data = error.response?.data;
        final message = data is Map ? data['message'] ?? 'Server error' : 'Server error';
        return ApiException(message, statusCode: error.response?.statusCode);
      default:
        return ApiException('Something went wrong. Please try again.');
    }
  }

  @override
  String toString() => message;
}
