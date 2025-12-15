import '../../domain/entities/biometric_attendance.dart';
import '../../domain/entities/location_info.dart';
import '../repositories/attendance_repository.dart';

/// Use case for marking attendance with biometric verification
///
/// This use case handles:
/// - Biometric authentication verification
/// - Location info gathering
/// - Attendance marking API call
class MarkBiometricAttendanceUseCase {
  MarkBiometricAttendanceUseCase(this._repository);

  final AttendanceRepository _repository;

  /// Mark attendance with biometric verification
  ///
  /// [employeeId] - Employee identifier
  /// [attendanceType] - Either 'check_in' or 'check_out'
  /// [biometricType] - Either 'fingerprint' or 'face'
  /// [locationInfo] - Location details including coordinates and landmarks
  /// [deviceId] - Unique device identifier
  /// [deviceModel] - Device model name
  /// [appVersion] - App version
  Future<BiometricAttendanceResponse> call({
    required String employeeId,
    required String attendanceType,
    required String biometricType,
    required LocationInfo locationInfo,
    String? deviceId,
    String? deviceModel,
    String? appVersion,
  }) async {
    final request = BiometricAttendanceRequest(
      employeeId: employeeId,
      attendanceType: attendanceType,
      biometricType: biometricType,
      locationInfo: locationInfo,
      timestamp: DateTime.now(),
      deviceId: deviceId,
      deviceModel: deviceModel,
      appVersion: appVersion,
    );

    return _repository.markBiometricAttendance(request);
  }
}
