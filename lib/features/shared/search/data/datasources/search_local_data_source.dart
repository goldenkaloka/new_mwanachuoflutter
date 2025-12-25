import 'dart:convert';
import 'package:mwanachuo/core/constants/storage_constants.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/features/shared/search/data/models/search_result_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstract class defining search local data source operations
abstract class SearchLocalDataSource {
  /// Get recent searches
  Future<List<String>> getRecentSearches({int? limit});

  /// Save search query
  Future<void> saveSearchQuery(String query);

  /// Clear search history
  Future<void> clearSearchHistory();

  /// Cache search results
  Future<void> cacheSearchResults(List<SearchResultModel> results);

  /// Get cached search results
  Future<List<SearchResultModel>> getCachedSearchResults();
}

/// Implementation of SearchLocalDataSource using SharedPreferences
class SearchLocalDataSourceImpl implements SearchLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const int maxRecentSearches = 20;

  SearchLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<String>> getRecentSearches({int? limit}) async {
    try {
      final jsonString = sharedPreferences.getString(
        StorageConstants.searchHistoryKey,
      );

      if (jsonString == null) {
        return [];
      }

      final searches = List<String>.from(json.decode(jsonString) as List);
      return searches.take(limit ?? maxRecentSearches).toList();
    } catch (e) {
      throw CacheException('Failed to get recent searches: $e');
    }
  }

  @override
  Future<void> saveSearchQuery(String query) async {
    try {
      final searches = await getRecentSearches();

      // Remove duplicate if exists
      searches.remove(query);

      // Add to beginning
      searches.insert(0, query);

      // Keep only the most recent ones
      final limitedSearches = searches.take(maxRecentSearches).toList();

      await sharedPreferences.setString(
        StorageConstants.searchHistoryKey,
        json.encode(limitedSearches),
      );
    } catch (e) {
      throw CacheException('Failed to save search query: $e');
    }
  }

  @override
  Future<void> clearSearchHistory() async {
    try {
      await sharedPreferences.remove(StorageConstants.searchHistoryKey);
    } catch (e) {
      throw CacheException('Failed to clear search history: $e');
    }
  }

  @override
  Future<void> cacheSearchResults(List<SearchResultModel> results) async {
    try {
      final jsonList = results.map((r) => r.toJson()).toList();
      await sharedPreferences.setString(
        StorageConstants.searchResultsCacheKey,
        json.encode(jsonList),
      );
    } catch (e) {
      throw CacheException('Failed to cache search results: $e');
    }
  }

  @override
  Future<List<SearchResultModel>> getCachedSearchResults() async {
    try {
      final jsonString = sharedPreferences.getString(
        StorageConstants.searchResultsCacheKey,
      );

      if (jsonString == null) {
        return [];
      }

      final jsonList = json.decode(jsonString) as List;
      return jsonList
          .map((json) => SearchResultModel.fromCacheJson(json))
          .toList();
    } catch (e) {
      throw CacheException('Failed to get cached search results: $e');
    }
  }
}
