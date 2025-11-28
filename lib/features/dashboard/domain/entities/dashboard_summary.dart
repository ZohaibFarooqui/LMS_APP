import 'package:equatable/equatable.dart';

import '../../../leaves/domain/entities/leave_balance.dart';

class DashboardSummary extends Equatable {
  const DashboardSummary({
    required this.userName,
    required this.employeeCode,
    required this.cadre,
    required this.designation,
    required this.department,
    required this.location,
    required this.cardNumber,
    required this.balances,
  });

  final String userName;
  final String employeeCode;
  final String cadre;
  final String designation;
  final String department;
  final String location;
  final String cardNumber;
  final List<LeaveBalance> balances;

  @override
  List<Object?> get props => [
        userName,
        employeeCode,
        cadre,
        designation,
        department,
        location,
        cardNumber,
        balances,
      ];
}

