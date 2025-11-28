part of 'attendance_bloc.dart';

enum AttendanceStatus { initial, loading, success, failure }

class AttendanceState extends Equatable {
  const AttendanceState({
    required this.fromDate,
    required this.toDate,
    required this.records,
    required this.summary,
    this.status = AttendanceStatus.initial,
    this.errorMessage,
  });

  final DateTime fromDate;
  final DateTime toDate;
  final List<AttendanceRecord> records;
  final AttendanceSummary summary;
  final AttendanceStatus status;
  final String? errorMessage;

  factory AttendanceState.initial() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    return AttendanceState(
      fromDate: firstDay,
      toDate: lastDay,
      records: const [],
      summary: const AttendanceSummary(
        casualLeave: 0,
        earnedLeave: 0,
        medicalLeave: 0,
        compensatoryLeave: 0,
        sickLeave: 0,
        lossOfPay: 0,
        absent: 0,
        outdoorDuty: 0,
        approvedExtraWork: 0,
        lateCount: 0,
      ),
    );
  }

  AttendanceState copyWith({
    DateTime? fromDate,
    DateTime? toDate,
    List<AttendanceRecord>? records,
    AttendanceSummary? summary,
    AttendanceStatus? status,
    String? errorMessage,
  }) {
    return AttendanceState(
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      records: records ?? this.records,
      summary: summary ?? this.summary,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        fromDate,
        toDate,
        records,
        summary,
        status,
        errorMessage,
      ];
}

