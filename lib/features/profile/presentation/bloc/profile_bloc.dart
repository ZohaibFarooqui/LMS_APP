import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/profile_entity.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_profile_contacts_usecase.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._getProfileUseCase, this._updateProfileContactsUseCase) : super(const ProfileState()) {
    on<ProfileRequested>(_onRequested);
    on<ProfileContactUpdated>(_onContactUpdated);
  }

  final GetProfileUseCase _getProfileUseCase;
  final UpdateProfileContactsUseCase _updateProfileContactsUseCase;

  Future<void> _onRequested(ProfileRequested event, Emitter<ProfileState> emit) async {
    final cached = _getProfileUseCase.cached();
    if (cached != null) {
      emit(state.copyWith(status: ProfileStatus.success, profile: cached));
    } else {
      emit(state.copyWith(status: ProfileStatus.loading));
    }
    try {
      final profile = await _getProfileUseCase();
      emit(state.copyWith(status: ProfileStatus.success, profile: profile));
    } catch (error) {
      emit(state.copyWith(status: ProfileStatus.failure, errorMessage: error.toString()));
    }
  }

  Future<void> _onContactUpdated(ProfileContactUpdated event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(status: ProfileStatus.updating));
    try {
      final profile = await _updateProfileContactsUseCase(email: event.email, phone: event.phone);
      emit(state.copyWith(status: ProfileStatus.success, profile: profile));
    } catch (error) {
      emit(state.copyWith(status: ProfileStatus.failure, errorMessage: error.toString()));
    }
  }
}

