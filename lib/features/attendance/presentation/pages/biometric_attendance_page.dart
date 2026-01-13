import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../bloc/biometric_attendance_bloc.dart';

class BiometricAttendancePage extends StatelessWidget {
  const BiometricAttendancePage({super.key});

  void _onMarkAttendance(BuildContext context, String type) {
    final bloc = context.read<BiometricAttendanceBloc>();
    bloc.add(BiometricAttendanceTypeChanged(type));
    bloc.add(const BiometricAttendanceMarkRequested());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Biometric Attendance'), elevation: 0),
      body: BlocConsumer<BiometricAttendanceBloc, BiometricAttendanceState>(
        listenWhen: (previous, current) {
          // Only listen to status and message changes
          return previous.status != current.status ||
              previous.successMessage != current.successMessage ||
              previous.errorMessage != current.errorMessage;
        },
        listener: (context, state) {
          if (state.status == BiometricAttendanceStatus.success &&
              state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 3),
              ),
            );
          } else if ((state.status == BiometricAttendanceStatus.error ||
                  state.status == BiometricAttendanceStatus.faceNotRegistered ||
                  state.status ==
                      BiometricAttendanceStatus.faceVerificationFailed) &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 4),
              ),
            );
          } else if (state.status ==
                  BiometricAttendanceStatus.faceVerificationFailed &&
              state.faceVerificationMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.faceVerificationMessage!),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        buildWhen: (previous, current) {
          // Only rebuild when UI-relevant state changes
          return previous.status != current.status ||
              previous.isLocationServiceEnabled !=
                  current.isLocationServiceEnabled ||
              previous.locationInfo != current.locationInfo ||
              previous.errorMessage != current.errorMessage;
        },
        builder: (context, state) {
          // Show loading for initial states
          if (state.status == BiometricAttendanceStatus.checkingFaceStatus ||
              state.status == BiometricAttendanceStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show error for face not registered
          if (state.status == BiometricAttendanceStatus.faceNotRegistered) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.0.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.face_unlock_outlined,
                      size: 64.sp,
                      color: AppColors.error,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Face Not Registered',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      state.errorMessage ??
                          'Please register your face first before marking attendance.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Location Service Warning
                if (!state.isLocationServiceEnabled) ...[
                  _LocationServiceWarning(isDark: isDark, theme: theme),
                  SizedBox(height: 16.h),
                ],

                // Today's Status Card
                _TodayStatusCard(state: state, isDark: isDark, theme: theme),
                SizedBox(height: 16.h),

                // Location Information Card
                _LocationInfoCard(state: state, isDark: isDark, theme: theme),
                SizedBox(height: 24.h),

                // Action Buttons
                if (state.status ==
                        BiometricAttendanceStatus.capturingFaceFrames ||
                    state.status == BiometricAttendanceStatus.verifyingFace ||
                    state.status == BiometricAttendanceStatus.markingAttendance)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          if (state.status ==
                              BiometricAttendanceStatus.capturingFaceFrames)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Text(
                                'Capturing frames: ${state.capturedFramesCount}/${state.totalFramesToCapture}',
                                style: TextStyle(fontSize: 14.sp),
                              ),
                            )
                          else if (state.status ==
                              BiometricAttendanceStatus.verifyingFace)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Text(
                                'Verifying face...',
                                style: TextStyle(fontSize: 14.sp),
                              ),
                            )
                          else if (state.status ==
                              BiometricAttendanceStatus.markingAttendance)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Text(
                                'Marking attendance...',
                                style: TextStyle(fontSize: 14.sp),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                else
                  _ActionButtons(
                    state: state,
                    onMarkAttendance: _onMarkAttendance,
                    isDark: isDark,
                    theme: theme,
                  ),

                // Error Message Display
                if (state.errorMessage != null &&
                    state.status != BiometricAttendanceStatus.error &&
                    state.status !=
                        BiometricAttendanceStatus.faceNotRegistered &&
                    state.status !=
                        BiometricAttendanceStatus.faceVerificationFailed) ...[
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          color: AppColors.error,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            state.errorMessage!,
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TodayStatusCard extends StatelessWidget {
  const _TodayStatusCard({
    required this.state,
    required this.isDark,
    required this.theme,
  });

  final BiometricAttendanceState state;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.secondary : theme.primaryColor)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: isDark ? AppColors.secondary : theme.primaryColor,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Status',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      DateFormatter.formatDate(DateTime.now()),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark
                            ? Colors.white60
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: _getStatusColor(
                    state,
                    isDark,
                    theme,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  state.todayStatusText,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(state, isDark, theme),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: _StatusItem(
                  icon: Icons.login_rounded,
                  label: 'Check In',
                  value: state.todayCheckInTime ?? '--',
                  color: state.hasCheckedInToday
                      ? AppColors.success
                      : Colors.grey,
                  isDark: isDark,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _StatusItem(
                  icon: Icons.logout_rounded,
                  label: 'Check Out',
                  value: state.todayCheckOutTime ?? '--',
                  color: state.hasCheckedOutToday
                      ? AppColors.error
                      : Colors.grey,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          if (state.markedAt != null) ...[
            SizedBox(height: 16.h),
            Divider(color: isDark ? Colors.white12 : Colors.grey.shade200),
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 16.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Last marked: ${DateFormatter.formatDateTime(state.markedAt!)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(
    BiometricAttendanceState state,
    bool isDark,
    ThemeData theme,
  ) {
    if (state.hasCheckedOutToday) {
      return AppColors.success;
    } else if (state.hasCheckedInToday) {
      return AppColors.warning;
    }
    return isDark ? AppColors.secondary : theme.primaryColor;
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16.sp, color: color),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: color == Colors.grey
                ? (isDark ? Colors.white38 : Colors.grey.shade400)
                : color,
          ),
        ),
      ],
    );
  }
}

class _LocationInfoCard extends StatelessWidget {
  const _LocationInfoCard({
    required this.state,
    required this.isDark,
    required this.theme,
  });

  final BiometricAttendanceState state;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.secondary : theme.primaryColor)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: isDark ? AppColors.secondary : theme.primaryColor,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location Information',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    if (state.isLoadingLocation)
                      Text(
                        'Fetching location...',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark
                              ? Colors.white60
                              : AppColors.textSecondary,
                        ),
                      )
                    else if (state.locationError != null)
                      Text(
                        'Location error',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.error,
                        ),
                      )
                    else
                      Text(
                        'Current location',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark
                              ? Colors.white60
                              : AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          if (state.isLoadingLocation)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (state.locationError != null)
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      state.locationError!,
                      style: TextStyle(color: AppColors.error, fontSize: 12.sp),
                    ),
                  ),
                ],
              ),
            )
          else if (state.locationInfo != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Coordinates
                _LocationDetailItem(
                  icon: Icons.my_location_rounded,
                  label: 'Coordinates',
                  value:
                      '${state.locationInfo!.latitude.toStringAsFixed(6)}, ${state.locationInfo!.longitude.toStringAsFixed(6)}',
                  isDark: isDark,
                ),
                SizedBox(height: 12.h),

                // Accuracy
                _LocationDetailItem(
                  icon: Icons.gps_fixed_rounded,
                  label: 'Accuracy',
                  value:
                      '${state.locationInfo!.accuracy.toStringAsFixed(1)} meters',
                  isDark: isDark,
                ),
                SizedBox(height: 12.h),

                // Address
                if (state.locationInfo!.formattedAddress != null &&
                    state.locationInfo!.formattedAddress!.isNotEmpty) ...[
                  _LocationDetailItem(
                    icon: Icons.home_rounded,
                    label: 'Address',
                    value: state.locationInfo!.formattedAddress!,
                    isDark: isDark,
                    isMultiline: true,
                  ),
                  SizedBox(height: 12.h),
                ],

                // Nearest Landmark
                if (state.locationInfo!.nearestLandmark != null &&
                    state.locationInfo!.nearestLandmark!.isNotEmpty) ...[
                  _LocationDetailItem(
                    icon: Icons.place_rounded,
                    label: 'Nearest Landmark',
                    value: state.locationInfo!.nearestLandmark!,
                    isDark: isDark,
                    highlight: true,
                  ),
                  if (state.locationInfo!.distanceToLandmark != null) ...[
                    SizedBox(height: 4.h),
                    Padding(
                      padding: EdgeInsets.only(left: 28.w),
                      child: Text(
                        '${state.locationInfo!.distanceToLandmark!.toStringAsFixed(0)} meters away',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: isDark
                              ? Colors.white54
                              : AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 12.h),
                ],

                // Famous Place
                if (state.locationInfo!.famousPlace != null &&
                    state.locationInfo!.famousPlace!.isNotEmpty) ...[
                  _LocationDetailItem(
                    icon: Icons.star_rounded,
                    label: 'Famous Place',
                    value: state.locationInfo!.famousPlace!,
                    isDark: isDark,
                  ),
                  SizedBox(height: 12.h),
                ],

                // Area/City
                if (state.locationInfo!.subLocality != null ||
                    state.locationInfo!.locality != null) ...[
                  _LocationDetailItem(
                    icon: Icons.location_city_rounded,
                    label: 'Area',
                    value: [
                      state.locationInfo!.subLocality,
                      state.locationInfo!.locality,
                    ].where((e) => e != null && e.isNotEmpty).join(', '),
                    isDark: isDark,
                  ),
                ],
              ],
            )
          else
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Location information not available',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LocationDetailItem extends StatelessWidget {
  const _LocationDetailItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.isMultiline = false,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final bool isMultiline;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: isMultiline
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 18.sp,
          color: highlight
              ? (isDark ? AppColors.secondary : theme.primaryColor)
              : (isDark ? Colors.white54 : AppColors.textSecondary),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: highlight
                      ? (isDark ? AppColors.secondary : theme.primaryColor)
                      : (isDark ? Colors.white : AppColors.textPrimary),
                  fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LocationServiceWarning extends StatelessWidget {
  const _LocationServiceWarning({required this.isDark, required this.theme});

  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_off_rounded,
                color: AppColors.warning,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Location Services Disabled',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Please turn on your mobile location or GPS to mark attendance.',
            style: TextStyle(
              fontSize: 13.sp,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<BiometricAttendanceBloc>().add(
                  const BiometricAttendanceOpenLocationSettings(),
                );
              },
              icon: Icon(Icons.settings_rounded, size: 18.sp),
              label: Text(
                'Open Location Settings',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.state,
    required this.onMarkAttendance,
    required this.isDark,
    required this.theme,
  });

  final BiometricAttendanceState state;
  final Function(BuildContext, String) onMarkAttendance;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isLocationEnabled = state.isLocationServiceEnabled;

    final canCheckIn =
        isLocationEnabled &&
        state.attendanceType == 'check_in' &&
        !state.hasCheckedInToday &&
        state.canMarkAttendance;
    final canCheckOut =
        isLocationEnabled &&
        state.attendanceType == 'check_out' &&
        state.hasCheckedInToday &&
        !state.hasCheckedOutToday &&
        state.canMarkAttendance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Check In Button
        ElevatedButton.icon(
          onPressed: canCheckIn
              ? () => onMarkAttendance(context, 'check_in')
              : () {
                  if (!isLocationEnabled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Please turn on your mobile location or GPS to mark attendance.',
                        ),
                        backgroundColor: AppColors.warning,
                        duration: const Duration(seconds: 4),
                        action: SnackBarAction(
                          label: 'Settings',
                          textColor: Colors.white,
                          onPressed: () {
                            context.read<BiometricAttendanceBloc>().add(
                              const BiometricAttendanceOpenLocationSettings(),
                            );
                          },
                        ),
                      ),
                    );
                  }
                },
          icon: Icon(Icons.login_rounded, size: 20.sp),
          label: Text(
            'Check In',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            backgroundColor: canCheckIn
                ? AppColors.success
                : Colors.grey.shade300,
            foregroundColor: canCheckIn ? Colors.white : Colors.grey.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: canCheckIn ? 4 : 0,
          ),
        ),
        SizedBox(height: 12.h),

        // Check Out Button
        ElevatedButton.icon(
          onPressed: canCheckOut
              ? () => onMarkAttendance(context, 'check_out')
              : () {
                  if (!isLocationEnabled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Please turn on your mobile location or GPS to mark attendance.',
                        ),
                        backgroundColor: AppColors.warning,
                        duration: const Duration(seconds: 4),
                        action: SnackBarAction(
                          label: 'Settings',
                          textColor: Colors.white,
                          onPressed: () {
                            context.read<BiometricAttendanceBloc>().add(
                              const BiometricAttendanceOpenLocationSettings(),
                            );
                          },
                        ),
                      ),
                    );
                  }
                },
          icon: Icon(Icons.logout_rounded, size: 20.sp),
          label: Text(
            'Check Out',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            backgroundColor: canCheckOut
                ? AppColors.error
                : Colors.grey.shade300,
            foregroundColor: canCheckOut ? Colors.white : Colors.grey.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: canCheckOut ? 4 : 0,
          ),
        ),

        // Info Text
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.secondary : theme.primaryColor)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16.sp,
                color: isDark ? AppColors.secondary : theme.primaryColor,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  state.biometricDescription,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
