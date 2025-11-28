import '../../../../core/config/app_config.dart';
import '../../../../core/network/mock_api_service.dart';
import '../../../../core/network/network_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String username, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._client, this._config, this._mockApiService);

  final NetworkClient _client;
  final AppConfig _config;
  final MockApiService _mockApiService;

  @override
  Future<UserModel> login(String username, String password) async {
    if (_config.useMockData) {
      final user = await _mockApiService.login(username, password);
      return UserModel(
        id: user.id,
        name: user.name,
        employeeCode: user.employeeCode,
        department: user.department,
        designation: user.designation,
        location: user.location,
        cardNumber: user.cardNumber,
      );
    }

    final response = await _client.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'username': username, 'password': password},
    );
    return UserModel.fromJson(response.data!);
  }
}

