import 'dart:convert';
import 'package:mwanachuo/core/constants/storage_constants.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/features/shared/university/data/models/university_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstract class defining university local data source operations
abstract class UniversityLocalDataSource {
  /// Get cached universities
  Future<List<UniversityModel>> getCachedUniversities();

  /// Cache universities
  Future<void> cacheUniversities(List<UniversityModel> universities);

  /// Get selected university ID
  Future<String?> getSelectedUniversityId();

  /// Save selected university ID
  Future<void> saveSelectedUniversityId(String universityId);

  /// Clear selected university
  Future<void> clearSelectedUniversityId();

  /// Get cached university by ID
  Future<UniversityModel?> getCachedUniversityById(String id);
}

/// Implementation of UniversityLocalDataSource using SharedPreferences
class UniversityLocalDataSourceImpl implements UniversityLocalDataSource {
  final SharedPreferences sharedPreferences;

  UniversityLocalDataSourceImpl({required this.sharedPreferences});

  static const _universitiesCacheKey = StorageConstants.universitiesCacheKey;
  static const _selectedUniversityKey = StorageConstants.selectedUniversityKey;

  @override
  Future<List<UniversityModel>> getCachedUniversities() async {
    try {
      final jsonString = sharedPreferences.getString(_universitiesCacheKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList.map((json) => UniversityModel.fromJson(json)).toList();
      }
      throw CacheException('No cached universities found');
    } catch (e) {
      throw CacheException('Failed to get cached universities: $e');
    }
  }

  @override
  Future<void> cacheUniversities(List<UniversityModel> universities) async {
    try {
      final jsonList = universities.map((u) => u.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await sharedPreferences.setString(_universitiesCacheKey, jsonString);
    } catch (e) {
      throw CacheException('Failed to cache universities: $e');
    }
  }

  @override
  Future<String?> getSelectedUniversityId() async {
    try {
      return sharedPreferences.getString(_selectedUniversityKey);
    } catch (e) {
      throw CacheException('Failed to get selected university ID: $e');
    }
  }

  @override
  Future<void> saveSelectedUniversityId(String universityId) async {
    try {
      await sharedPreferences.setString(_selectedUniversityKey, universityId);
    } catch (e) {
      throw CacheException('Failed to save selected university ID: $e');
    }
  }

  @override
  Future<void> clearSelectedUniversityId() async {
    try {
      await sharedPreferences.remove(_selectedUniversityKey);
    } catch (e) {
      throw CacheException('Failed to clear selected university ID: $e');
    }
  }

  @override
  Future<UniversityModel?> getCachedUniversityById(String id) async {
    try {
      final universities = await getCachedUniversities();
      return universities.firstWhere(
        (u) => u.id == id,
        orElse: () => throw CacheException('University not found in cache'),
      );
    } catch (e) {
      return null;
    }
  }
}


