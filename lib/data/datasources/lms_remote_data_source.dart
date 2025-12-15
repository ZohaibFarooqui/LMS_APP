import 'package:lms/features/attendance/domain/entities/biometric_attendance.dart';

import '../../core/config/app_config.dart';
import '../../core/network/mock_api_service.dart';
import '../../core/network/network_client.dart';
import '../../core/services/secure_storage_service.dart';
import '../../di/service_locator.dart';
import '../../features/attendance/domain/entities/attendance_record.dart';
import '../../features/attendance/domain/entities/attendance_summary.dart';
import '../../features/dashboard/domain/entities/dashboard_summary.dart';
import '../../features/leaves/domain/entities/leave_balance.dart';
import '../../features/leaves/domain/entities/leave_request.dart';
import '../../features/notifications/domain/entities/notification_message.dart';
import '../../features/profile/domain/entities/enhanced_profile_entity.dart';

abstract class LmsRemoteDataSource {
  Future<DashboardSummary> dashboard();
  Future<List<LeaveBalance>> leaveBalances();
  Future<List<LeaveRequest>> leaveRequests();
  Future<void> submitLeave(LeaveRequest request);
  Future<List<AttendanceRecord>> attendance(DateTime from, DateTime to);
  Future<AttendanceSummary> attendanceSummary(DateTime from, DateTime to);
  Future<EnhancedProfileEntity> profile();
  Future<List<NotificationMessage>> notifications();
  Future<void> markAttendance({required bool automatic, String? note});
  Future<BiometricAttendanceResponse> markBiometricAttendance(
    BiometricAttendanceRequest request,
  );
}

class LmsRemoteDataSourceImpl implements LmsRemoteDataSource {
  LmsRemoteDataSourceImpl(this._client, this._config, this._mockApiService);

  final NetworkClient _client;
  final AppConfig _config;
  final MockApiService _mockApiService;

