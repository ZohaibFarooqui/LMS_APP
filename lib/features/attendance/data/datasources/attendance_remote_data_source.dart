import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/attendance_summary.dart';
import '../../domain/entities/biometric_attendance.dart';
// import '../../domain/entities/location_info.dart';

abstract class AttendanceRemoteDataSource {
  Future<BiometricAttendanceResponse> markBiometricAttendance(
    BiometricAttendanceRequest request,
  );

  Future<List<AttendanceRecord>> getAttendanceHistory({
    required String empPk,
    required String fromDate,
    required String toDate,
  });

  Future<AttendanceSummary> getAttendanceSummary({
    required String empPk,
    required String fromDate,
    required String toDate,
  });
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  AttendanceRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  @override
  Future<BiometricAttendanceResponse> markBiometricAttendance(
    BiometricAttendanceRequest request,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/attendance/biometric',
      data: request.toJson(),
    );
    final body = response.data?['body'] as Map<String, dynamic>? ?? {};
    return BiometricAttendanceResponse.fromJson(body);
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceHistory({
    required String empPk,
    required String fromDate,
    required String toDate,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/attendance/report',
      queryParameters: {
        'emp_pk': empPk,
        'from_date': fromDate,
        'to_date': toDate,
      },
    );
    final body = response.data?['body'] as Map<String, dynamic>? ?? {};
    final records = body['records'] as List<dynamic>? ?? [];
    return records.map((r) => _mapRecord(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<AttendanceSummary> getAttendanceSummary({
    required String empPk,
    required String fromDate,
    required String toDate,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/attendance/summary',
      queryParameters: {
        'emp_pk': empPk,
        'from_date': fromDate,
        'to_date': toDate,
      },
    );
    final body = response.data?['body'] as Map<String, dynamic>? ?? {};
    return AttendanceSummary(
      casualLeave: _asInt(body['casual_leave']),
      earnedLeave: _asInt(body['earned_leave']),
      medicalLeave: _asInt(body['medical_leave']),
      compensatoryLeave: _asInt(body['compensatory_leave']),
      sickLeave: _asInt(body['sick_leave']),
      lossOfPay: _asInt(body['loss_of_pay']),
      absent: _asInt(body['absent']),
      outdoorDuty: _asInt(body['outdoor_duty']),
      approvedExtraWork: _asInt(body['approved_extra_work']),
      lateCount: _asInt(body['late_count']),
    );
  }

  AttendanceRecord _mapRecord(Map<String, dynamic> json) {
    Duration parseDuration(String? value) {
      if (value == null || value.isEmpty) return Duration.zero;
      final parts = value.split(':').map(int.parse).toList();
      final hours = parts.isNotEmpty ? parts[0] : 0;
      final minutes = parts.length > 1 ? parts[1] : 0;
      final seconds = parts.length > 2 ? parts[2] : 0;
      return Duration(hours: hours, minutes: minutes, seconds: seconds);
    }

    return AttendanceRecord(
      date: DateTime.parse(json['date'] as String),
      shift: (json['shift'] ?? '').toString(),
      day: _asInt(json['day']),
      timeIn: parseDuration(json['time_in'] as String?),
      timeOut: parseDuration(json['time_out'] as String?),
      workHours: parseDuration(json['work_hours'] as String?),
      lateArrival: parseDuration(json['late_arrival'] as String?),
      approvedHours: parseDuration(json['approved_hours'] as String?),
      remarks: (json['remarks'] ?? '').toString(),
      isAbsent: json['is_absent'] == true,
    );
  }

  int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
