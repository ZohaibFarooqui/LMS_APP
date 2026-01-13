class AppConfig {
  const AppConfig({
    this.baseUrl = 'http://lms.yousufdewan.com:8080/ords/ws_tms/empdata/',
    // IMPORTANT: For Android devices, use your computer's IP address instead of localhost/127.0.0.1
    // Example: 'http://192.168.1.100:8000' (replace with your actual IP)
    // Find your IP: Windows (ipconfig) or Linux/Mac (ifconfig)
    // For emulator: localhost or 127.0.0.1 works
    // For physical device: MUST use your computer's local network IP (e.g., 192.168.x.x)
    this.faceAuthBaseUrl =
        "http://10.0.0.120:8000", // FastAPI face recognition backend - CHANGE TO YOUR IP FOR PHYSICAL DEVICES
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
  final String faceAuthBaseUrl;
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
