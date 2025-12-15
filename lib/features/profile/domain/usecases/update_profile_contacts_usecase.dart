import '../entities/enhanced_profile_entity.dart';
import '../repositories/profile_repository.dart';

class UpdateProfileContactsUseCase {
  UpdateProfileContactsUseCase(this._repository);

  final EnhancedProfileRepository _repository;

  Future<EnhancedProfileEntity> call({required String email, required String phone}) {
    return _repository.updateContacts(email: email, phone: phone);
  }
}

