import '../../domain/entities/enhanced_profile_entity.dart';

class EnhancedProfileModel extends EnhancedProfileEntity {
  const EnhancedProfileModel({
    required super.id,
    required super.employeeCode,
    required super.name,
    required super.email,
    required super.phoneNumber,
    required super.gender,
    required super.dateOfBirth,
    required super.joiningDate,
    required super.department,
    required super.designation,
    required super.cadre,
    required super.location,
    required super.branch,
    required super.cardNumber,
    super.profilePictureUrl,
    super.emergencyContact,
    super.address,
    super.reportingTo,
    super.workSchedule,
  });

  factory EnhancedProfileModel.fromJson(Map<String, dynamic> json) {
    final reporting = json['reporting_to'] as Map<String, dynamic>?;
    final emergency = json['emergency_contact'] as Map<String, dynamic>?;

    return EnhancedProfileModel(
      id: (json['emp_pk'] ?? json['id'] ?? '').toString(),
      employeeCode: (json['emp_no'] ?? '').toString(),
      name: (json['emp_name'] ?? json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phoneNumber: (json['phone'] ?? json['phone_number'] ?? '').toString(),
      gender: (json['gender'] ?? 'M').toString(),
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : DateTime.now(),
      joiningDate: json['date_of_join'] != null
          ? DateTime.parse(json['date_of_join'] as String)
          : DateTime.now(),
      department: (json['department'] ?? '').toString(),
      designation: (json['designation'] ?? '').toString(),
      cadre: (json['designation'] ?? '').toString(),
      location: (json['branch'] ?? '').toString(),
      branch: (json['branch'] ?? '').toString(),
      cardNumber: (json['card_no1'] ?? json['card_number'] ?? '').toString(),
      emergencyContact: emergency != null
          ? EmergencyContact(
              name: (emergency['name'] ?? '').toString(),
              relationship:
                  (emergency['relation'] ?? emergency['relationship'] ?? '')
                      .toString(),
              phoneNumber:
                  (emergency['phone'] ?? emergency['phone_number'] ?? '')
                      .toString(),
            )
          : null,
      reportingTo: reporting != null
          ? ReportingManager(
              id: (reporting['emp_pk'] ?? '').toString(),
              name: (reporting['emp_name'] ?? '').toString(),
              designation: (reporting['designation'] ?? '').toString(),
              phoneNumber: (reporting['phone'] ?? '').toString(),
            )
          : null,
    );
  }
}
