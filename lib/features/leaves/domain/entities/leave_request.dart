import 'package:equatable/equatable.dart';

enum LeaveStatus { pending, approved, rejected }

class LeaveRequest extends Equatable {
  const LeaveRequest({
    required this.id,
    required this.type,
    required this.fromDate,
    required this.toDate,
    required this.status,
    required this.reason,
    this.halfDay = false,
    this.approverComment,
  });

  final String id;
  final String type;
  final DateTime fromDate;
  final DateTime toDate;
  final LeaveStatus status;
  final String reason;
  final bool halfDay;
  final String? approverComment;

  @override
  List<Object?> get props => [
        id,
        type,
        fromDate,
        toDate,
        status,
        reason,
        halfDay,
        approverComment,
      ];
}

