import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/services/attendance_file_service.dart';
import '../../../../core/services/attendance_validation_service.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/services/geocoding_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../di/service_locator.dart';
import '../../../authentication/domain/repositories/auth_repository.dart';
import '../../domain/entities/biometric_attendance.dart';
import '../../domain/entities/location_info.dart';
import '../../domain/usecases/mark_biometric_attendance_usecase.dart';

part 'biometric_attendance_event.dart';
part 'biometric_attendance_state.dart';

/// BLoC for managing biometric attendance marking
///
/// This BLoC handles:
/// - Biometric authentication (fingerprint/face)
/// - Location fetching with landmarks
/// - Duplicate check-in/check-out prevention (same location not allowed)
/// - Attendance saving to local text file
class BiometricAttendanceBloc
    extends Bloc<BiometricAttendanceEvent, BiometricAttendanceState> {
  BiometricAttendanceBloc({
    required BiometricService biometricService,
    required GeocodingService geocodingService,
    required AttendanceFileService attendanceFileService,
    required AttendanceValidationService validationService,
    required AppConfig appConfig,
    required String employeeId,
    LocationService? locationService,
    AuthRepository? authRepository,
    MarkBiometricAttendanceUseCase? markBiometricAttendanceUseCase,
  }) : _biometricService = biometricService,
       _geocodingService = geocodingService,
       _attendanceFileService = attendanceFileService,
       _validationService = validationService,
       _appConfig = appConfig,
       _employeeId = employeeId,
       _locationService = locationService ?? getIt<LocationService>(),
       _authRepository = authRepository ?? getIt<AuthRepository>(),
       _markBiometricAttendanceUseCase =
           markBiometricAttendanceUseCase ??
           getIt<MarkBiometricAttendanceUseCase>(),
       super(const BiometricAttendanceState()) {
    on<BiometricAttendanceInitialized>(_onInitialized);
    on<BiometricAttendanceLocationRequested>(_onLocationRequested);
    on<BiometricAttendanceMarkRequested>(_onMarkRequested);
    on<BiometricAttendanceTypeChanged>(_onTypeChanged);
    on<BiometricAttendanceReset>(_onReset);
    on<BiometricAttendanceCheckTodayStatus>(_onCheckTodayStatus);
    on<BiometricAttendanceOpenLocationSettings>(_onOpenLocationSettings);
  }

  final BiometricService _biometricService;
  final GeocodingService _geocodingService;
  final AttendanceFileService _attendanceFileService;
  final AttendanceValidationService _validationService;
  final AppConfig _appConfig;
  final String _employeeId;
  final LocationService _locationService;
  final AuthRepository _authRepository;
  final MarkBiometricAttendanceUseCase _markBiometricAttendanceUseCase;

  /// Initialize the bloc - check biometric availability
  Future<void> _onInitialized(
    BiometricAttendanceInitialized event,
    Emitter<BiometricAttendanceState> emit,
  ) async {
    emit(state.copyWith(status: BiometricAttendanceStatus.loading));

    try {
      // Check location service status first
      final isLocationEnabled = await _locationService
          .isLocationServiceEnabled();

      // Get available biometric types first (this is the most reliable check)
      final biometrics = await _biometricService.getAvailableBiometrics();
      final hasFace = biometrics.contains(BiometricType.face);
      final hasFingerprint = biometrics.contains(BiometricType.fingerprint);

      // Check device biometric availability (similar to login page)
      final isDeviceAvailable = await _biometricService.isBiometricAvailable();

      // Check if biometric is enabled in app settings (user linked it in profile)
      final isEnabledInApp = await _authRepository.isBiometricEnabled();

      // Always allow proceeding if device has biometrics enrolled (like login page)
      // This is more lenient - just check if biometrics are available, not if they're "enabled" in app
      if (isDeviceAvailable || (hasFace || hasFingerprint) || isEnabledInApp) {
        // Device supports it or user has enabled it, allow proceeding
        emit(
          state.copyWith(
            status: BiometricAttendanceStatus.ready,
            hasFaceId: hasFace,
            hasFingerprint: hasFingerprint,
            availableBiometrics: biometrics,
            isLocationServiceEnabled: isLocationEnabled,
          ),
        );
      } else {
        // Still allow proceeding but show a note
        emit(
          state.copyWith(
            status: BiometricAttendanceStatus.ready,
            hasFaceId: hasFace,
            hasFingerprint: hasFingerprint,
            availableBiometrics: biometrics,
            isLocationServiceEnabled: isLocationEnabled,
            errorMessage:
                'Note: Biometric check had issues, but you can still try marking attendance.',
          ),
        );
      }

      // Check today's attendance status
      add(const BiometricAttendanceCheckTodayStatus());

      // Start fetching location only if location services are enabled
      if (isLocationEnabled) {
        add(const BiometricAttendanceLocationRequested());
      } else {
        emit(
          state.copyWith(
            locationError:
                'Location services are disabled. Please enable GPS/location to mark attendance.',
          ),
        );
      }
    } catch (e) {
      // On any error, still try to get biometrics and allow proceeding (like login page)
      try {
        final biometrics = await _biometricService.getAvailableBiometrics();
        final hasFace = biometrics.contains(BiometricType.face);
        final hasFingerprint = biometrics.contains(BiometricType.fingerprint);
        final isEnabledInApp = await _authRepository.isBiometricEnabled();

        // Always allow proceeding if we have any biometrics or it's enabled in app
        emit(
          state.copyWith(
            status: BiometricAttendanceStatus.ready,
            hasFaceId: hasFace,
            hasFingerprint: hasFingerprint,
            availableBiometrics: biometrics,
            errorMessage: (hasFace || hasFingerprint || isEnabledInApp)
                ? null
                : 'Warning: ${e.toString()}',
          ),
        );
      } catch (e2) {
        // If everything fails, still allow proceeding (most lenient approach)
        emit(
          state.copyWith(
            status: BiometricAttendanceStatus.ready,
            errorMessage:
                'Note: Some checks failed, but you can still try marking attendance.',
          ),
        );
      }
      // Still try to check status and get location
      add(const BiometricAttendanceCheckTodayStatus());
      add(const BiometricAttendanceLocationRequested());
    }
  }

  /// Check today's attendance status
  Future<void> _onCheckTodayStatus(
    BiometricAttendanceCheckTodayStatus event,
    Emitter<BiometricAttendanceState> emit,
  ) async {
    final todayStatus = _validationService.getTodayStatus();

    emit(
      state.copyWith(
        hasCheckedInToday: todayStatus.hasCheckedIn,
        hasCheckedOutToday: todayStatus.hasCheckedOut,
        todayCheckInTime: todayStatus.checkInTime,
        todayCheckOutTime: todayStatus.checkOutTime,
      ),
    );

    // Auto-select appropriate attendance type
    if (!todayStatus.hasCheckedIn) {
      emit(state.copyWith(attendanceType: 'check_in'));
    } else if (!todayStatus.hasCheckedOut) {
      emit(state.copyWith(attendanceType: 'check_out'));
    }
  }

  /// Fetch current location with address and landmarks
  Future<void> _onLocationRequested(
    BiometricAttendanceLocationRequested event,
    Emitter<BiometricAttendanceState> emit,
  ) async {
    emit(state.copyWith(isLoadingLocation: true));

    try {
      final locationInfo = await _geocodingService.getLocationInfo();

      emit(
        state.copyWith(isLoadingLocation: false, locationInfo: locationInfo),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingLocation: false,
          locationError: 'Failed to get location: $e',
        ),
      );
    }
  }

  /// Mark attendance with biometric verification
  Future<void> _onMarkRequested(
    BiometricAttendanceMarkRequested event,
    Emitter<BiometricAttendanceState> emit,
  ) async {
    print('=== MARK ATTENDANCE REQUESTED ===');
    print('Current state: ${state.status}');
    print('Attendance type: ${state.attendanceType}');
    print('Can mark: ${state.canMarkAttendance}');

    // Check location service status first
    final isLocationEnabled = await _locationService.isLocationServiceEnabled();

    if (!isLocationEnabled) {
      emit(
        state.copyWith(
          status: BiometricAttendanceStatus.error,
          errorMessage:
              'Please turn on your mobile location or GPS to mark attendance.',
        ),
      );
      return;
    }

    // Update location service status in state
    emit(state.copyWith(isLocationServiceEnabled: true));

    // Immediately show loading state
    emit(
      state.copyWith(
        status: BiometricAttendanceStatus.submitting,
        errorMessage: null,
      ),
    );

    // Try to get location if we don't have it yet
    if (state.locationInfo == null && !state.isLoadingLocation) {
      emit(state.copyWith(isLoadingLocation: true));
      try {
        final locationInfo = await _geocodingService.getLocationInfo();
        emit(
          state.copyWith(isLoadingLocation: false, locationInfo: locationInfo),
        );
      } catch (e) {
        emit(
          state.copyWith(
            isLoadingLocation: false,
            locationError: 'Location unavailable: $e',
          ),
        );
        // Continue anyway - location is not critical for attendance marking
        // We'll use default coordinates if needed
      }
    }

    // Wait for location if it's still loading
    if (state.isLoadingLocation) {
      // Wait a bit for location to load
      await Future.delayed(const Duration(seconds: 2));
      if (state.locationInfo == null && !state.isLoadingLocation) {
        // Location failed, but we'll continue with default coordinates
        emit(
          state.copyWith(
            locationError:
                'Using default location. Please ensure GPS is enabled.',
          ),
        );
      }
    }

    // Validate duplicate check-in/check-out using latest persisted status
    final refreshedStatus = _validationService.getTodayStatus();
    emit(
      state.copyWith(
        hasCheckedInToday: refreshedStatus.hasCheckedIn,
        hasCheckedOutToday: refreshedStatus.hasCheckedOut,
        todayCheckInTime: refreshedStatus.checkInTime,
        todayCheckOutTime: refreshedStatus.checkOutTime,
      ),
    );

    // Use location if available, otherwise use default coordinates
    final latitude =
        state.locationInfo?.latitude ?? _appConfig.defaultGeoLatitude;
    final longitude =
        state.locationInfo?.longitude ?? _appConfig.defaultGeoLongitude;

    AttendanceValidationResult validationResult;
    if (state.attendanceType == 'check_in') {
      validationResult = _validationService.canCheckIn(
        latitude: latitude,
        longitude: longitude,
      );
    } else {
      // Ensure check-out only when refreshed status says checked-in
      if (!refreshedStatus.hasCheckedIn) {
        validationResult = const AttendanceValidationResult(
          canProceed: false,
          reason: 'You must check in first before checking out',
          errorType: AttendanceErrorType.noCheckIn,
        );
      } else {
        validationResult = _validationService.canCheckOut();
      }
    }

    if (!validationResult.canProceed) {
      emit(
        state.copyWith(
          status: BiometricAttendanceStatus
              .ready, // Keep ready so user can see the error and retry
          errorMessage: validationResult.reason,
        ),
      );
      return;
    }

    emit(state.copyWith(status: BiometricAttendanceStatus.authenticating));

    // Perform biometric authentication
    final biometricResult = await _biometricService.authenticate(
      reason:
          'Verify your identity to mark ${state.attendanceType == 'check_in' ? 'check-in' : 'check-out'}',
      biometricOnly: true,
    );

    if (!biometricResult.success) {
      emit(
        state.copyWith(
          status: BiometricAttendanceStatus.authFailed,
          errorMessage: biometricResult.message,
        ),
      );
      return;
    }

    // Determine biometric type used
    final biometricType = state.hasFaceId ? 'face' : 'fingerprint';

    emit(state.copyWith(status: BiometricAttendanceStatus.submitting));

    try {
      final now = DateTime.now();

      // Create location info if we don't have it
      final locationInfoToSave =
          state.locationInfo ??
          LocationInfo.coordinates(
            latitude: latitude,
            longitude: longitude,
            accuracy: 0.0,
          );

      // Get device info
      String? deviceId;
      String? deviceModel;
      String? appVersion;
      try {
        final deviceInfo = DeviceInfoPlugin();
        final packageInfo = await PackageInfo.fromPlatform();
        appVersion = packageInfo.version;

        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceId = androidInfo.id;
          deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor;
          deviceModel = '${iosInfo.name} ${iosInfo.model}';
        }
      } catch (e) {
        // Device info is optional, continue without it
        print('Failed to get device info: $e');
      }

      // Save to database via API first (as per API_MAPPING_SHEET.md)
      BiometricAttendanceResponse? apiResponse;
      try {
        print('Calling API to mark attendance...');
        apiResponse = await _markBiometricAttendanceUseCase.call(
          employeeId: _employeeId,
          attendanceType: state.attendanceType,
          biometricType: biometricType,
          locationInfo: locationInfoToSave,
          deviceId: deviceId,
          deviceModel: deviceModel,
          appVersion: appVersion,
        );
        print('API response: ${apiResponse.success} - ${apiResponse.message}');
      } catch (e, stackTrace) {
        // API call failed, but continue to save locally
        // This allows offline functionality
        print('API call failed: $e');
        print('Stack trace: $stackTrace');
        apiResponse = null;
      }

      // Record in validation service (for local tracking)
      if (state.attendanceType == 'check_in') {
        await _validationService.recordCheckIn(
          latitude: latitude,
          longitude: longitude,
        );
      } else {
        await _validationService.recordCheckOut(
          latitude: latitude,
          longitude: longitude,
        );
      }

      // Save attendance to local file (as backup/offline record)
      final fileResult = await _attendanceFileService.saveAttendance(
        employeeId: _employeeId,
        attendanceType: state.attendanceType,
        biometricType: biometricType,
        locationInfo: locationInfoToSave,
        timestamp: now,
      );

      // Update today's status
      final todayStatus = _validationService.getTodayStatus();

      // Prepare next available type (if any)
      final nextType = (!todayStatus.hasCheckedIn)
          ? 'check_in'
          : (!todayStatus.hasCheckedOut ? 'check_out' : state.attendanceType);

      // Success if API call succeeded OR if local file save succeeded
      final isSuccess =
          fileResult.success || (apiResponse != null && apiResponse.success);

      if (isSuccess) {
        final successMsg = apiResponse != null && apiResponse.success
            ? '${state.attendanceType == 'check_in' ? 'Check-in' : 'Check-out'} saved successfully to server!'
            : '${state.attendanceType == 'check_in' ? 'Check-in' : 'Check-out'} saved successfully (local backup)!';

        print('=== ATTENDANCE MARKED SUCCESSFULLY ===');
        print('Success message: $successMsg');
        print(
          'Today status - Checked in: ${todayStatus.hasCheckedIn}, Checked out: ${todayStatus.hasCheckedOut}',
        );
        print('Next type: $nextType');

        // Emit success state - the UI will show dialog
        final newState = state.copyWith(
          status: BiometricAttendanceStatus.success,
          successMessage: successMsg,
          markedAt: now,
          savedFilePath: fileResult.filePath,
          hasCheckedInToday: todayStatus.hasCheckedIn,
          hasCheckedOutToday: todayStatus.hasCheckedOut,
          todayCheckInTime: todayStatus.checkInTime,
          todayCheckOutTime: todayStatus.checkOutTime,
          attendanceType: nextType,
          errorMessage: apiResponse == null
              ? 'Note: Saved locally only. Server connection unavailable.'
              : null,
        );

        emit(newState);
        print(
          'Success state emitted. Status: ${newState.status}, HasCheckedIn: ${newState.hasCheckedInToday}, AttendanceType: ${newState.attendanceType}',
        );
      } else {
        final errorMsg = apiResponse?.message ?? fileResult.message;
        print('Failed to save attendance: $errorMsg');
        emit(
          state.copyWith(
            status: BiometricAttendanceStatus
                .ready, // Set to ready so user can retry
            errorMessage: errorMsg,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: BiometricAttendanceStatus.error,
          errorMessage: 'Error saving attendance: $e',
        ),
      );
    }
  }

  /// Change attendance type (check-in/check-out)
  void _onTypeChanged(
    BiometricAttendanceTypeChanged event,
    Emitter<BiometricAttendanceState> emit,
  ) {
    emit(state.copyWith(attendanceType: event.type));
  }

  /// Reset state for new attendance marking
  void _onReset(
    BiometricAttendanceReset event,
    Emitter<BiometricAttendanceState> emit,
  ) {
    emit(
      state.copyWith(
        status: BiometricAttendanceStatus.ready,
        errorMessage: null,
        successMessage: null,
        markedAt: null,
      ),
    );

    // Refresh location
    add(const BiometricAttendanceLocationRequested());
  }

  /// Open location settings
  Future<void> _onOpenLocationSettings(
    BiometricAttendanceOpenLocationSettings event,
    Emitter<BiometricAttendanceState> emit,
  ) async {
    await _locationService.openLocationSettings();
    // Refresh location status after opening settings
    Future.delayed(const Duration(seconds: 1), () {
      add(const BiometricAttendanceInitialized());
    });
  }
}
