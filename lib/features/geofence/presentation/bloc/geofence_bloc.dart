import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/geofence_service.dart';
import '../../domain/entities/geofence_status.dart';
import '../../domain/usecases/manual_attendance_override_usecase.dart';
import '../../domain/usecases/mark_automatic_check_in_usecase.dart';

part 'geofence_event.dart';
part 'geofence_state.dart';

class GeoFenceBloc extends Bloc<GeoFenceEvent, GeoFenceState> {
  GeoFenceBloc(
    this._geoFenceService,
    this._markAutomaticCheckInUseCase,
    this._manualAttendanceOverrideUseCase,
  ) : super(const GeoFenceState()) {
    on<GeoFenceStarted>(_onStarted);
    on<_GeoFenceStatusUpdated>(_onStatusUpdated);
    on<GeoFenceManualOverrideRequested>(_onManualOverride);
    on<GeoFenceRefreshRequested>(_onRefreshRequested);
  }

  final GeoFenceService _geoFenceService;
  final MarkAutomaticCheckInUseCase _markAutomaticCheckInUseCase;
  final ManualAttendanceOverrideUseCase _manualAttendanceOverrideUseCase;

  StreamSubscription<GeoFenceStatus>? _subscription;

  Future<void> _onStarted(GeoFenceStarted event, Emitter<GeoFenceState> emit) async {
    _subscription?.cancel();
    _subscription = _geoFenceService.statusStream.listen((status) {
      add(_GeoFenceStatusUpdated(status));
    });
    await _geoFenceService.refreshStatus();
  }

  void _onStatusUpdated(_GeoFenceStatusUpdated event, Emitter<GeoFenceState> emit) async {
    emit(state.copyWith(status: event.status));
    if (event.status.isInside) {
      await _markAutomaticCheckInUseCase();
      emit(state.copyWith(lastMessage: 'Attendance marked automatically'));
    }
  }

  Future<void> _onManualOverride(GeoFenceManualOverrideRequested event, Emitter<GeoFenceState> emit) async {
    emit(state.copyWith(isSubmitting: true));
    await _manualAttendanceOverrideUseCase(note: event.note);
    emit(state.copyWith(isSubmitting: false, lastMessage: 'Manual override submitted'));
  }

  Future<void> _onRefreshRequested(GeoFenceRefreshRequested event, Emitter<GeoFenceState> emit) async {
    await _geoFenceService.refreshStatus();
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

