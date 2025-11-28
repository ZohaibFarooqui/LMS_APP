import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.employeeCode,
    required super.department,
    required super.designation,
    required super.location,
    required super.cardNumber,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      employeeCode: json['employeeCode'] as String,
      department: json['department'] as String,
      designation: json['designation'] as String,
      location: json['location'] as String,
      cardNumber: json['cardNumber'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'employeeCode': employeeCode,
      'department': department,
      'designation': designation,
      'location': location,
      'cardNumber': cardNumber,
    };
  }
}

