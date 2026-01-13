part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class LoginRequested extends AuthEvent {
  const LoginRequested({
    required this.username,
    required this.password,
    required this.rememberMe,
  });

  final String username;
  final String password;
  final bool rememberMe;

  @override
  List<Object?> get props => [username, password, rememberMe];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class BiometricToggled extends AuthEvent {
  const BiometricToggled(this.enabled);

  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}

class BiometricLoginRequested extends AuthEvent {
  const BiometricLoginRequested();
}