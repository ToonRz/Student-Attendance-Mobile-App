class ApiConstants {
  static const String baseUrl = 'http://127.0.0.1:3000/api'; // Web -> localhost (using IPv4)
  // Use 'http://localhost:3000/api' for iOS simulator
  // Use your machine IP for physical device: 'http://192.168.x.x:3000/api'

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String updateFcmToken = '/auth/fcm-token';

  static const String classes = '/classes';
  static const String myClasses = '/classes/my';
  static const String joinClass = '/classes/join';

  static const String sessions = '/sessions';

  static const String checkIn = '/attendance/checkin';
  static const String attendanceSession = '/attendance/session';
  static const String attendanceReport = '/attendance/report';
  static const String attendanceStudent = '/attendance/student';
}
