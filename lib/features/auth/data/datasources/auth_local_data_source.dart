import 'package:shared_preferences/shared_preferences.dart';
import 'package:mwanachuo/core/constants/storage_constants.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'dart:convert';
import 'package:mwanachuo/features/auth/data/models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<UserModel?> getCachedUser();
  Future<void> cacheUser(UserModel user);
  Future<void> clearCache();
  Future<bool> isLoggedIn();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl(this.sharedPreferences);

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final userJson = sharedPreferences.getString('cached_user');
      if (userJson != null) {
        return UserModel.fromJson(json.decode(userJson));
      }
      return null;
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      await sharedPreferences.setString(
        'cached_user',
        json.encode(user.toJson()),
      );
      await sharedPreferences.setBool(StorageConstants.isLoggedInKey, true);
      await sharedPreferences.setString(StorageConstants.userIdKey, user.id);
      await sharedPreferences.setString(StorageConstants.userRoleKey, user.role.value);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await sharedPreferences.remove('cached_user');
      await sharedPreferences.remove(StorageConstants.isLoggedInKey);
      await sharedPreferences.remove(StorageConstants.userIdKey);
      await sharedPreferences.remove(StorageConstants.userRoleKey);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    return sharedPreferences.getBool(StorageConstants.isLoggedInKey) ?? false;
  }
}

