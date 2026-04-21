import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/services/attendance_file_service.dart';
import '../../../../core/services/location_tracking_service.dart';
import '../../../../core/services/attendance_validation_service.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/services/geocoding_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../di/service_locator.dart';
import '../../../authentication/domain/repositories/auth_repository.dart';
import '../../../face_auth/domain/entities/face_identify_response.dart';
import '../../../face_auth/domain/usecases/face_status_usecase.dart';
import '../../../face_auth/domain/usecases/identify_face_usecase.dart';
import '../../../face_auth/domain/usecases/verify_face_usecase.dart';
import '../../../face_verification/data/datasources/face_camera_datasource.dart';
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
    this.identifyMode = false,
    LocationService? locationService,
    AuthRepository? authRepository,
    MarkBiometricAttendanceUseCase? markBiometricAttendanceUseCase,
    FaceStatusUseCase? faceStatusUseCase,
    VerifyFaceUseCase? verifyFaceUseCase,
    IdentifyFaceUseCase? identifyFaceUseCase,
    FaceCameraDataSource? faceCameraDataSource,
  }) : _biometricService = biometricService,
       _geocodingService = geocodingService,
       _attendanceFileService = attendanceFileService,
       _validationService = validationService,
       _appConfig = appConfig,
       _employeeId = employeeId,
       _locationService = locationService ?? getIt<LocationService>(),
       _authRepository = authRepository,
       _markBiometricAttendanceUseCase =
           markBiometricAttendanceUseCase ??
           getIt<MarkBiometricAttendanceUseCase>(),
       _faceStatusUseCase = faceStatusUseCase ?? getIt<FaceStatusUseCase>(),
       _verifyFaceUseCase = verifyFaceUseCase ?? getIt<VerifyFaceUseCase>(),
       _identifyFaceUseCase =
           identifyFaceUseCase ?? getIt<IdentifyFaceUseCase>(),
       _faceCameraDataSource =
           faceCameraDataSource ?? getIt<FaceCameraDataSource>(),
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
  // ignore: unused_field - Kept for potential future use
  final AuthRepository? _authRepository;
  final MarkBiometricAttendanceUseCase _markBiometricAttendanceUseCase;
  final FaceStatusUseCase _faceStatusUseCase;
  final VerifyFaceUseCase _verifyFaceUseCase;
  final IdentifyFaceUseCase _identifyFaceUseCase;
  final FaceCameraDataSource _faceCameraDataSource;
  final bool identifyMode;

  CameraController? _cameraController;
  bool _isCapturing = false;

  /// Initialize the bloc - STEP 1: Check face registration status
  ///
  /// FLOW: Face Status Check → If registered → Ready, else → Face Not Registered
  Future<void> _onInitialized(
    BiometricAttendanceInitialized event,
    Emitter<BiometricAttendanceState> emit,
  ) async {
    emit(state.copyWith(status: BiometricAttendanceStatus.checkingFaceStatus));

    try {
      if (identifyMode) {
        // IDENTIFY MODE: Skip face status check, go straight to ready
        debugPrint('BiometricAttendanceBloc: Identify mode — skipping face status check');

        final isLocationEnabled = await _locationService.isLocationServiceEnabled();
        final biometrics = await _biometricService.getAvailableBiometrics();

        emit(
          state.copyWith(
            status: BiometricAttendanceStatus.ready,
            isFaceRegistered: true,
            hasFaceId: biometrics.contains(BiometricType.face),
            hasFingerprint: biometrics.contains(BiometricType.fingerprint),
            availableBiometrics: biometrics,
            isLocationServiceEnabled: isLocationEnabled,
          ),
        );

        if (isLocationEnabled) {
          add(const BiometricAttendanceLocationRequested());
        }

        // Auto-trigger mark immediately in identify mode
        add(const BiometricAttendanceMarkRequested());
        return;
      }

      // NORMAL MODE: Check face registration status
      // Get card_no from secure storage — prefer card_no1 (set by Mark Attendance
      // dialog on login page), fall back to card_no (set during normal login).
      final secureStorage = getIt<SecureStorageService>();
      final cardNo1 = await secureStorage.read('card_no1') ??
          await secureStorage.read('card_no') ??
          '';

      if (cardNo1.isEmpty) {
        emit(
          state.copyWith(
            status: BiometricAttendanceStatus.error,
            errorMessage: 'Employee ID not found. Please login again.',
          ),
        );
        return;
      }

      // Scope the validation service to this user so different employees
      // on the same phone don't share check-in / check-out state.
      _validationService.setCurrentUser(cardNo1);

      // STEP 1: Check face registration status via API
      debugPrint(
        'BiometricAttendanceBloc: Checking face status for card_no: $cardNo1',
      );
      final faceStatusResponse = await _faceStatusUseCase.call(cardNo1);

      if (!faceStatusResponse.isRegistered) {
        // Face not registered - STOP flow
        debugPrint(
          'BiometricAttendanceBloc: Face not registered for card_no: $cardNo1',
        );
        emit(
          state.copyWith(
            status: BiometricAttendanceStatus.faceNotRegistered,
            errorMessage: 'Face not registered. Please register face first.',
            isFaceRegistered: false,
          ),
        );
        return;
      }

      // Face is registered - proceed to ready state
      debugPrint(
        'BiometricAttendanceBloc: Face is registered for card_no: $cardNo1',
      );

      // Check location service status
      final isLocationEnabled = await _locationService
          .isLocationServiceEnabled();

      // Get available biometric types (for UI display)
      final biometrics = await _biometricService.getAvailableBiometrics();
      final hasFace = biometrics.contains(BiometricType.face);
      final hasFingerprint = biometrics.contains(BiometricType.fingerprint);

      emit(
        state.copyWith(
          status: BiometricAttendanceStatus.ready,
          isFaceRegistered: true,
          hasFaceId: hasFace,
          hasFingerprint: hasFingerprint,
          availableBiometrics: biometrics,
          isLocationServiceEnabled: isLocationEnabled,
        ),
      );

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
      debugPrint('BiometricAttendanceBloc: Error during initialization: $e');
      emit(
        state.copyWith(
          status: BiometricAttendanceStatus.error,
          errorMessage: 'Failed to check face status: ${e.toString()}',
        ),
      );
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

  /// Mark attendance with face verification
  ///
  /// FLOW: STEP 2: Face Verification → STEP 3: Mark Attendance (only if verification succeeds)
  Future<void> _onMarkRequested(
    BiometricAttendanceMarkRequested event,
    Emitter<BiometricAttendanceState> emit,
  ) async {
    debugPrint('=== MARK ATTENDANCE REQUESTED ===');
    debugPrint('Current state: ${state.status}');
    debugPrint('Attendance type: ${state.attendanceType}');
    debugPrint('Can mark: ${state.canMarkAttendance}');

    // In identify mode, skip face registration check and card_no lookup
    String cardNo1 = '';
    if (!identifyMode) {
      // Verify face is registered (should already be checked in initialization)
      if (!state.isFaceRegistered) {
        emit(
          state.copyWith(
            status: BiometricAttendanceStatus.faceNotRegistered,
            errorMessage: 'Face not registered. Please register face first.',
          ),
        );
        return;
      }

      // Get card_no — prefer card_no1, fall back to card_no
      final secureStorage = getIt<SecureStorageService>();
      cardNo1 = await secureStorage.read('card_no1') ??
          await secureStorage.read('card_no') ??
          '';

      if (cardNo1.isEmpty) {
        emit(
          state.copyWith(
            status: BiometricAttendanceStatus.error,
            errorMessage: 'Employee ID not found. Please login again.',
          ),
        );
        return;
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
            status: BiometricAttendanceStatus.ready,
            errorMessage: validationResult.reason,
          ),
        );
        return;
      }
    }

    // Check location service status
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

    // Use location if available, otherwise use default coordinates
    final latitude =
        state.locationInfo?.latitude ?? _appConfig.defaultGeoLatitude;
    final longitude =
        state.locationInfo?.longitude ?? _appConfig.defaultGeoLongitude;

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
      }
    }

    // Wait for the user to see the location before starting face capture
    await Future.delayed(const Duration(seconds: 2));

    // ============================================================
    // STEP 2: FACE VERIFICATION
    // ============================================================

    // Initialize camera for face capture
    try {
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        emit(
          state.copyWith(
            status: BiometricAttendanceStatus.capturingFaceFrames,
            totalFramesToCapture: 20,
            capturedFramesCount: 0,
          ),
        );
        _cameraController = await _faceCameraDataSource.initializeCamera();
      }
    } catch (e) {
      debugPrint('BiometricAttendanceBloc: Failed to initialize camera: $e');
      emit(
        state.copyWith(
          status: BiometricAttendanceStatus.error,
          errorMessage: 'Failed to initialize camera: ${e.toString()}',
        ),
      );
      return;
    }

    // Capture minimum 5 frames for verification
    if (_isCapturing) {
      return; // Prevent multiple simultaneous captures
    }

    _isCapturing = true;

    try {
      emit(
        state.copyWith(
          status: BiometricAttendanceStatus.capturingFaceFrames,
          totalFramesToCapture: 20,
          capturedFramesCount: 0,
          errorMessage: null,
        ),
      );

      const int numFrames = 20;
      debugPrint(
        'BiometricAttendanceBloc: Starting face frame capture - $numFrames frames',
      );

      final frames = await _faceCameraDataSource.captureBurstFrames(
        _cameraController!,
        numFrames,
        onProgress: (frameCount) {
          emit(
            state.copyWith(
              capturedFramesCount: frameCount,
              status: BiometricAttendanceStatus.capturingFaceFrames,
            ),
          );
        },
      );

      if (frames.isEmpty || frames.length < numFrames) {
        emit(
          state.copyWith(
            status: BiometricAttendanceStatus.faceVerificationFailed,
            errorMessage:
                'Failed to capture enough frames (${frames.length}/$numFrames). Please try again.',
          ),
        );
        _isCapturing = false;
        return;
      }

      // Convert frames to base64 JPEG
      final List<String> base64Frames = [];
      for (int i = 0; i < frames.length; i++) {
        final img.Image f = frames[i];
        final jpg = img.encodeJpg(f, quality: 85);
        base64Frames.add(base64Encode(jpg));
      }

      debugPrint(
        'BiometricAttendanceBloc: Captured ${base64Frames.length} frames, verifying...',
      );

      // Verify/Identify face with backend
      emit(
        state.copyWith(
          status: BiometricAttendanceStatus.verifyingFace,
          capturedFramesCount: base64Frames.length,
          errorMessage: null,
        ),
      );

      // The employeeId to use for attendance marking
      // In normal mode, use cardNo1 from secure storage (not _employeeId which
      // may be a phone number from AuthBloc).  cardNo1 was already read above.
      String effectiveEmployeeId = cardNo1.isNotEmpty ? cardNo1 : _employeeId;

      if (identifyMode) {
        // IDENTIFY MODE: 1:N face search — returns who this person is
        debugPrint('BiometricAttendanceBloc: Calling face identify (1:N)...');
        final FaceIdentifyResponse identifyResponse =
            await _identifyFaceUseCase.call(frames: base64Frames);

        debugPrint(
          'BiometricAttendanceBloc: Face identify result - '
          'identified: ${identifyResponse.identified}, '
          'card_no: ${identifyResponse.cardNo}, '
          'emp_name: ${identifyResponse.empName}, '
          'confidence: ${identifyResponse.confidence}',
        );

        if (!identifyResponse.identified || identifyResponse.cardNo == null) {
          emit(
            state.copyWith(
              status: BiometricAttendanceStatus.faceVerificationFailed,
              faceVerificationMessage:
                  identifyResponse.message ?? 'Face not recognized',
              faceVerificationConfidence: identifyResponse.confidence,
              errorMessage:
                  identifyResponse.message ??
                  'Face not recognized. Please register your face first.',
            ),
          );
          _isCapturing = false;
          return;
        }

        // Use the identified card_no for attendance
        effectiveEmployeeId = identifyResponse.cardNo!;
        cardNo1 = effectiveEmployeeId;

        // Scope validation service to identified user
        _validationService.setCurrentUser(effectiveEmployeeId);

        debugPrint(
          'BiometricAttendanceBloc: Face identified as ${identifyResponse.empName} '
          '(card_no: $effectiveEmployeeId)',
        );

        emit(
          state.copyWith(
            status: BiometricAttendanceStatus.markingAttendance,
            faceVerificationMessage:
                'Face identified as ${identifyResponse.empName}',
            faceVerificationConfidence: identifyResponse.confidence,
            errorMessage: null,
          ),
        );
      } else {
        // NORMAL MODE: 1:1 face verification
        final verifyResponse = await _verifyFaceUseCase.call(
          cardNo1: cardNo1,
          frames: base64Frames,
        );

        debugPrint(
          'BiometricAttendanceBloc: Face verification result - '
          'isMatch: ${verifyResponse.isMatch}, '
          'confidence: ${verifyResponse.confidence}, '
          'message: ${verifyResponse.message}',
        );

        if (!verifyResponse.isMatch) {
          emit(
            state.copyWith(
              status: BiometricAttendanceStatus.faceVerificationFailed,
              faceVerificationMessage:
                  verifyResponse.message ?? 'Face verification failed',
              faceVerificationConfidence: verifyResponse.confidence,
              errorMessage:
                  verifyResponse.message ??
                  'Face verification failed. Please try again.',
            ),
          );
          _isCapturing = false;
          return;
        }

        debugPrint(
          'BiometricAttendanceBloc: Face verification succeeded - proceeding to mark attendance',
        );

        emit(
          state.copyWith(
            status: BiometricAttendanceStatus.markingAttendance,
            faceVerificationMessage:
                verifyResponse.message ?? 'Face verified successfully',
            faceVerificationConfidence: verifyResponse.confidence,
            errorMessage: null,
          ),
        );
      }

      // ============================================================
      // STEP 3: MARK ATTENDANCE (only if face verification succeeded)
      // ============================================================

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
        debugPrint('Failed to get device info: $e');
      }

      // Mark attendance via API (biometric_type: 'face')
      BiometricAttendanceResponse? apiResponse;
      try {
        debugPrint('BiometricAttendanceBloc: Calling attendance API for $effectiveEmployeeId...');
        apiResponse = await _markBiometricAttendanceUseCase.call(
          employeeId: effectiveEmployeeId,
          attendanceType: state.attendanceType,
          biometricType: 'face', // Always 'face' for face login
          locationInfo: locationInfoToSave,
          deviceId: deviceId,
          deviceModel: deviceModel,
          appVersion: appVersion,
        );
        debugPrint(
          'BiometricAttendanceBloc: Attendance API response - '
          'success: ${apiResponse.success}, '
          'message: ${apiResponse.message}',
        );
      } catch (e, stackTrace) {
        debugPrint('BiometricAttendanceBloc: Attendance API call failed: $e');
        debugPrint('Stack trace: $stackTrace');
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
        employeeId: effectiveEmployeeId,
        attendanceType: state.attendanceType,
        biometricType: 'face',
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

        debugPrint('=== ATTENDANCE MARKED SUCCESSFULLY ===');
        debugPrint('Success message: $successMsg');
        debugPrint(
          'Today status - Checked in: ${todayStatus.hasCheckedIn}, Checked out: ${todayStatus.hasCheckedOut}',
        );
        debugPrint('Next type: $nextType');

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
        debugPrint(
          'Success state emitted. Status: ${newState.status}, HasCheckedIn: ${newState.hasCheckedInToday}, AttendanceType: ${newState.attendanceType}',
        );

        // Start/stop background location tracking based on what was just marked
        final trackingService = getIt<LocationTrackingService>();
        if (state.attendanceType == 'check_in' && (apiResponse?.success ?? false)) {
          unawaited(trackingService.startTracking(effectiveEmployeeId));
        } else if (state.attendanceType == 'check_out' || todayStatus.hasCheckedOut) {
          unawaited(trackingService.stopTracking());
        }
      } else {
        final errorMsg = apiResponse?.message ?? fileResult.message;
        debugPrint('Failed to save attendance: $errorMsg');
        emit(
          state.copyWith(
            status: BiometricAttendanceStatus
                .ready, // Set to ready so user can retry
            errorMessage: errorMsg,
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'BiometricAttendanceBloc: Error during attendance marking: $e',
      );
      emit(
        state.copyWith(
          status: BiometricAttendanceStatus.error,
          errorMessage: 'Error saving attendance: ${e.toString()}',
        ),
      );
    } finally {
      _isCapturing = false;
      // Dispose camera after use
      if (_cameraController != null) {
        try {
          await _faceCameraDataSource.disposeCamera(_cameraController!);
          _cameraController = null;
        } catch (e) {
          debugPrint('BiometricAttendanceBloc: Error disposing camera: $e');
        }
      }
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
  Future<void> _onReset(
    BiometricAttendanceReset event,
    Emitter<BiometricAttendanceState> emit,
  ) async {
    // Dispose camera if active
    if (_cameraController != null) {
      try {
        await _faceCameraDataSource.disposeCamera(_cameraController!);
        _cameraController = null;
      } catch (e) {
        debugPrint(
          'BiometricAttendanceBloc: Error disposing camera on reset: $e',
        );
      }
    }

    _isCapturing = false;

    emit(
      state.copyWith(
        status: BiometricAttendanceStatus.ready,
        errorMessage: null,
        successMessage: null,
        markedAt: null,
        faceVerificationMessage: null,
        faceVerificationConfidence: null,
        capturedFramesCount: 0,
        totalFramesToCapture: 20,
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

  @override
  Future<void> close() async {
    // Dispose camera if active
    if (_cameraController != null) {
      try {
        await _faceCameraDataSource.disposeCamera(_cameraController!);
        _cameraController = null;
      } catch (e) {
        debugPrint(
          'BiometricAttendanceBloc: Error disposing camera on close: $e',
        );
      }
    }
    return super.close();
  }
}
