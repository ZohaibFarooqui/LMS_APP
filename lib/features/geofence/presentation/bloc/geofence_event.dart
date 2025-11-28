part of 'geofence_bloc.dart';

abstract class GeoFenceEvent extends Equatable {
  const GeoFenceEvent();

  @override
  List<Object?> get props => [];
}

class GeoFenceStarted extends GeoFenceEvent {
  const GeoFenceStarted();
}

class GeoFenceManualOverrideRequested extends GeoFenceEvent {
  const GeoFenceManualOverrideRequested({this.note});

  final String? note;

  @override
  List<Object?> get props => [note];
}

class GeoFenceRefreshRequested extends GeoFenceEvent {
  const GeoFenceRefreshRequested();
}

class _GeoFenceStatusUpdated extends GeoFenceEvent {
  const _GeoFenceStatusUpdated(this.status);

  final GeoFenceStatus status;

  @override
  List<Object?> get props => [status];
}

