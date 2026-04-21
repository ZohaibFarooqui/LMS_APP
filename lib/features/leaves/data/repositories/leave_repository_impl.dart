import 'package:flutter/material.dart';
import '../../domain/entities/leave_balance.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/repositories/leave_repository.dart';
import '../datasources/leave_remote_data_source.dart';

class LeaveRepositoryImpl implements LeaveRepository {
  LeaveRepositoryImpl(this._remote, this._cardNo1Provider, this._empPkProvider);

  final LeaveRemoteDataSource _remote;
  final Future<String?> Function() _cardNo1Provider;
  final Future<String?> Function() _empPkProvider;

  List<LeaveBalance>? _cachedBalances;
  List<LeaveRequest>? _cachedRequests;

  @override
  List<LeaveBalance>? cachedBalances() => _cachedBalances;

  @override
  List<LeaveRequest>? cachedRequests() => _cachedRequests;

  @override
  Future<List<LeaveBalance>> fetchBalances() async {
    final cardNo1 = await _cardNo1Provider() ?? '';
    if (cardNo1.isEmpty) {
      throw Exception('Card number not found. Please login again.');
    }
    final data = await _remote.fetchBalances(cardNo1);
    _cachedBalances = data;
    return data;
  }

  @override
  Future<List<LeaveRequest>> fetchRequests() async {
    final cardNo1 = await _cardNo1Provider() ?? '';
    final data = await _remote.fetchRequests(cardNo1);
    _cachedRequests = data;
    return data;
  }

  @override
  Future<void> submitRequest(LeaveRequest request, {TimeOfDay? fromTime, TimeOfDay? toTime}) async {
    final empPk = await _empPkProvider() ?? '';
    final body = <String, dynamic>{
      'type': request.type,
      'from_date': request.fromDate.toIso8601String().split('T').first,
      'to_date': request.toDate.toIso8601String().split('T').first,
      'half_day': request.halfDay,
      'reason': request.reason,
    };
    
    // Add time fields if half-day and times are provided
    if (request.halfDay && fromTime != null && toTime != null) {
      body['from_time'] = '${fromTime.hour.toString().padLeft(2, '0')}:${fromTime.minute.toString().padLeft(2, '0')}';
      body['to_time'] = '${toTime.hour.toString().padLeft(2, '0')}:${toTime.minute.toString().padLeft(2, '0')}';
    }
    
    await _remote.submitRequest(
      empPk: empPk,
      body: body,
    );
  }
}
