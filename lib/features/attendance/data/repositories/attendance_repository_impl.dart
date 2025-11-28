import '../../../../data/datasources/lms_local_data_source.dart';
import '../../../../data/datasources/lms_remote_data_source.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/attendance_summary.dart';
import '../../domain/repositories/attendance_repository.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  AttendanceRepositoryImpl(this._remote, this._local);

  final LmsRemoteDataSource _remote;
  final LmsLocalDataSource _local;

  @override
  List<AttendanceRecord>? cachedAttendance() => _local.attendance();

  @override
  AttendanceSummary? cachedSummary() => _local.attendanceSummary();

  @override
  Future<List<AttendanceRecord>> fetchAttendance(DateTime from, DateTime to) async {
    final data = await _remote.attendance(from, to);
    await _local.cacheAttendance(data);
    return data;
  }

  @override
  Future<AttendanceSummary> fetchSummary(DateTime from, DateTime to) async {
    final summary = await _remote.attendanceSummary(from, to);
    await _local.cacheAttendanceSummary(summary);
    return summary;
  }
}

