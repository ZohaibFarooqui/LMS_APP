import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/enhanced_profile_entity.dart';
// import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_profile_contacts_usecase.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._getProfileUseCase, this._updateProfileContactsUseCase)
    : super(const ProfileState()) {
    on<ProfileRequested>(_onRequested);
    on<ProfileContactUpdated>(_onContactUpdated);
  }

  final GetProfileUseCase _getProfileUseCase;
  final UpdateProfileContactsUseCase _updateProfileContactsUseCase;

  Future<void> _onRequested(
    ProfileRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading, errorMessage: null));
    try {
      final profile = await _getProfileUseCase();
      emit(state.copyWith(status: ProfileStatus.success, profile: profile));
    } catch (e) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onContactUpdated(
    ProfileContactUpdated event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading, errorMessage: null));
    try {
      final updated = await _updateProfileContactsUseCase(
        email: event.email,
        phone: event.phone,
      );
      emit(state.copyWith(status: ProfileStatus.success, profile: updated));
    } catch (e) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
