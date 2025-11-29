import 'package:shared_preferences/shared_preferences.dart';
import 'package:mwanachuo/core/constants/storage_constants.dart';

/// Service to cache subscription access status to avoid repeated checks
class SubscriptionCacheService {
  static final SubscriptionCacheService _instance =
      SubscriptionCacheService._internal();
  factory SubscriptionCacheService() => _instance;
  SubscriptionCacheService._internal();

  // In-memory cache
  final Map<String, _CachedAccess> _memoryCache = {};
  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  /// Get cached access status for a seller
  bool? getCachedAccess(String sellerId) {
    final cached = _memoryCache[sellerId];
    if (cached == null) return null;

    // Check if cache is still valid
    if (DateTime.now().difference(cached.cachedAt) > _cacheValidityDuration) {
      _memoryCache.remove(sellerId);
      return null;
    }

    return cached.canAccess;
  }

  /// Cache access status for a seller
  Future<void> cacheAccess(String sellerId, bool canAccess) async {
    _memoryCache[sellerId] = _CachedAccess(
      canAccess: canAccess,
      cachedAt: DateTime.now(),
    );

    // Also persist to SharedPreferences for app restarts
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        '${StorageConstants.subscriptionAccessKey}_$sellerId',
        canAccess,
      );
      await prefs.setInt(
        '${StorageConstants.subscriptionAccessTimestampKey}_$sellerId',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      // Ignore cache errors
    }
  }

  /// Get persisted access status (for app restarts)
  Future<bool?> getPersistedAccess(String sellerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final canAccess = prefs.getBool(
        '${StorageConstants.subscriptionAccessKey}_$sellerId',
      );
      final timestamp = prefs.getInt(
        '${StorageConstants.subscriptionAccessTimestampKey}_$sellerId',
      );

      if (canAccess == null || timestamp == null) return null;

      final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cachedAt) > _cacheValidityDuration) {
        // Cache expired, remove it
        await prefs.remove(
          '${StorageConstants.subscriptionAccessKey}_$sellerId',
        );
        await prefs.remove(
          '${StorageConstants.subscriptionAccessTimestampKey}_$sellerId',
        );
        return null;
      }

      return canAccess;
    } catch (e) {
      return null;
    }
  }

  /// Clear cache for a seller (e.g., after subscription update)
  Future<void> clearCache(String sellerId) async {
    _memoryCache.remove(sellerId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${StorageConstants.subscriptionAccessKey}_$sellerId');
      await prefs.remove(
        '${StorageConstants.subscriptionAccessTimestampKey}_$sellerId',
      );
    } catch (e) {
      // Ignore errors
    }
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    _memoryCache.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(StorageConstants.subscriptionAccessKey) ||
            key.startsWith(StorageConstants.subscriptionAccessTimestampKey)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      // Ignore errors
    }
  }
}

class _CachedAccess {
  final bool canAccess;
  final DateTime cachedAt;

  _CachedAccess({required this.canAccess, required this.cachedAt});
}
