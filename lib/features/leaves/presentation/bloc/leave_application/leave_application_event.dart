part of 'leave_application_bloc.dart';

abstract class LeaveApplicationEvent extends Equatable {
  const LeaveApplicationEvent();

  @override
  List<Object?> get props => [];
}

class LeaveTypeChanged extends LeaveApplicationEvent {
  const LeaveTypeChanged(this.leaveType);

  final String leaveType;

  @override
  List<Object?> get props => [leaveType];
}

class LeaveDatesChanged extends LeaveApplicationEvent {
  const LeaveDatesChanged(this.from, this.to);

  final DateTime from;
  final DateTime to;

  @override
  List<Object?> get props => [from, to];
}

class LeaveReasonChanged extends LeaveApplicationEvent {
  const LeaveReasonChanged(this.reason);

  final String reason;

  @override
  List<Object?> get props => [reason];
}

class LeaveHalfDayToggled extends LeaveApplicationEvent {
  const LeaveHalfDayToggled(this.halfDay);

  final bool halfDay;

  @override
  List<Object?> get props => [halfDay];
}

class LeaveFromTimeChanged extends LeaveApplicationEvent {
  const LeaveFromTimeChanged(this.fromTime);

  final TimeOfDay fromTime;

  @override
  List<Object?> get props => [fromTime];
}

class LeaveToTimeChanged extends LeaveApplicationEvent {
  const LeaveToTimeChanged(this.toTime);

  final TimeOfDay toTime;

  @override
  List<Object?> get props => [toTime];
}

class LeaveSubmitted extends LeaveApplicationEvent {
  const LeaveSubmitted();
}

