import 'package:dio/dio.dart';

/// Shared Dio client configured for the LMS APIs.
class DioClient {
  DioClient._()
    : dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          contentType: 'application/json',
          responseType: ResponseType.json,
        ),
      );

  // static const String _baseUrl =
  //     'http://lms.yousufdewan.com:8080/ords/ws_tms/empdata';
  // NOTE: Use your PC's LAN IP — 127.0.0.1 only works on emulator, not physical devices.
  // Run `ipconfig` on Windows to find it (look for IPv4 Address).
  // static const String _baseUrl = 'http://10.0.0.120:8001';
  // static const String _baseUrl = 'http://apps.d-tech.com.pk:8001';
  static const String _baseUrl = 'http://163.61.91.221:8001';

  static final DioClient _instance = DioClient._();

  /// Access the configured Dio client.
  static Dio get instance => _instance.dio;

  final Dio dio;
}
