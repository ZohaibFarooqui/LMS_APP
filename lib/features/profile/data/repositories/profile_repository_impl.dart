import '../../../../data/datasources/lms_local_data_source.dart';
import '../../../../data/datasources/lms_remote_data_source.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote, this._local);

  final LmsRemoteDataSource _remote;
  final LmsLocalDataSource _local;

  @override
  ProfileEntity? cachedProfile() => _local.profile();

  @override
  Future<ProfileEntity> fetchProfile() async {
    final profile = await _remote.profile();
    await _local.cacheProfile(profile);
    return profile;
  }

  @override
  Future<ProfileEntity> updateContacts({required String email, required String phone}) async {
    // Future: call backend update endpoint. For now, update cached profile.
    final current = _local.profile() ?? await fetchProfile();
    final updated = ProfileEntity(
      name: current.name,
      employeeCode: current.employeeCode,
      cadre: current.cadre,
      department: current.department,
      designation: current.designation,
      joiningDate: current.joiningDate,
      location: current.location,
      cardNumber: current.cardNumber,
      email: email,
      phoneNumber: phone,
    );
    await _local.cacheProfile(updated);
    return updated;
  }
}

