part of 'attendance_bloc.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class AttendanceRequested extends AttendanceEvent {
  const AttendanceRequested();
}

class AttendanceRangeChanged extends AttendanceEvent {
  const AttendanceRangeChanged({
    required this.from,
    required this.to,
  });

  final DateTime from;
  final DateTime to;

  @override
  List<Object?> get props => [from, to];
}

