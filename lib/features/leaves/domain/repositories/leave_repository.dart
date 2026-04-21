import '../entities/leave_balance.dart';
import '../entities/leave_request.dart';

import 'package:flutter/material.dart';

abstract class LeaveRepository {
  Future<List<LeaveBalance>> fetchBalances();
  Future<List<LeaveRequest>> fetchRequests();
  Future<void> submitRequest(LeaveRequest request, {TimeOfDay? fromTime, TimeOfDay? toTime});
  List<LeaveBalance>? cachedBalances();
  List<LeaveRequest>? cachedRequests();
}

