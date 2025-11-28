import '../../../../data/datasources/lms_local_data_source.dart';
import '../../../../data/datasources/lms_remote_data_source.dart';
import '../../domain/entities/leave_balance.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/repositories/leave_repository.dart';

class LeaveRepositoryImpl implements LeaveRepository {
  LeaveRepositoryImpl(this._remote, this._local);

  final LmsRemoteDataSource _remote;
  final LmsLocalDataSource _local;

  @override
  List<LeaveBalance>? cachedBalances() => _local.balances();

  @override
  List<LeaveRequest>? cachedRequests() => _local.leaveRequests();

  @override
  Future<List<LeaveBalance>> fetchBalances() async {
    final data = await _remote.leaveBalances();
    await _local.cacheBalances(data);
    return data;
  }

  @override
  Future<List<LeaveRequest>> fetchRequests() async {
    final data = await _remote.leaveRequests();
    await _local.cacheLeaveRequests(data);
    return data;
  }

  @override
  Future<void> submitRequest(LeaveRequest request) {
    return _remote.submitLeave(request);
  }
}

