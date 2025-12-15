import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../di/service_locator.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../authentication/data/datasources/auth_local_data_source.dart';
import '../../domain/entities/enhanced_profile_entity.dart';
import '../bloc/profile_bloc.dart';

/// Enhanced Profile Page with premium UI
///
/// Features:
/// - Personal information display
/// - Emergency contact management
/// - Day type calendar view
/// - Contact editing
/// - Biometric account linking
class EnhancedProfilePage extends StatefulWidget {
  const EnhancedProfilePage({super.key});

  @override
  State<EnhancedProfilePage> createState() => _EnhancedProfilePageState();
}

class _EnhancedProfilePageState extends State<EnhancedProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileBloc>()..add(const ProfileRequested()),
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state.profile != null) {
            _emailController.text = state.profile!.email;
            _phoneController.text = state.profile!.phoneNumber;
          }

          if (state.status == ProfileStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Profile updated successfully'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == ProfileStatus.loading && state.profile == null) {
            return const LoadingIndicator();
          }

          return _buildContent(context, state);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ProfileState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Mock enhanced profile for demo
    final mockProfile = EnhancedProfileEntity(
      id: '106',
      employeeCode: 'F-84',
      name: state.profile?.name ?? 'John Doe',
      email: state.profile?.email ?? 'john.doe@company.com',
      phoneNumber: state.profile?.phoneNumber ?? '3458000041',
      gender: 'M',
      dateOfBirth: DateTime(1990, 5, 15),
      joiningDate: DateTime(2019, 11, 21),
      department: state.profile?.department ?? 'IT',
      designation: state.profile?.designation ?? 'DY. GENERAL MANAGER',
      cadre: state.profile?.cadre ?? 'Management',
      location: state.profile?.location ?? 'Karachi',
      branch: 'Head Office',
      cardNumber: state.profile?.cardNumber ?? '10000106.1.2',
      emergencyContact: const EmergencyContact(
        name: 'Jane Doe',
        relationship: 'Spouse',
        phoneNumber: '0300XXXXXXX',
      ),
      workSchedule: WorkSchedule.defaultSchedule,
    );

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverToBoxAdapter(
          child: _buildProfileHeader(context, mockProfile, isDark),
        ),
        SliverPersistentHeader(
          delegate: _SliverAppBarDelegate(
            TabBar(
              controller: _tabController,
              labelColor: isDark ? AppColors.secondary : theme.primaryColor,
              unselectedLabelColor: isDark ? Colors.white54 : Colors.grey,
              indicatorColor: isDark ? AppColors.secondary : theme.primaryColor,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Info', icon: Icon(Icons.person_outline, size: 20)),
                Tab(
                  text: 'Schedule',
                  icon: Icon(Icons.calendar_today, size: 20),
                ),
                Tab(text: 'Edit', icon: Icon(Icons.edit_outlined, size: 20)),
              ],
            ),
            isDark: isDark,
          ),
          pinned: true,
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(context, mockProfile, isDark),
          _buildScheduleTab(context, mockProfile, isDark),
          _buildEditTab(context, mockProfile, state, isDark),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    EnhancedProfileEntity profile,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E1E1E), const Color(0xFF2D2D2D)]
              : [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.8)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Profile Avatar (No upload feature)
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
                child: CircleAvatar(
                radius: 50.w,
                backgroundColor: Colors.white,
                child: Text(
                  profile.initials,
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.secondary : theme.primaryColor,
                  ),
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // Name
            Text(
              profile.name,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            SizedBox(height: 4.h),

            // Designation & Department
            Text(
              '${profile.designation} • ${profile.department}',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),

            SizedBox(height: 12.h),

            // Employee Code Badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20.r),
              ),
                  child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.badge_outlined, size: 16.sp, color: Colors.white),
                  SizedBox(width: 6.w),
                  Text(
                    profile.employeeCode,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // Quick Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickStat(
                  'Years',
                  '${profile.yearsOfService}',
                  Icons.work_history_outlined,
                ),
                _buildQuickStat(
                  'Gender',
                  profile.genderText,
                  profile.isMale ? Icons.male_rounded : Icons.female_rounded,
                ),
                _buildQuickStat(
                  'Branch',
                  profile.branch,
                  Icons.location_city_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 22.sp),
        ),
        SizedBox(height: 6.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTab(
    BuildContext context,
    EnhancedProfileEntity profile,
    bool isDark,
  ) {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        // Personal Information
        _buildSection(
          context,
          title: 'Personal Information',
          icon: Icons.person_outline,
          isDark: isDark,
          children: [
            _buildInfoRow('Email', profile.email, Icons.email_outlined, isDark),
            _buildInfoRow(
              'Phone',
              profile.phoneNumber,
              Icons.phone_outlined,
              isDark,
            ),
            _buildInfoRow(
              'Date of Birth',
              _formatDate(profile.dateOfBirth),
              Icons.cake_outlined,
              isDark,
            ),
            _buildInfoRow(
              'Gender',
              profile.genderText,
              profile.isMale ? Icons.male_rounded : Icons.female_rounded,
              isDark,
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // Work Information
        _buildSection(
          context,
          title: 'Work Information',
          icon: Icons.work_outline,
          isDark: isDark,
          children: [
            _buildInfoRow(
              'Joining Date',
              _formatDate(profile.joiningDate),
              Icons.event_outlined,
              isDark,
            ),
            _buildInfoRow(
              'Cadre',
              profile.cadre,
              Icons.category_outlined,
              isDark,
            ),
            _buildInfoRow(
              'Location',
              profile.location,
              Icons.location_on_outlined,
              isDark,
            ),
            _buildInfoRow(
              'Card Number',
              profile.cardNumber,
              Icons.credit_card_outlined,
              isDark,
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // Emergency Contact
        _buildSection(
          context,
          title: 'Emergency Contact',
          icon: Icons.emergency_outlined,
          isDark: isDark,
          children: profile.emergencyContact != null
              ? [
                  _buildInfoRow(
                    'Name',
                    profile.emergencyContact!.name,
                    Icons.person_outline,
                    isDark,
                  ),
                  _buildInfoRow(
                    'Relationship',
                    profile.emergencyContact!.relationship,
                    Icons.family_restroom_outlined,
                    isDark,
                  ),
                  _buildInfoRow(
                    'Phone',
                    profile.emergencyContact!.phoneNumber,
                    Icons.phone_outlined,
                    isDark,
                  ),
                ]
              : [
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Text(
                      'No emergency contact added. Tap Edit to add one.',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white54
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
        ),

        SizedBox(height: 16.h),

        // Reporting Manager
        if (profile.reportingTo != null)
          _buildSection(
            context,
            title: 'Reporting To',
            icon: Icons.supervisor_account_outlined,
            isDark: isDark,
            children: [
              _buildInfoRow(
                'Name',
                profile.reportingTo!.name,
                Icons.person_outline,
                isDark,
              ),
              _buildInfoRow(
                'Designation',
                profile.reportingTo!.designation,
                Icons.work_outline,
                isDark,
              ),
              if (profile.reportingTo!.phoneNumber != null)
                _buildInfoRow(
                  'Phone',
                  profile.reportingTo!.phoneNumber!,
                  Icons.phone_outlined,
                  isDark,
                ),
            ],
          ),

        SizedBox(height: 80.h),
      ],
    );
  }

  Widget _buildScheduleTab(
    BuildContext context,
    EnhancedProfileEntity profile,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        // Day Types Legend
        _buildSection(
          context,
          title: 'Day Types',
          icon: Icons.legend_toggle_outlined,
          isDark: isDark,
          children: [
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  _buildDayTypeLegend(
                    'G',
                    'General (Working)',
                    AppColors.success,
                    isDark,
                  ),
                  SizedBox(width: 16.w),
                  _buildDayTypeLegend(
                    'R',
                    'Rest (Weekly Off)',
                    Colors.orange,
                    isDark,
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // Weekly Schedule
        _buildSection(
          context,
          title: 'Weekly Schedule',
          icon: Icons.calendar_view_week_outlined,
          isDark: isDark,
          children: [
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                    .asMap()
                    .entries
                    .map((entry) {
                      final dayIndex = entry.key + 1; // 1-7 for Monday-Sunday
                      final dayType = profile.getDayType(
                        DateTime.now().subtract(
                          Duration(days: DateTime.now().weekday - dayIndex),
                        ),
                      );

                      return _buildDayCircle(
                        entry.value,
                        dayType,
                        theme,
                        isDark,
                      );
                    })
                    .toList(),
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // Shift Timings
        if (profile.workSchedule != null)
          _buildSection(
            context,
            title: 'Shift Timings',
            icon: Icons.access_time_outlined,
            isDark: isDark,
            children: [
              _buildInfoRow(
                'Start Time',
                profile.workSchedule!.shiftStartTime ?? '09:00 AM',
                Icons.login_outlined,
                isDark,
              ),
              _buildInfoRow(
                'End Time',
                profile.workSchedule!.shiftEndTime ?? '06:00 PM',
                Icons.logout_outlined,
                isDark,
              ),
              _buildInfoRow(
                'Grace Period',
                '${profile.workSchedule!.graceMinutes} minutes',
                Icons.timer_outlined,
                isDark,
              ),
            ],
          ),

        SizedBox(height: 80.h),
      ],
    );
  }

  Widget _buildEditTab(
    BuildContext context,
    EnhancedProfileEntity profile,
    ProfileState state,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        // Contact Information
        _buildSection(
          context,
          title: 'Contact Information',
          icon: Icons.contact_mail_outlined,
          isDark: isDark,
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    isDark: isDark,
                  ),
                  SizedBox(height: 16.h),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // Emergency Contact
        _buildSection(
          context,
          title: 'Emergency Contact',
          icon: Icons.emergency_outlined,
          isDark: isDark,
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  _buildTextField(
                    controller: _emergencyNameController,
                    label: 'Contact Name',
                    icon: Icons.person_outline,
                    isDark: isDark,
                  ),
                  SizedBox(height: 16.h),
                  _buildTextField(
                    controller: _emergencyRelationController,
                    label: 'Relationship',
                    icon: Icons.family_restroom_outlined,
                    isDark: isDark,
                  ),
                  SizedBox(height: 16.h),
                  _buildTextField(
                    controller: _emergencyPhoneController,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // Biometric Account Linking
        _buildSection(
          context,
          title: 'Security & Biometric',
          icon: Icons.fingerprint_outlined,
          isDark: isDark,
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  FutureBuilder<bool>(
                    future: getIt<AuthLocalDataSource>().isBiometricEnabled(),
                    builder: (context, snapshot) {
                      final isEnabled = snapshot.data ?? false;
                      return Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: isEnabled
                              ? AppColors.success.withValues(alpha: 0.1)
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: isEnabled
                                ? AppColors.success
                                : (isDark
                                      ? Colors.white12
                                      : Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isEnabled
                                  ? Icons.fingerprint
                                  : Icons.fingerprint_outlined,
                              color: isEnabled
                                  ? AppColors.success
                                  : (isDark
                                        ? Colors.white54
                                        : AppColors.textSecondary),
                              size: 28.sp,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEnabled
                                        ? 'Biometric Linked'
                                        : 'Link Biometric',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    isEnabled
                                        ? 'Your biometric is linked to your account'
                                        : 'Link fingerprint/face ID for quick login',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: isDark
                                          ? Colors.white54
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  _showBiometricLinkingDialog(context),
                              icon: Icon(
                                isEnabled
                                    ? Icons.settings
                                    : Icons.arrow_forward_ios,
                                size: 20.sp,
                                color: isDark
                                    ? AppColors.secondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 24.h),

        // Save Button
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor,
                theme.primaryColor.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: state.status == ProfileStatus.loading
                  ? null
                  : () => _saveProfile(context),
              borderRadius: BorderRadius.circular(16.r),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (state.status == ProfileStatus.loading)
                      SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    else
                      Icon(
                        Icons.save_outlined,
                        color: Colors.white,
                        size: 22.sp,
                      ),
                    SizedBox(width: 10.w),
                    Text(
                      state.status == ProfileStatus.loading
                          ? 'Saving...'
                          : 'Save Changes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        SizedBox(height: 80.h),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isDark,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.secondary : theme.primaryColor)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(icon,
                      color: isDark ? AppColors.secondary : theme.primaryColor,
                      size: 20.sp),
                ),
                SizedBox(width: 12.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20.sp,
            color: isDark ? AppColors.secondary : AppColors.textSecondary,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDark ? AppColors.secondary : AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon,
            size: 22.sp,
            color: isDark ? AppColors.secondary : Colors.grey.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade50,
      ),
    );
  }

  Widget _buildDayTypeLegend(
    String code,
    String label,
    Color color,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          width: 28.w,
          height: 28.w,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              code,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            color: isDark ? Colors.white70 : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDayCircle(
    String day,
    DayType dayType,
    ThemeData theme,
    bool isDark,
  ) {
    final color = dayType == DayType.rest ? Colors.orange : AppColors.success;

    return Column(
      children: [
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              dayType.code,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          day,
          style: TextStyle(
            fontSize: 11.sp,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _showBiometricLinkingDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final biometricService = getIt<BiometricService>();
    final authLocalDataSource = getIt<AuthLocalDataSource>();

    // Check if biometric is already enabled
    final isEnabled = await authLocalDataSource.isBiometricEnabled();
    final isAvailable = await biometricService.isBiometricAvailable();
    final availableBiometrics = await biometricService.getAvailableBiometrics();

    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Biometric authentication is not available on this device',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          'Link Biometric Account',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Link your ${availableBiometrics.contains(BiometricType.face) ? "Face ID" : "Fingerprint"} to your account for quick login and attendance marking.',
              style: TextStyle(
                fontSize: 14.sp,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 16.h),
            if (isEnabled)
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Biometric is currently linked',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // Authenticate to link
              final result = await biometricService.authenticate(
                reason: 'Authenticate to link biometric to your account',
                biometricOnly: true,
              );

              if (result.success) {
                await authLocalDataSource.setBiometricEnabled(true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Biometric linked successfully!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(isEnabled ? 'Re-link' : 'Link Now'),
          ),
        ],
      ),
    );
  }

  void _saveProfile(BuildContext context) {
    context.read<ProfileBloc>().add(
      ProfileContactUpdated(
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar, {required this.isDark});

  final TabBar _tabBar;
  final bool isDark;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
