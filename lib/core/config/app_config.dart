class AppConfig {
  const AppConfig({
    this.baseUrl = 'https://api.ydc.com/lms',
    this.appName = 'YDC LMS',
    this.useMockData = true,
    this.defaultGeoLatitude = 24.85851,
    this.defaultGeoLongitude = 67.05,
    this.geoFenceRadiusMeters = 200,
  });

  final String baseUrl;
  final String appName;
  final bool useMockData;
  final double defaultGeoLatitude;
  final double defaultGeoLongitude;
  final int geoFenceRadiusMeters;
}

