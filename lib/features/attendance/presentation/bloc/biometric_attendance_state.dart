part of 'biometric_attendance_bloc.dart';

/// Status of biometric attendance process
enum BiometricAttendanceStatus {
  /// Initial state
  initial,

  /// Loading biometric capabilities
  loading,

  /// Ready to mark attendance
  ready,

  /// Authenticating with biometrics
  authenticating,

  /// Biometric authentication failed
  authFailed,

  /// Submitting attendance to server
  submitting,

  /// Attendance marked successfully
  success,

  /// Error occurred
  error,
}

/// State for biometric attendance
class BiometricAttendanceState extends Equatable {
  const BiometricAttendanceState({
    this.status = BiometricAttendanceStatus.initial,
    this.hasFaceId = false,
    this.hasFingerprint = false,
    this.availableBiometrics = const [],
    this.locationInfo,
    this.isLoadingLocation = false,
    this.locationError,
    this.isLocationServiceEnabled = true,
    this.attendanceType = 'check_in',
    this.errorMessage,
    this.successMessage,
    this.markedAt,
    this.savedFilePath,
    this.hasCheckedInToday = false,
    this.hasCheckedOutToday = false,
    this.todayCheckInTime,
    this.todayCheckOutTime,
  });

  /// Current status of the attendance process
  final BiometricAttendanceStatus status;

  /// Whether face ID is available
  final bool hasFaceId;

  /// Whether fingerprint is available
  final bool hasFingerprint;

  /// List of available biometric types
  final List<BiometricType> availableBiometrics;

  /// Current location information
  final LocationInfo? locationInfo;

  /// Whether location is being loaded
  final bool isLoadingLocation;

  /// Location error message if any
  final String? locationError;

  /// Whether location services (GPS) are enabled on the device
  final bool isLocationServiceEnabled;

  /// Type of attendance (check_in or check_out)
  final String attendanceType;

  /// Error message if any
  final String? errorMessage;

  /// Success message after marking attendance
  final String? successMessage;

  /// Timestamp when attendance was marked
  final DateTime? markedAt;

  /// Path to the saved attendance file
  final String? savedFilePath;

  /// Whether user has checked in today
  final bool hasCheckedInToday;

  /// Whether user has checked out today
  final bool hasCheckedOutToday;

  /// Today's check-in time
  final String? todayCheckInTime;

  /// Today's check-out time
  final String? todayCheckOutTime;

  /// Whether any biometric is available (from state)
  bool get isBiometricAvailable => hasFaceId || hasFingerprint;

  /// Whether location is ready
  /// Made more lenient - allow proceeding even if location is not fully ready
  bool get isLocationReady => !isLoadingLocation;

  /// Whether we can mark attendance
  /// Requires location services to be enabled
  bool get canMarkAttendance {
    if (status != BiometricAttendanceStatus.ready) return false;

    // Location services MUST be enabled
    if (!isLocationServiceEnabled) return false;

    // Allow if biometrics are available in state OR if we have any biometric types
    // This is more lenient than requiring both hasFaceId and hasFingerprint
    if (!isBiometricAvailable && availableBiometrics.isEmpty) return false;

    // Check-in: can only if not already checked in today
    if (attendanceType == 'check_in' && hasCheckedInToday) return false;

    // Check-out: can only if checked in but not checked out
    if (attendanceType == 'check_out') {
      if (!hasCheckedInToday) return false;
      if (hasCheckedOutToday) return false;
    }

    return true;
  }

  /// Get today's status text
  String get todayStatusText {
    if (hasCheckedOutToday) {
      return 'Day Complete';
    } else if (hasCheckedInToday) {
      return 'Checked In';
    }
    return 'Not Checked In';
  }

  /// Human-readable biometric type description
  String get biometricDescription {
    if (hasFaceId && hasFingerprint) return 'Face ID or Fingerprint';
    if (hasFaceId) return 'Face ID';
    if (hasFingerprint) return 'Fingerprint';
    return 'Biometric';
  }

  BiometricAttendanceState copyWith({
    BiometricAttendanceStatus? status,
    bool? hasFaceId,
    bool? hasFingerprint,
    List<BiometricType>? availableBiometrics,
    LocationInfo? locationInfo,
    bool? isLoadingLocation,
    String? locationError,
    bool? isLocationServiceEnabled,
    String? attendanceType,
    String? errorMessage,
    String? successMessage,
    DateTime? markedAt,
    String? savedFilePath,
    bool? hasCheckedInToday,
    bool? hasCheckedOutToday,
    String? todayCheckInTime,
    String? todayCheckOutTime,
  }) {
    return BiometricAttendanceState(
      status: status ?? this.status,
      hasFaceId: hasFaceId ?? this.hasFaceId,
      hasFingerprint: hasFingerprint ?? this.hasFingerprint,
      availableBiometrics: availableBiometrics ?? this.availableBiometrics,
      locationInfo: locationInfo ?? this.locationInfo,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      locationError: locationError ?? this.locationError,
      isLocationServiceEnabled:
          isLocationServiceEnabled ?? this.isLocationServiceEnabled,
      attendanceType: attendanceType ?? this.attendanceType,
      errorMessage: errorMessage,
      successMessage: successMessage,
      markedAt: markedAt,
      savedFilePath: savedFilePath,
      hasCheckedInToday: hasCheckedInToday ?? this.hasCheckedInToday,
      hasCheckedOutToday: hasCheckedOutToday ?? this.hasCheckedOutToday,
      todayCheckInTime: todayCheckInTime ?? this.todayCheckInTime,
      todayCheckOutTime: todayCheckOutTime ?? this.todayCheckOutTime,
    );
  }

  @override
  List<Object?> get props => [
    status,
    hasFaceId,
    hasFingerprint,
    availableBiometrics,
    locationInfo,
    isLoadingLocation,
    locationError,
    isLocationServiceEnabled,
    attendanceType,
    errorMessage,
    successMessage,
    markedAt,
    savedFilePath,
    hasCheckedInToday,
    hasCheckedOutToday,
    todayCheckInTime,
    todayCheckOutTime,
  ];
}
