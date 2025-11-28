import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

class UpdateProfileContactsUseCase {
  UpdateProfileContactsUseCase(this._repository);

  final ProfileRepository _repository;

  Future<ProfileEntity> call({required String email, required String phone}) {
    return _repository.updateContacts(email: email, phone: phone);
  }
}

