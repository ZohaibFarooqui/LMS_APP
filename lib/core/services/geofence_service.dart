import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../config/app_config.dart';
import '../../features/geofence/domain/entities/geofence_status.dart';
import 'location_service.dart';

class GeoFenceService {
  GeoFenceService(this._config, this._locationService);

  final AppConfig _config;
  final LocationService _locationService;
  final _controller = StreamController<GeoFenceStatus>.broadcast();

  Stream<GeoFenceStatus> get statusStream => _controller.stream;

  Future<void> refreshStatus() async {
    try {
      final position = await _locationService.currentPosition();
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _config.defaultGeoLatitude,
        _config.defaultGeoLongitude,
      );
      _controller.add(
        GeoFenceStatus(
          isInside: distance <= _config.geoFenceRadiusMeters,
          distanceMeters: distance,
          lastUpdated: DateTime.now(),
        ),
      );
    } catch (_) {
      // Ignore errors for now; UI will show last known status.
    }
  }

  void dispose() {
    _controller.close();
  }
}

