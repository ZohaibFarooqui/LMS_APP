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

  static const String _baseUrl =
      'http://lms.yousufdewan.com:8080/ords/ws_tms/empdata';

  static final DioClient _instance = DioClient._();

  /// Access the configured Dio client.
  static Dio get instance => _instance.dio;

  final Dio dio;
}
