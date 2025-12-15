import '../../../leaves/domain/entities/leave_balance.dart';
import '../../domain/entities/dashboard_summary.dart';

class DashboardSummaryModel extends DashboardSummary {
  DashboardSummaryModel({
    required super.userName,
    required super.employeeCode,
    required super.cadre,
    required super.designation,
    required super.department,
    required super.location,
    required super.cardNumber,
    required super.balances,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      userName: (json['emp_name'] ?? json['userName'] ?? '').toString(),
      employeeCode: (json['emp_no'] ?? json['employeeCode'] ?? '').toString(),
      cadre: (json['designation'] ?? json['cadre'] ?? '').toString(),
      designation: (json['designation'] ?? '').toString(),
      department: (json['department'] ?? '').toString(),
      location: (json['branch'] ?? json['brnchnm'] ?? '').toString(),
      cardNumber: (json['card_no1'] ?? json['cardNumber'] ?? '').toString(),
      balances: const <LeaveBalance>[],
    );
  }
}
