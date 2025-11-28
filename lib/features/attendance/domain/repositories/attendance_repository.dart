import '../entities/attendance_record.dart';
import '../entities/attendance_summary.dart';

abstract class AttendanceRepository {
  Future<List<AttendanceRecord>> fetchAttendance(DateTime from, DateTime to);
  Future<AttendanceSummary> fetchSummary(DateTime from, DateTime to);
  List<AttendanceRecord>? cachedAttendance();
  AttendanceSummary? cachedSummary();
}

