import 'dart:convert';
import 'package:mwanachuo/core/constants/storage_constants.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/features/services/data/models/service_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ServiceLocalDataSource {
  Future<void> cacheServices(List<ServiceModel> services);
  Future<List<ServiceModel>> getCachedServices();
  Future<void> cacheService(ServiceModel service);
  Future<ServiceModel> getCachedService(String serviceId);
  Future<void> clearCache();
}

class ServiceLocalDataSourceImpl implements ServiceLocalDataSource {
  final SharedPreferences sharedPreferences;

  ServiceLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheServices(List<ServiceModel> services) async {
    try {
      final jsonList = services.map((s) => s.toJson()).toList();
      await sharedPreferences.setString(
        StorageConstants.servicesCacheKey,
        json.encode(jsonList),
      );
    } catch (e) {
      throw CacheException('Failed to cache services: $e');
    }
  }

  @override
  Future<List<ServiceModel>> getCachedServices() async {
    try {
      final jsonString = sharedPreferences.getString(
        StorageConstants.servicesCacheKey,
      );
      if (jsonString == null) throw CacheException('No cached services found');

      final jsonList = json.decode(jsonString) as List;
      return jsonList.map((json) => ServiceModel.fromJson(json)).toList();
    } catch (e) {
      throw CacheException('Failed to get cached services: $e');
    }
  }

  @override
  Future<void> cacheService(ServiceModel service) async {
    try {
      await sharedPreferences.setString(
        '${StorageConstants.serviceCachePrefix}_${service.id}',
        json.encode(service.toJson()),
      );
    } catch (e) {
      throw CacheException('Failed to cache service: $e');
    }
  }

  @override
  Future<ServiceModel> getCachedService(String serviceId) async {
    try {
      final jsonString = sharedPreferences.getString(
        '${StorageConstants.serviceCachePrefix}_$serviceId',
      );
      if (jsonString == null) throw CacheException('No cached service found');

      return ServiceModel.fromJson(json.decode(jsonString));
    } catch (e) {
      throw CacheException('Failed to get cached service: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await sharedPreferences.remove(StorageConstants.servicesCacheKey);
      final keys = sharedPreferences.getKeys();
      final serviceKeys = keys.where((key) =>
          key.startsWith(StorageConstants.serviceCachePrefix));
      for (final key in serviceKeys) {
        await sharedPreferences.remove(key);
      }
    } catch (e) {
      throw CacheException('Failed to clear cache: $e');
    }
  }
}

