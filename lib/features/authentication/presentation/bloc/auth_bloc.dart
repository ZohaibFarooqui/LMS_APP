import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/biometric_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../di/service_locator.dart';
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
    // Clear previous errors and set loading state
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    debugPrint('AuthBloc: Starting login for username: ${event.username}');

    try {
      final user = await _authenticateUserUseCase(
        event.username,
        event.password,
      );

      debugPrint('AuthBloc: Login successful, user ID: ${user.id}');

      // Store phone number (username) in secure storage for API calls
      final secureStorage = getIt<SecureStorageService>();
      await secureStorage.write('phone_number', event.username);

      // Set remember me before emitting authenticated state
      await _authRepository.setRememberMe(
        event.rememberMe,
        username: event.username,
      );

      // Get biometric enabled state
      final biometricEnabled = await _authRepository.isBiometricEnabled();
      final rememberedUsername = event.rememberMe
          ? event.username
          : state.rememberedUsername;

      // Emit authenticated state - this should trigger navigation
      final authenticatedState = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        biometricEnabled: biometricEnabled,
        rememberedUsername: rememberedUsername,
        clearErrorMessage: true, // Explicitly clear errors
      );

      debugPrint(
        'AuthBloc: Emitting authenticated state - User: ${user.id}, Status: authenticated',
      );

      emit(authenticatedState);
    } catch (error, stackTrace) {
      // Extract clean error message with detailed logging
      debugPrint('AuthBloc: Login error caught - $error');
      debugPrint('AuthBloc: Stack trace: $stackTrace');

      String errorMsg = error.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring('Exception: '.length);
      }

      // Clean up error message - remove verbose Dio error messages
      if (errorMsg.contains('404')) {
        errorMsg =
            'Login endpoint not found. Please check your network connection or contact support.';
      } else if (errorMsg.contains('status code of 404')) {
        errorMsg =
            'Invalid credentials or endpoint not found. Please check your phone number and password.';
      } else if (errorMsg.contains('Network error') ||
          errorMsg.contains('SocketException')) {
        errorMsg = 'Network error. Please check your internet connection.';
      } else if (errorMsg.length > 200) {
        // If error message is too long (like Dio's verbose errors), extract meaningful part
        if (errorMsg.contains('message')) {
          // Try to extract a shorter message
          // Look for pattern like: message: "actual message" or message: 'actual message'
          // Use a simpler regex that avoids complex character classes
          final doubleQuoteMatch = RegExp(
            r'message\s*:\s*"([^"]+)"',
          ).firstMatch(errorMsg);
          final singleQuoteMatch = RegExp(
            r"message\s*:\s*'([^']+)'",
          ).firstMatch(errorMsg);

          if (doubleQuoteMatch != null && doubleQuoteMatch.group(1) != null) {
            errorMsg = doubleQuoteMatch.group(1)!;
          } else if (singleQuoteMatch != null &&
              singleQuoteMatch.group(1) != null) {
            errorMsg = singleQuoteMatch.group(1)!;
          } else {
            errorMsg =
                'Login failed. Please check your credentials and try again.';
          }
        } else {
          errorMsg =
              'Login failed. Please check your credentials and try again.';
        }
      }

      // Ensure we always have an error message
      if (errorMsg.isEmpty || errorMsg == 'null') {
        errorMsg = 'Login failed. Please check your credentials and try again.';
      }

      debugPrint('AuthBloc: Final error message - $errorMsg');

      // Emit failure state with error message
      emit(state.copyWith(status: AuthStatus.failure, errorMessage: errorMsg));
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
