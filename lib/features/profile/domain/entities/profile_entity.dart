import 'package:equatable/equatable.dart';

class ProfileEntity extends Equatable {
  const ProfileEntity({
    required this.name,
    required this.employeeCode,
    required this.cadre,
    required this.department,
    required this.designation,
    required this.joiningDate,
    required this.location,
    required this.cardNumber,
    required this.email,
    required this.phoneNumber,
  });

  final String name;
  final String employeeCode;
  final String cadre;
  final String department;
  final String designation;
  final String joiningDate;
  final String location;
  final String cardNumber;
  final String email;
  final String phoneNumber;

  @override
  List<Object?> get props => [
        name,
        employeeCode,
        cadre,
        department,
        designation,
        joiningDate,
        location,
        cardNumber,
        email,
        phoneNumber,
      ];
}

