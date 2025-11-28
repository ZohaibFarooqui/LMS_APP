part of 'auth_bloc.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.biometricEnabled = false,
    this.rememberedUsername,
  });

  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;
  final bool biometricEnabled;
  final String? rememberedUsername;

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? errorMessage,
    bool? biometricEnabled,
    String? rememberedUsername,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      rememberedUsername: rememberedUsername ?? this.rememberedUsername,
    );
  }

  @override
  List<Object?> get props => [
        status,
        user,
        errorMessage,
        biometricEnabled,
        rememberedUsername,
      ];
}

