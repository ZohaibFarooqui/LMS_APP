import 'package:equatable/equatable.dart';

class AttendanceSummary extends Equatable {
  const AttendanceSummary({
    required this.casualLeave,
    required this.earnedLeave,
    required this.medicalLeave,
    required this.compensatoryLeave,
    required this.sickLeave,
    required this.lossOfPay,
    required this.absent,
    required this.outdoorDuty,
    required this.approvedExtraWork,
    required this.lateCount,
  });

  final int casualLeave;
  final int earnedLeave;
  final int medicalLeave;
  final int compensatoryLeave;
  final int sickLeave;
  final int lossOfPay;
  final int absent;
  final int outdoorDuty;
  final int approvedExtraWork;
  final int lateCount;

  @override
  List<Object?> get props => [
        casualLeave,
        earnedLeave,
        medicalLeave,
        compensatoryLeave,
        sickLeave,
        lossOfPay,
        absent,
        outdoorDuty,
        approvedExtraWork,
        lateCount,
      ];
}

