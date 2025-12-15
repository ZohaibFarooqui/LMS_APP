class AppConfig {
  const AppConfig({
    this.baseUrl = 'http://lms.yousufdewan.com:8080/ords/ws_tms/empdata/',
    this.appName = 'YDC LMS',
    this.useMockData = false,
    this.defaultGeoLatitude = 24.85851,
    this.defaultGeoLongitude = 67.05,
    this.geoFenceRadiusMeters = 200,
    this.geoFenceMonitoringIntervalSeconds = 20,
    this.geoFenceMaxAccuracyMeters = 30.0,
    this.enableGeoFenceAntiSpoofing = true,
  });


  final String baseUrl;
  final String appName;
  final bool useMockData;
  
  // Geofence Configuration
  final double defaultGeoLatitude;
  final double defaultGeoLongitude;
  final int geoFenceRadiusMeters;
  
  /// Interval for periodic geofence checks in seconds
  final int geoFenceMonitoringIntervalSeconds;
  
  /// Maximum acceptable GPS accuracy in meters
  /// Readings with worse accuracy will be filtered
  final double geoFenceMaxAccuracyMeters;
  
  /// Whether to enable mock location detection
  final bool enableGeoFenceAntiSpoofing;
}

