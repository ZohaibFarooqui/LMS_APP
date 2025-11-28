import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clear();
  Future<void> setRememberMe(bool value, {String? username});
  Future<String?> rememberedUsername();
  Future<void> setBiometricEnabled(bool enabled);
  Future<bool> isBiometricEnabled();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl(this._storage, this._secureStorage);

  static const _userKey = 'auth_user';
  static const _rememberKey = 'remember_me';
  static const _rememberedUsernameKey = 'remembered_username';
  static const _biometricKey = 'biometric_enabled';

  final LocalStorageService _storage;
  final SecureStorageService _secureStorage;

  @override
  Future<void> cacheUser(UserModel user) async {
    await _storage.writeJson(_userKey, user.toJson());
    await _secureStorage.write('token', 'mock-jwt-token');
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final data = _storage.readJson(_userKey);
    if (data == null) return null;
    return UserModel.fromJson(data);
  }

  @override
  Future<void> clear() async {
    await _storage.remove(_userKey);
    await _secureStorage.delete('token');
  }

  @override
  Future<void> setRememberMe(bool value, {String? username}) async {
    await _storage.writeString(_rememberKey, value.toString());
    if (username != null) {
      await _storage.writeString(_rememberedUsernameKey, username);
    }
  }

  @override
  Future<String?> rememberedUsername() async {
    return _storage.readString(_rememberedUsernameKey);
  }

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.writeString(_biometricKey, enabled.toString());
  }

  @override
  Future<bool> isBiometricEnabled() async {
    final value = _storage.readString(_biometricKey);
    return value == 'true';
  }
}

