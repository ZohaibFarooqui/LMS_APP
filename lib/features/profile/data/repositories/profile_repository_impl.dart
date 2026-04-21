import '../../../../data/datasources/lms_local_data_source.dart';
import '../../../../data/datasources/lms_remote_data_source.dart';
import '../../domain/entities/enhanced_profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements EnhancedProfileRepository {
  ProfileRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final LmsRemoteDataSource _remoteDataSource;
  final LmsLocalDataSource _localDataSource;

  @override
  Future<EnhancedProfileEntity> fetchProfile() async {
    // ALWAYS fetch fresh from API - NO caching across users
    // This ensures data integrity and prevents showing previous user's data
    try {
      final profile = await _remoteDataSource.profile();
      // Ensure static schedule is always set
      return profile.copyWith(workSchedule: WorkSchedule.defaultSchedule);
    } catch (e) {
      // If profile API fails, try to get basic info from dashboard cache
      // This is only a fallback for display purposes
      final dashboardData = _localDataSource.dashboard();
      if (dashboardData != null) {
        return _createProfileFromDashboard(dashboardData);
      }

      // Last resort: return minimal profile
      return EnhancedProfileEntity(
        id: '0',
        employeeCode: '-',
        name: 'Loading...',
        email: '',
        phoneNumber: '',
        gender: 'M',
        dateOfBirth: '-',
        joiningDate: '-',
        department: '-',
        designation: '-',
        cadre: '-',
        location: '-',
        branch: '-',
        cardNumber: '-',
        workSchedule: WorkSchedule.defaultSchedule,
      );
    }
  }

  DateTime _parseDate(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      // Try alternative formats
      try {
        // Handle "27-oct-2025" format
        final parts = dateString.split('-');
        if (parts.length == 3) {
          final months = {
            'jan': 1,
            'feb': 2,
            'mar': 3,
            'apr': 4,
            'may': 5,
            'jun': 6,
            'jul': 7,
            'aug': 8,
            'sep': 9,
            'oct': 10,
            'nov': 11,
            'dec': 12,
          };
          final month = months[parts[1].toLowerCase()] ?? 1;
          final day = int.tryParse(parts[0]) ?? 1;
          final year = int.tryParse(parts[2]) ?? DateTime.now().year;
          return DateTime(year, month, day);
        }
      } catch (e2) {
        // Ignore
      }
      return DateTime.now();
    }
  }

  EnhancedProfileEntity _createProfileFromDashboard(dashboardData) {
    return EnhancedProfileEntity(
      id: dashboardData.empPk.toString(),
      employeeCode: dashboardData.empNo,
      name: dashboardData.empName,
      email: '',
      phoneNumber: '',
      gender: 'M',
      dateOfBirth: '-',
      joiningDate: dashboardData.dateOfJoin,
      department: dashboardData.department,
      designation: dashboardData.designation,
      cadre: dashboardData.designation,
      location: dashboardData.brnchnm,
      branch: dashboardData.brnchnm,
      cardNumber: dashboardData.cardNo1,
      workSchedule: WorkSchedule.defaultSchedule, // Always use static schedule
    );
  }

  @override
  Future<EnhancedProfileEntity> updateEmergencyContact({
    required String name,
    required String phone,
    required String relationship,
  }) async {
    // Fetch fresh profile first, then update emergency contact
    final current = await fetchProfile();
    final emergencyContact = EmergencyContact(
      name: name,
      phoneNumber: phone,
      relationship: relationship,
    );
    final updated = current.copyWith(
      emergencyContact: emergencyContact,
      workSchedule:
          WorkSchedule.defaultSchedule, // Always preserve static schedule
    );
    return updated;
  }

  @override
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    return await _remoteDataSource.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }
}
