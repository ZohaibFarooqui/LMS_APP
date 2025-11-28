import '../../core/config/app_config.dart';
import '../../core/network/mock_api_service.dart';
import '../../core/network/network_client.dart';
import '../../features/attendance/domain/entities/attendance_record.dart';
import '../../features/attendance/domain/entities/attendance_summary.dart';
import '../../features/dashboard/domain/entities/dashboard_summary.dart';
import '../../features/leaves/domain/entities/leave_balance.dart';
import '../../features/leaves/domain/entities/leave_request.dart';
import '../../features/notifications/domain/entities/notification_message.dart';
import '../../features/profile/domain/entities/profile_entity.dart';

abstract class LmsRemoteDataSource {
  Future<DashboardSummary> dashboard();
  Future<List<LeaveBalance>> leaveBalances();
  Future<List<LeaveRequest>> leaveRequests();
  Future<void> submitLeave(LeaveRequest request);
  Future<List<AttendanceRecord>> attendance(DateTime from, DateTime to);
  Future<AttendanceSummary> attendanceSummary(DateTime from, DateTime to);
  Future<ProfileEntity> profile();
  Future<List<NotificationMessage>> notifications();
  Future<void> markAttendance({required bool automatic, String? note});
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
    final response = await _client.get<Map<String, dynamic>>('/dashboard');
    throw UnimplementedError('Map dashboard response: ${response.data}');
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
    await _client.post('/leave/applications', data: {
      'type': request.type,
      'fromDate': request.fromDate.toIso8601String(),
      'toDate': request.toDate.toIso8601String(),
      'halfDay': request.halfDay,
      'reason': request.reason,
    });
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
  Future<AttendanceSummary> attendanceSummary(DateTime from, DateTime to) async {
    if (_config.useMockData) {
      return _mockApiService.fetchAttendanceSummary();
    }
    final response = await _client.get<Map<String, dynamic>>('/attendance/summary');
    throw UnimplementedError('Map attendance summary ${response.data}');
  }

  @override
  Future<ProfileEntity> profile() async {
    if (_config.useMockData) {
      return _mockApiService.fetchProfile();
    }
    final response = await _client.get<Map<String, dynamic>>('/employee/profile');
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
      data: {
        'automatic': automatic,
        'note': note,
      },
    );
  }
}

