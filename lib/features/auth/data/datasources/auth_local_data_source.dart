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
  Future<bool> isRegistrationCompleted();
  Future<void> setRegistrationCompleted(bool completed);
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
      await sharedPreferences.setString(
        StorageConstants.userRoleKey,
        user.role.value,
      );
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      // Clear auth cache
      await sharedPreferences.remove('cached_user');
      await sharedPreferences.remove(StorageConstants.isLoggedInKey);
      await sharedPreferences.remove(StorageConstants.userIdKey);
      await sharedPreferences.remove(StorageConstants.userRoleKey);

      // Clear profile cache to prevent showing previous user's data
      await sharedPreferences.remove(StorageConstants.myProfileCacheKey);
      await sharedPreferences.remove(StorageConstants.profileTimestampKey);

      // Clear all user profile caches
      final keys = sharedPreferences.getKeys();
      final profileKeys = keys.where(
        (key) => key.startsWith(StorageConstants.profileCachePrefix),
      );

      for (final key in profileKeys) {
        await sharedPreferences.remove(key);
      }
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    return sharedPreferences.getBool(StorageConstants.isLoggedInKey) ?? false;
  }

  @override
  Future<bool> isRegistrationCompleted() async {
    return sharedPreferences.getBool(
          StorageConstants.registrationCompletedKey,
        ) ??
        false;
  }

  @override
  Future<void> setRegistrationCompleted(bool completed) async {
    await sharedPreferences.setBool(
      StorageConstants.registrationCompletedKey,
      completed,
    );
  }
}
