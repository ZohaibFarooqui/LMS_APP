import 'package:equatable/equatable.dart';

class GeoFenceStatus extends Equatable {
  const GeoFenceStatus({
    required this.isInside,
    required this.distanceMeters,
    required this.lastUpdated,
  });

  final bool isInside;
  final double distanceMeters;
  final DateTime lastUpdated;

  @override
  List<Object?> get props => [isInside, distanceMeters, lastUpdated];
}

