import 'package:flutter/material.dart';
import '../data/class_repository.dart';
import '../../../core/network/api_exceptions.dart';

class ClassProvider extends ChangeNotifier {
  final ClassRepository _repo = ClassRepository();

  List<dynamic> _classes = [];
  Map<String, dynamic>? _selectedClass;
  Map<String, dynamic>? _report;
  bool _isLoading = false;
  String? _error;

  List<dynamic> get classes => _classes;
  Map<String, dynamic>? get selectedClass => _selectedClass;
  Map<String, dynamic>? get report => _report;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadClasses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _classes = await _repo.getTeacherClasses();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load classes';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createClass(String name, String subject) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repo.createClass(name, subject);
      await loadClasses();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadClassDetail(String classId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedClass = await _repo.getClassDetail(classId);
    } on ApiException catch (e) {
      _error = e.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadReport(String classId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _report = await _repo.getAttendanceReport(classId);
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
}
