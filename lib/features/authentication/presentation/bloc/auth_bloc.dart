import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/authenticate_user_usecase.dart';
import '../../domain/usecases/get_cached_user_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/toggle_biometric_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthenticateUserUseCase authenticateUserUseCase,
    required GetCachedUserUseCase getCachedUserUseCase,
    required LogoutUseCase logoutUseCase,
    required ToggleBiometricUseCase toggleBiometricUseCase,
    required AuthRepository authRepository,
  })  : _authenticateUserUseCase = authenticateUserUseCase,
        _getCachedUserUseCase = getCachedUserUseCase,
        _logoutUseCase = logoutUseCase,
        _toggleBiometricUseCase = toggleBiometricUseCase,
        _authRepository = authRepository,
        super(const AuthState()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<BiometricToggled>(_onBiometricToggled);
  }

  final AuthenticateUserUseCase _authenticateUserUseCase;
  final GetCachedUserUseCase _getCachedUserUseCase;
  final LogoutUseCase _logoutUseCase;
  final ToggleBiometricUseCase _toggleBiometricUseCase;
  final AuthRepository _authRepository;

  Future<void> _onCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final user = await _getCachedUserUseCase();
    final rememberedUsername = await _authRepository.rememberedUsername();
    final biometricEnabled = await _authRepository.isBiometricEnabled();
    if (user != null) {
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          biometricEnabled: biometricEnabled,
          rememberedUsername: rememberedUsername,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          biometricEnabled: biometricEnabled,
          rememberedUsername: rememberedUsername,
        ),
      );
    }
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user = await _authenticateUserUseCase(event.username, event.password);
      await _authRepository.setRememberMe(event.rememberMe, username: event.username);
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          biometricEnabled: state.biometricEnabled,
          rememberedUsername: event.rememberMe ? event.username : state.rememberedUsername,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: error.toString(),
        ),
      );
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    await _logoutUseCase();
    emit(state.copyWith(status: AuthStatus.unauthenticated, user: null));
  }

  Future<void> _onBiometricToggled(BiometricToggled event, Emitter<AuthState> emit) async {
    await _toggleBiometricUseCase(event.enabled);
    emit(state.copyWith(biometricEnabled: event.enabled));
  }
}

