import '../entities/enhanced_profile_entity.dart';

abstract class EnhancedProfileRepository {
  Future<EnhancedProfileEntity> fetchProfile();
  Future<EnhancedProfileEntity> updateContacts({
    required String email,
    required String phone,
  });
}
