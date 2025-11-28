import '../entities/profile_entity.dart';

abstract class ProfileRepository {
  Future<ProfileEntity> fetchProfile();
  Future<ProfileEntity> updateContacts({required String email, required String phone});
  ProfileEntity? cachedProfile();
}

