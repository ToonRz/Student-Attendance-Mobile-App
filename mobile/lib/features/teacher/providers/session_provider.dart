import 'dart:async';
import 'package:flutter/material.dart';
import '../data/session_repository.dart';
import '../../../core/network/api_exceptions.dart';

class SessionProvider extends ChangeNotifier {
  final SessionRepository _repo = SessionRepository();

  Map<String, dynamic>? _activeSession;
  Map<String, dynamic>? _qrData;
  Map<String, dynamic>? _sessionAttendance;
  List<dynamic> _sessions = [];
  bool _isLoading = false;
  String? _error;
  Timer? _qrTimer;
  int _qrCountdown = 30;

  Map<String, dynamic>? get activeSession => _activeSession;
  Map<String, dynamic>? get qrData => _qrData;
  Map<String, dynamic>? get sessionAttendance => _sessionAttendance;
  List<dynamic> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get qrCountdown => _qrCountdown;

  Future<bool> openSession({
    required String classId,
    required int durationMin,
    required double latitude,
    required double longitude,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _activeSession = await _repo.openSession(
        classId: classId,
        durationMin: durationMin,
        latitude: latitude,
        longitude: longitude,
      );
      _isLoading = false;
      notifyListeners();

      // Start QR rotation
      await refreshQr();
      _startQrRotation();

      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshQr() async {
    if (_activeSession == null) return;

    try {
      _qrData = await _repo.getSessionQr(_activeSession!['id']);
      _qrCountdown = 30;
      notifyListeners();
    } on ApiException catch (e) {
      if (e.statusCode == 410) {
        // Session expired
        _activeSession = null;
        _qrData = null;
        stopQrRotation();
      }
      _error = e.message;
      notifyListeners();
    }
  }

  void _startQrRotation() {
    _qrTimer?.cancel();
    _qrTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _qrCountdown--;
      if (_qrCountdown <= 0) {
        refreshQr();
      }
      notifyListeners();
    });
  }

  void stopQrRotation() {
    _qrTimer?.cancel();
    _qrTimer = null;
  }

  Future<void> closeSession() async {
    if (_activeSession == null) return;

    try {
      await _repo.closeSession(_activeSession!['id']);
      stopQrRotation();
      _activeSession = null;
      _qrData = null;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  Future<void> loadSessions(String classId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _sessions = await _repo.getClassSessions(classId);
    } on ApiException catch (e) {
      _error = e.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadSessionAttendance(String sessionId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _sessionAttendance = await _repo.getSessionAttendance(sessionId);
    } on ApiException catch (e) {
      _error = e.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopQrRotation();
    super.dispose();
  }
}
