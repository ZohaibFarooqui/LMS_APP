import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/biometric_service.dart';
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
    required BiometricService biometricService,
  }) : _authenticateUserUseCase = authenticateUserUseCase,
       _getCachedUserUseCase = getCachedUserUseCase,
       _logoutUseCase = logoutUseCase,
       _toggleBiometricUseCase = toggleBiometricUseCase,
       _authRepository = authRepository,
       _biometricService = biometricService,
       super(const AuthState()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<BiometricToggled>(_onBiometricToggled);
    on<BiometricLoginRequested>(_onBiometricLoginRequested);
  }

  final AuthenticateUserUseCase _authenticateUserUseCase;
  final GetCachedUserUseCase _getCachedUserUseCase;
  final LogoutUseCase _logoutUseCase;
  final ToggleBiometricUseCase _toggleBiometricUseCase;
  final AuthRepository _authRepository;
  final BiometricService _biometricService;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
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

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user = await _authenticateUserUseCase(
        event.username,
        event.password,
      );
      await _authRepository.setRememberMe(
        event.rememberMe,
        username: event.username,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          biometricEnabled: state.biometricEnabled,
          rememberedUsername: event.rememberMe
              ? event.username
              : state.rememberedUsername,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          errorMessage: error.toString(),
        ),
      );
      emit(state.copyWith(status: AuthStatus.authenticated));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _logoutUseCase();
    emit(state.copyWith(status: AuthStatus.unauthenticated, user: null));
  }

  Future<void> _onBiometricToggled(
    BiometricToggled event,
    Emitter<AuthState> emit,
  ) async {
    await _toggleBiometricUseCase(event.enabled);
    emit(state.copyWith(biometricEnabled: event.enabled));
  }

  Future<void> _onBiometricLoginRequested(
    BiometricLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Check if biometric is available and enabled
    final isAvailable = await _biometricService.isBiometricAvailable();
    if (!isAvailable) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage:
              'Biometric authentication is not available on this device.',
        ),
      );
      emit(state.copyWith(status: AuthStatus.unauthenticated));
      return;
    }

    // Authenticate with biometrics
    final result = await _biometricService.authenticate(
      reason: 'Please authenticate to login',
      biometricOnly: true,
    );

    if (result.success) {
      // Get cached user to restore session
      final user = await _getCachedUserUseCase();
      if (user != null) {
        emit(state.copyWith(status: AuthStatus.authenticated, user: user));
      } else {
        emit(
          state.copyWith(
            status: AuthStatus.failure,
            errorMessage:
                'No saved credentials found. Please login with username and password first.',
          ),
        );
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      }
    } else {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: result.message,
        ),
      );
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }
}
