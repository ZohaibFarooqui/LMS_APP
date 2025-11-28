part of 'geofence_bloc.dart';

class GeoFenceState extends Equatable {
  const GeoFenceState({
    this.status,
    this.lastMessage,
    this.isSubmitting = false,
  });

  final GeoFenceStatus? status;
  final String? lastMessage;
  final bool isSubmitting;

  GeoFenceState copyWith({
    GeoFenceStatus? status,
    String? lastMessage,
    bool? isSubmitting,
  }) {
    return GeoFenceState(
      status: status ?? this.status,
      lastMessage: lastMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [status, lastMessage, isSubmitting];
}

