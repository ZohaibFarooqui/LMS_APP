part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileRequested extends ProfileEvent {
  const ProfileRequested();
}

class ProfileContactUpdated extends ProfileEvent {
  const ProfileContactUpdated({
    required this.email,
    required this.phone,
  });

  final String email;
  final String phone;

  @override
  List<Object?> get props => [email, phone];
}