  @override
  Future<DashboardSummary> dashboard() async {
    if (_config.useMockData) {
      return _mockApiService.fetchDashboard();
    }

    // Get phone number from secure storage (stored during login)
    final secureStorage = getIt<SecureStorageService>();
    final phoneNumber = await secureStorage.read('phone_number');

    if (phoneNumber == null || phoneNumber.isEmpty) {
      throw Exception('Phone number not found. Please login again.');
    }

    // Clean phone number (remove spaces, dashes, etc.)
    final cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    print('=== FETCHING DASHBOARD ===');
    print('Phone number from storage: $phoneNumber');
    print('Cleaned phone number: $cleanPhoneNumber');
    print('API URL: /data/$cleanPhoneNumber');

    try {
      // Call real API: /data/{phoneNumber}
      final response = await _client.get<Map<String, dynamic>>(
        '/data/$cleanPhoneNumber',
      );

      print('API Response received');
      final data = response.data;
      if (data == null) {
        print('ERROR: Response data is null');
        throw Exception('Invalid response from server');
      }

      print('Response data: $data');
      final header = data['header'] as Map<String, dynamic>?;
      final body = data['body'] as Map<String, dynamic>?;

      if (header == null || body == null) {
        print('ERROR: Header or body is null');
        print('Header: $header');
        print('Body: $body');
        throw Exception('Invalid response format');
      }

      print('Response header code: ${header['code']}');
      print('Response header message: ${header['message']}');
      print('Response body: $body');

      if (header['code'] != 100) {
        final errorMsg =
            header['message'] as String? ?? 'Failed to fetch dashboard';
        print('ERROR: API returned error code ${header['code']}: $errorMsg');
        throw Exception(errorMsg);
      }

      // Map response to DashboardSummary
      print('Mapping response to DashboardSummary...');
      final summary = DashboardSummary(
        userName: body['emp_name'] as String? ?? 'N/A',
        employeeCode: body['emp_no'] as String? ?? 'N/A',
        cadre: body['designation'] as String? ?? 'N/A',
        designation: body['designation'] as String? ?? 'N/A',
        department: body['department'] as String? ?? 'N/A',
        location: body['compcnm'] as String? ?? 'N/A',
        cardNumber: body['card_no1'] as String? ?? 'N/A',
        balances: const [], // Leave balances would come from separate API
      );

      print('=== DASHBOARD SUMMARY CREATED ===');
      print('User Name: ${summary.userName}');
      print('Employee Code: ${summary.employeeCode}');
      print('Designation: ${summary.designation}');
      print('Department: ${summary.department}');
      print('Location: ${summary.location}');

      return summary;
    } catch (e, stackTrace) {
      print('=== DASHBOARD API ERROR ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<List<LeaveBalance>> leaveBalances() async {
    if (_config.useMockData) {
      return _mockApiService.fetchBalances();
    }
    final response = await _client.get<List<dynamic>>('/leave/balances');
    throw UnimplementedError('Map leave balances ${response.data}');
  }

  @override
  Future<List<LeaveRequest>> leaveRequests() async {
    if (_config.useMockData) {
      return _mockApiService.fetchLeaveRequests();
    }
    final response = await _client.get<List<dynamic>>('/leave/applications');
    throw UnimplementedError('Map leave requests ${response.data}');
  }

  @override
  Future<void> submitLeave(LeaveRequest request) async {
    if (_config.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return;
    }
    await _client.post(
      '/leave/applications',
      data: {
        'type': request.type,
        'fromDate': request.fromDate.toIso8601String(),
        'toDate': request.toDate.toIso8601String(),
        'halfDay': request.halfDay,
        'reason': request.reason,
      },
    );
  }

  @override
  Future<List<AttendanceRecord>> attendance(DateTime from, DateTime to) async {
    if (_config.useMockData) {
      return _mockApiService.fetchAttendance(from, to);
    }
    final response = await _client.get<List<dynamic>>('/attendance/report');
    throw UnimplementedError('Map attendance ${response.data}');
  }

  @override
  Future<AttendanceSummary> attendanceSummary(
    DateTime from,
    DateTime to,
  ) async {
    if (_config.useMockData) {
      return _mockApiService.fetchAttendanceSummary();
    }
    final response = await _client.get<Map<String, dynamic>>(
      '/attendance/summary',
    );
    throw UnimplementedError('Map attendance summary ${response.data}');
  }

  @override
  Future<EnhancedProfileEntity> profile() async {
    if (_config.useMockData) {
      return _mockApiService.fetchProfile();
    }
    final response = await _client.get<Map<String, dynamic>>(
      '/employee/profile',
    );
    throw UnimplementedError('Map profile ${response.data}');
  }

  @override
  Future<List<NotificationMessage>> notifications() async {
    if (_config.useMockData) {
      return _mockApiService.fetchNotifications();
    }
    final response = await _client.get<List<dynamic>>('/notifications');
    throw UnimplementedError('Map notifications ${response.data}');
  }

  @override
  Future<void> markAttendance({required bool automatic, String? note}) async {
    if (_config.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return;
    }
    await _client.post(
      '/attendance/check-in',
      data: {'automatic': automatic, 'note': note},
    );
  }

  @override
  Future<BiometricAttendanceResponse> markBiometricAttendance(
    BiometricAttendanceRequest request,
  ) async {
    if (_config.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      return BiometricAttendanceResponse(
        attendanceId: 'ATT-${DateTime.now().millisecondsSinceEpoch}',
        markedAt: DateTime.now(),
        locationVerified: true,
        biometricVerified: true,
        success: true,
        message: 'Attendance marked successfully',
      );
    }

    final response = await _client.post<Map<String, dynamic>>(
      '/attendance/biometric',
      data: request.toJson(),
    );

    return BiometricAttendanceResponse.fromJson(
      response.data ??
          {
            'header': {'code': 500, 'message': 'Unknown error'},
          },
    );
  }
}
