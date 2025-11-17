import 'dart:convert';
import 'package:mwanachuo/core/constants/storage_constants.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/features/profile/data/models/user_profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstract class defining profile local data source operations
abstract class ProfileLocalDataSource {
  /// Cache user profile
  Future<void> cacheMyProfile(UserProfileModel profile);

  /// Get cached user profile
  Future<UserProfileModel> getCachedMyProfile();

  /// Cache other user's profile
  Future<void> cacheUserProfile(String userId, UserProfileModel profile);

  /// Get cached user profile by ID
  Future<UserProfileModel> getCachedUserProfile(String userId);

  /// Check if profile cache is expired
  bool isProfileCacheExpired();

  /// Clear profile cache
  Future<void> clearCache();
}

/// Implementation of ProfileLocalDataSource using SharedPreferences
class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  final SharedPreferences sharedPreferences;

  ProfileLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheMyProfile(UserProfileModel profile) async {
    try {
      await sharedPreferences.setString(
        StorageConstants.myProfileCacheKey,
        json.encode(profile.toJson()),
      );
      
      // Save timestamp
      await sharedPreferences.setInt(
        StorageConstants.profileTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      throw CacheException('Failed to cache profile: $e');
    }
  }

  @override
  Future<UserProfileModel> getCachedMyProfile() async {
    try {
      final jsonString = sharedPreferences.getString(
        StorageConstants.myProfileCacheKey,
      );

      if (jsonString == null) {
        throw CacheException('No cached profile found');
      }

      return UserProfileModel.fromJson(json.decode(jsonString));
    } catch (e) {
      throw CacheException('Failed to get cached profile: $e');
    }
  }

  @override
  Future<void> cacheUserProfile(String userId, UserProfileModel profile) async {
    try {
      await sharedPreferences.setString(
        '${StorageConstants.profileCachePrefix}_$userId',
        json.encode(profile.toJson()),
      );
      
      // Save timestamp
      await sharedPreferences.setInt(
        '${StorageConstants.profileCachePrefix}_${userId}_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      throw CacheException('Failed to cache user profile: $e');
    }
  }

  @override
  Future<UserProfileModel> getCachedUserProfile(String userId) async {
    try {
      final jsonString = sharedPreferences.getString(
        '${StorageConstants.profileCachePrefix}_$userId',
      );

      if (jsonString == null) {
        throw CacheException('No cached user profile found');
      }

      return UserProfileModel.fromJson(json.decode(jsonString));
    } catch (e) {
      throw CacheException('Failed to get cached user profile: $e');
    }
  }

  @override
  bool isProfileCacheExpired() {
    final timestamp = sharedPreferences.getInt(
      StorageConstants.profileTimestampKey,
    );

    if (timestamp == null) return true;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(cacheTime).inMinutes;

    return difference >= StorageConstants.profileCacheExpiration;
  }

  @override
  Future<void> clearCache() async {
    try {
      // Remove my profile cache
      await sharedPreferences.remove(StorageConstants.myProfileCacheKey);
      await sharedPreferences.remove(StorageConstants.profileTimestampKey);
      
      // Remove all user profile caches
      final keys = sharedPreferences.getKeys();
      final profileKeys = keys.where((key) =>
          key.startsWith(StorageConstants.profileCachePrefix));
      
      for (final key in profileKeys) {
        await sharedPreferences.remove(key);
      }
    } catch (e) {
      throw CacheException('Failed to clear cache: $e');
    }
  }
}

