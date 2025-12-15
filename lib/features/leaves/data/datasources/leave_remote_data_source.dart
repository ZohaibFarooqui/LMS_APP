import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/leave_balance.dart';
import '../../domain/entities/leave_request.dart';

abstract class LeaveRemoteDataSource {
  Future<List<LeaveBalance>> fetchBalances(String empPk);
  Future<List<LeaveRequest>> fetchRequests(String empPk);
  Future<void> submitRequest({
    required String empPk,
    required Map<String, dynamic> body,
  });
}

class LeaveRemoteDataSourceImpl implements LeaveRemoteDataSource {
  LeaveRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  @override
  Future<List<LeaveBalance>> fetchBalances(String empPk) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/leave/balances',
      queryParameters: {'emp_pk': empPk},
    );
    final body = response.data?['body'] as Map<String, dynamic>? ?? {};
    final balances = body['balances'] as List<dynamic>? ?? [];
    return balances.map((b) => _mapBalance(b as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<LeaveRequest>> fetchRequests(String empPk) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/leave/applications',
      queryParameters: {'emp_pk': empPk, 'status': 'all'},
    );
    final body = response.data?['body'] as Map<String, dynamic>? ?? {};
    final requests = body['requests'] as List<dynamic>? ?? [];
    return requests.map((r) => _mapRequest(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> submitRequest({
    required String empPk,
    required Map<String, dynamic> body,
  }) async {
    await _dio.post('/leave/applications', data: {...body, 'emp_pk': empPk});
  }

  LeaveBalance _mapBalance(Map<String, dynamic> json) {
    return LeaveBalance(
      code: (json['code'] ?? '').toString(),
      name: (json['leave_type'] ?? json['name'] ?? '').toString(),
      balance:
          int.tryParse((json['available'] ?? json['total']).toString()) ?? 0,
    );
  }

  LeaveRequest _mapRequest(Map<String, dynamic> json) {
    LeaveStatus _status(String value) {
      switch (value.toLowerCase()) {
        case 'approved':
          return LeaveStatus.approved;
        case 'rejected':
          return LeaveStatus.rejected;
        default:
          return LeaveStatus.pending;
      }
    }

    return LeaveRequest(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      fromDate: DateTime.parse(json['from_date'] as String),
      toDate: DateTime.parse(json['to_date'] as String),
      status: _status((json['status'] ?? 'pending').toString()),
      reason: (json['reason'] ?? '').toString(),
      halfDay: json['half_day'] == true,
      approverComment: json['remarks'] as String?,
    );
  }
}
