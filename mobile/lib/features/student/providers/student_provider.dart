import 'package:flutter/material.dart';
import '../data/student_repository.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/services/device_service.dart';

class StudentProvider extends ChangeNotifier {
  final StudentRepository _repo = StudentRepository();

  List<dynamic> _classes = [];
  Map<String, dynamic>? _attendance;
  bool _isLoading = false;
  String? _error;
  bool _checkInSuccess = false;

  List<dynamic> get classes => _classes;
  Map<String, dynamic>? get attendance => _attendance;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get checkInSuccess => _checkInSuccess;

  Future<void> loadClasses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _classes = await _repo.getMyClasses();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load classes';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> joinClass(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repo.joinClass(code);
      await loadClasses();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkIn({
    required String sessionId,
    required String qrToken,
    required double latitude,
    required double longitude,
  }) async {
    _isLoading = true;
    _error = null;
    _checkInSuccess = false;
    notifyListeners();

    try {
      final deviceId = await DeviceService.getDeviceId();
      await _repo.checkIn(
        sessionId: sessionId,
        qrToken: qrToken,
        latitude: latitude,
        longitude: longitude,
        deviceId: deviceId,
      );
      _checkInSuccess = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadAttendance(String classId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _attendance = await _repo.getMyAttendance(classId);
    } on ApiException catch (e) {
      _error = e.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  void resetCheckIn() {
    _checkInSuccess = false;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
