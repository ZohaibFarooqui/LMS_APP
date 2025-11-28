import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

class GetProfileUseCase {
  GetProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<ProfileEntity> call() => _repository.fetchProfile();
  ProfileEntity? cached() => _repository.cachedProfile();
}

