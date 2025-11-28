import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../errors/app_exception.dart';

class NetworkClient {
  NetworkClient(this._config)
      : _dio = Dio(
          BaseOptions(
            baseUrl: _config.baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
          ),
        );

  final AppConfig _config;
  final Dio _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get<T>(path, queryParameters: queryParameters);
    } on DioException catch (error) {
      throw NetworkException(error.message ?? 'Network error');
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
  }) async {
    try {
      return await _dio.post<T>(path, data: data);
    } on DioException catch (error) {
      throw NetworkException(error.message ?? 'Network error');
    }
  }

  AppConfig get config => _config;
}

