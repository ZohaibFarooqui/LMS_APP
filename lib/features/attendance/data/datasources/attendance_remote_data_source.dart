import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../di/service_locator.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/attendance_summary.dart';
import '../../domain/entities/biometric_attendance.dart';

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
  AttendanceRemoteDataSourceImpl({
    Dio? dio,
    required Future<String?> Function() cardNo1Provider,
  }) : _dio = dio ?? DioClient.instance,
       _cardNo1Provider = cardNo1Provider;

  final Dio _dio;
  final Future<String?> Function() _cardNo1Provider;

  /// Attach Authorization header (Bearer token) like other LMS API calls.
  Future<Map<String, dynamic>?> _authorizedPost(
    String path, {
    Object? data,
  }) async {
    final secureStorage = getIt<SecureStorageService>();
    final token = await secureStorage.read('token');

    final headers = <String, dynamic>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: data,
      options: Options(headers: headers),
    );

    return response.data;
  }

  Future<Map<String, dynamic>?> _authorizedGet(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final secureStorage = getIt<SecureStorageService>();
    final token = await secureStorage.read('token');

    final headers = <String, dynamic>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: queryParameters,
      options: Options(headers: headers),
    );

    return response.data;
  }

  @override
  Future<BiometricAttendanceResponse> markBiometricAttendance(
    BiometricAttendanceRequest request,
  ) async {
    // Route FACE biometric attendance to the dedicated Face Attendance API
    if (request.biometricType.toLowerCase() == 'face') {
      var cardNo1 = await _cardNo1Provider() ?? '';

      // In identify mode (login page), secure storage may be empty.
      // Fall back to the employeeId from the request (set by face identify).
      if (cardNo1.isEmpty && request.employeeId.isNotEmpty) {
        cardNo1 = request.employeeId;
      }

      if (cardNo1.isEmpty) {
        throw Exception('Card number not found. Please login again.');
      }

      final location = request.locationInfo;
      // DB column "ADDRESS" is VARCHAR2(100) - avoid ORA-12899 by trimming.
      final rawAddress = location.address ?? location.displayAddress;
      final safeAddress = rawAddress.length > 100
          ? rawAddress.substring(0, 100)
          : rawAddress;

      final payload = <String, dynamic>{
        'card_no': cardNo1,
        // Backend accepts "check_in" / "check_out" as used across the app.
        'attendance_type': request.attendanceType,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'accuracy': location.accuracy,
        'address': safeAddress,
        'formatted_address':
            location.formattedAddress ?? location.displayAddress,
        'timestamp': request.timestamp.toIso8601String(),
        'device_id': request.deviceId,
        'device_model': request.deviceModel,
        'app_version': request.appVersion,
      };

      final data =
          await _authorizedPost('/auth/attendance/face', data: payload) ??
          <String, dynamic>{};

      // API returns: { "body": { "marked_at": "...", "location_verified": true } }
      final body = (data['body'] as Map<String, dynamic>?) ?? data;

      final markedAtStr = body['marked_at']?.toString();
      DateTime markedAt;
      if (markedAtStr != null && markedAtStr.isNotEmpty) {
        // Backend returns "HH:MI" format (e.g. "14:30"), not ISO 8601.
        // Try ISO parse first, then fall back to HH:MI → today's DateTime.
        markedAt = DateTime.tryParse(markedAtStr) ?? _parseHHMM(markedAtStr);
      } else {
        markedAt = DateTime.now();
      }

      final locationVerified = body['location_verified'] == true;

      return BiometricAttendanceResponse(
        attendanceId: (body['attendance_id'] ?? '').toString(),
        markedAt: markedAt,
        locationVerified: locationVerified,
        // Face has already been verified on the frontend before this call
        biometricVerified: true,
        success: true,
        message: (body['message'] ?? 'Attendance marked successfully')
            .toString(),
      );
    }

    // Fallback for non-face biometric types (legacy endpoint)
    final data =
        await _authorizedPost(
          '/auth/attendance/biometric',
          data: request.toJson(),
        ) ??
        <String, dynamic>{};

    return BiometricAttendanceResponse.fromJson(data);
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceHistory({
    required String empPk,
    required String fromDate,
    required String toDate,
  }) async {
    final cardNo1 = await _cardNo1Provider() ?? '';

    if (cardNo1.isEmpty) {
      return <AttendanceRecord>[];
    }

    // Single bulk API call for the entire date range
    final data = await _authorizedGet(
      '/auth/attendance/report-range/$cardNo1',
      queryParameters: {
        'from_date': fromDate,
        'to_date': toDate,
      },
    );
    return _parseAttendanceHistoryResponse(data);
  }

  @override
  Future<AttendanceSummary> getAttendanceSummary({
    required String empPk,
    required String fromDate,
    required String toDate,
  }) async {
    final data = await _authorizedGet(
      '/auth/attendance/summary',
      queryParameters: {
        'emp_pk': empPk,
        'from_date': fromDate,
        'to_date': toDate,
      },
    );
    final body = data?['body'] as Map<String, dynamic>? ?? {};
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
      totalDays: _asInt(body['total_days']),
      presentDays: _asInt(body['present']),
      incompleteDays: _asInt(body['incomplete']),
      totalMinutes: _asInt(body['total_minutes']),
    );
  }

  List<AttendanceRecord> _parseAttendanceHistoryResponse(
    Map<String, dynamic>? data,
  ) {
    if (data == null) return [];

    // New ORDS-style response: { "items": [ ... ] }
    if (data.containsKey('items')) {
      final items = data['items'] as List<dynamic>? ?? [];
      return items
          .map((item) => _mapRecord(item as Map<String, dynamic>))
          .toList();
    }

    // Legacy response: { "body": { "records": [ ... ] } }
    final body = data['body'] as Map<String, dynamic>? ?? {};
    final records = body['records'] as List<dynamic>? ?? [];
    return records
        .map((record) => _mapRecord(record as Map<String, dynamic>))
        .toList();
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

    // New ORDS /attendance/report format (roster_date, in_time, out_time, etc.)
    if (json.containsKey('roster_date')) {
      final rosterDateStr = json['roster_date']?.toString();
      DateTime date;
      try {
        date = rosterDateStr != null && rosterDateStr.isNotEmpty
            ? DateTime.parse(rosterDateStr)
            : DateTime.now();
      } catch (_) {
        date = DateTime.now();
      }

      final timeIn = parseDuration(json['in_time'] as String?);
      final timeOut = parseDuration(json['out_time'] as String?);

      // Use w_hrs/w_mnt from DUTY_ROSTER if available, else approximate
      final wHrs = _asInt(json['w_hrs']);
      final wMnt = _asInt(json['w_mnt']);
      final workHours = (wHrs > 0 || wMnt > 0)
          ? Duration(hours: wHrs, minutes: wMnt)
          : (timeIn != Duration.zero && timeOut != Duration.zero
              ? timeOut - timeIn
              : Duration.zero);

      final lateHrs = _asInt(json['late_hrs']);
      final lateMnt = _asInt(json['late_mnt']);
      final lateArrival = Duration(hours: lateHrs, minutes: lateMnt);

      final isAbsent = (json['absent_days'] is num)
          ? (json['absent_days'] as num) > 0
          : false;

      return AttendanceRecord(
        date: date,
        shift: (json['roster_shift'] ?? '').toString(),
        day: date.day,
        timeIn: timeIn,
        timeOut: timeOut,
        workHours: workHours,
        lateArrival: lateArrival,
        approvedHours: Duration.zero,
        remarks: (json['status'] ?? json['roster_remarks'] ?? '').toString(),
        isAbsent: isAbsent,
      );
    }

    // Legacy /attendance/report format (date, shift, time_in, etc.)
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

  /// Parse "HH:MI" time string into today's DateTime.
  DateTime _parseHHMM(String hhmm) {
    try {
      final parts = hhmm.split(':');
      final now = DateTime.now();
      return DateTime(
        now.year, now.month, now.day,
        int.parse(parts[0]),
        parts.length > 1 ? int.parse(parts[1]) : 0,
      );
    } catch (_) {
      return DateTime.now();
    }
  }

  int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

}
