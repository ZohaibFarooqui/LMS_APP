import 'package:equatable/equatable.dart';

import 'location_info.dart';

class BiometricAttendanceRequest extends Equatable {
  const BiometricAttendanceRequest({
    required this.employeeId,
    required this.attendanceType,
    required this.biometricType,
    required this.locationInfo,
    required this.timestamp,
    this.deviceId,
    this.deviceModel,
    this.appVersion,
  });

  final String employeeId;
  final String attendanceType;
  final String biometricType;
  final LocationInfo locationInfo;
  final DateTime timestamp;
  final String? deviceId;
  final String? deviceModel;
  final String? appVersion;

  Map<String, dynamic> toJson() {
    return {
      'emp_pk': employeeId,
      'attendance_type': attendanceType,
      'biometric_type': biometricType,
      'location': locationInfo.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'device_id': deviceId,
      'device_model': deviceModel,
      'app_version': appVersion,
    };
  }

  @override
  List<Object?> get props => [
    employeeId,
    attendanceType,
    biometricType,
    locationInfo,
    timestamp,
    deviceId,
    deviceModel,
    appVersion,
  ];
}

class BiometricAttendanceResponse extends Equatable {
  const BiometricAttendanceResponse({
    required this.attendanceId,
    required this.markedAt,
    required this.locationVerified,
    required this.biometricVerified,
    this.success = true,
    this.message = '',
  });

  final String attendanceId;
  final DateTime markedAt;
  final bool locationVerified;
  final bool biometricVerified;
  final bool success;
  final String message;

  factory BiometricAttendanceResponse.fromJson(Map<String, dynamic> json) {
    final header = json['header'] as Map<String, dynamic>?;
    final body = json['body'] as Map<String, dynamic>? ?? json;
    return BiometricAttendanceResponse(
      attendanceId: (body['attendance_id'] ?? '').toString(),
      markedAt: body['marked_at'] != null
          ? DateTime.parse(body['marked_at'] as String)
          : DateTime.now(),
      locationVerified: body['location_verified'] == true,
      biometricVerified: body['biometric_verified'] == true,
      success: header?['code'] == 100 || body['success'] == true,
      message: (header?['message'] ?? body['message'] ?? '').toString(),
    );
  }

  @override
  List<Object?> get props => [
    attendanceId,
    markedAt,
    locationVerified,
    biometricVerified,
    success,
    message,
  ];
}
