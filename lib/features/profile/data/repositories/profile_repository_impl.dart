import '../../domain/entities/enhanced_profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements EnhancedProfileRepository {
  ProfileRepositoryImpl(this._remoteDataSource, this._empPkProvider);

  final ProfileRemoteDataSource _remoteDataSource;
  final Future<String?> Function() _empPkProvider;

  EnhancedProfileEntity? _cache;

  @override
  Future<EnhancedProfileEntity> fetchProfile() async {
    final empPk = await _empPkProvider() ?? '';
    final profile = await _remoteDataSource.fetchProfile(empPk);
    _cache = profile;
    return profile;
  }

  @override
  Future<EnhancedProfileEntity> updateContacts({
    required String email,
    required String phone,
  }) async {
    // API for updating contacts not provided; return cached profile with updated fields
    final current = _cache ?? await fetchProfile();
    _cache = current.copyWith(email: email, phoneNumber: phone);
    return _cache!;
  }
}
