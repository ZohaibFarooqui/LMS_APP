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
    super.fatherName,
    super.nicNo,
    super.nicExpDate,
    super.eobiNo,
    super.uicCardNo,
    super.salary,
    super.managerAboveSts,
    super.confirmationDate,
    super.companyAccommodation,
    super.compcnm,
    super.compc,
  });

  factory EnhancedProfileModel.fromJson(Map<String, dynamic> json) {
    final reporting = json['reporting_to'] as Map<String, dynamic>?;
    final emergency = json['emergency_contact'] as Map<String, dynamic>?;
    // Support multiple API field names (legacy and new)
    String? fatherName = (json['father_name'] ?? json['fatherName'])?.toString();
    String? nicNo = (json['nic_no'] ?? json['nicNo'])?.toString();
    DateTime? nicExpDate = json['nic_exp_date'] != null
        ? DateTime.tryParse(json['nic_exp_date'] as String)
        : (json['nicExpDate'] != null ? DateTime.tryParse(json['nicExpDate'] as String) : null);
    String? eobi = (json['eobi_no'] ?? json['eobiNo'])?.toString();
    String? uic = (json['uic_card_no'] ?? json['uicCardNo'])?.toString();
    int? salary = json['salary'] is int ? json['salary'] as int : (json['salary'] != null ? int.tryParse(json['salary'].toString()) : null);
    String? managerAbove = (json['manager_above_sts'] ?? json['managerAboveSts'])?.toString();
    DateTime? confirmationDate = json['confirmation_date'] != null
        ? DateTime.tryParse(json['confirmation_date'] as String)
        : (json['confirmationDate'] != null ? DateTime.tryParse(json['confirmationDate'] as String) : null);
    String? companyAccommodation = (json['company_accomodation'] ?? json['company_accommodation'] ?? json['companyAccommodation'])?.toString();
    String? compcnm = (json['compcnm'] ?? json['compcnm'])?.toString();
    int? compc = json['compc'] is int ? json['compc'] as int : (json['compc'] != null ? int.tryParse(json['compc'].toString()) : null);
    // mobile number fallback
    final phoneVal = json['mobile_no'] ?? json['mobile'] ?? json['phone'] ?? json['phone_number'];
    return EnhancedProfileModel(
      id: (json['emp_pk'] ?? json['id'] ?? '').toString(),
      employeeCode: (json['emp_no'] ?? '').toString(),
      name: (json['emp_name'] ?? json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phoneNumber: (phoneVal ?? json['phone'] ?? json['phone_number'] ?? '').toString(),
      gender: (json['gender'] ?? 'M').toString(),
        dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : DateTime.now(),
        joiningDate: json['date_of_join'] != null
          ? DateTime.parse(json['date_of_join'] as String)
          : DateTime.now(),
      department: (json['department'] ?? '').toString(),
      designation: (json['designation'] ?? '').toString(),
        cadre: (json['cadre'] ?? json['designation'] ?? '').toString(),
        location: (json['location'] ?? json['branch'] ?? '').toString(),
        branch: (json['brnchnm'] ?? json['branch'] ?? '').toString(),
        cardNumber: (json['card_no1'] ?? json['card_number'] ?? json['card_no'] ?? '').toString(),
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
          : (json['hod_nm'] != null || json['hod2'] != null)
            ? ReportingManager(
              id: (json['hod2'] ?? '').toString(),
              name: (json['hod_nm'] ?? '').toString(),
              designation: (json['hod1'] ?? '').toString(),
              phoneNumber: (json['hod2'] ?? '').toString(),
            )
            : null,
        workSchedule: WorkSchedule.defaultSchedule, // Always use static schedule
        // Additional optional fields
        fatherName: fatherName,
        nicNo: nicNo,
        nicExpDate: nicExpDate,
        eobiNo: eobi,
        uicCardNo: uic,
        salary: salary,
        managerAboveSts: managerAbove,
        confirmationDate: confirmationDate,
        companyAccommodation: companyAccommodation,
        compcnm: compcnm,
        compc: compc,
    );
  }
}
