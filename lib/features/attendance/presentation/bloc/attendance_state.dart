part of 'attendance_bloc.dart';

enum AttendanceStatus { initial, loading, success, failure }

class AttendanceState extends Equatable {
  const AttendanceState({
    this.status = AttendanceStatus.initial,
    this.records = const [],
    this.errorMessage,
  });

  final AttendanceStatus status;
  final List<AttendanceRecord> records;
  final String? errorMessage;

  AttendanceState copyWith({
    AttendanceStatus? status,
    List<AttendanceRecord>? records,
    String? errorMessage,
  }) {
    return AttendanceState(
      status: status ?? this.status,
      records: records ?? this.records,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, records, errorMessage];
}






