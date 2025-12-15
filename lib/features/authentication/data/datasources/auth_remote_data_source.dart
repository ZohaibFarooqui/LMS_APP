import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String username, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  @override
  Future<UserModel> login(String username, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/login',
      data: {'phoneNumber': username, 'passcode': password},
    );

    final body = response.data?['body'] as Map<String, dynamic>? ?? {};
    final empPk = body['emp_pk']?.toString() ?? '';

    return UserModel(
      id: empPk,
      name: '',
      employeeCode: '',
      department: '',
      designation: '',
      location: '',
      cardNumber: '',
    );
  }
}
