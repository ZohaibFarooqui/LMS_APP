import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../models/enhanced_profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<EnhancedProfileModel> fetchProfile(String empPk);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  ProfileRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  @override
  Future<EnhancedProfileModel> fetchProfile(String empPk) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/employee/profile',
      queryParameters: {'emp_pk': empPk},
    );
    final body = response.data?['body'] as Map<String, dynamic>? ?? {};
    return EnhancedProfileModel.fromJson(body);
  }
}
