import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/core/services/subscription_cache_service.dart';
import 'package:mwanachuo/features/subscriptions/domain/usecases/check_subscription_status.dart';

/// Middleware to check if a seller can perform an action (e.g., create listing)
class SubscriptionMiddleware {
  static final CheckSubscriptionStatus _checkSubscriptionStatus =
      sl<CheckSubscriptionStatus>();
  static final SubscriptionCacheService _cacheService =
      SubscriptionCacheService();

  /// Check if seller can create a listing
  /// Returns true if allowed, false otherwise
  /// Throws exception with reason if not allowed
  static Future<bool> canCreateListing({
    required String sellerId,
    required String listingType, // 'product', 'service', or 'accommodation'
  }) async {
    final result = await _checkSubscriptionStatus(
      CheckSubscriptionStatusParams(
        sellerId: sellerId,
        listingType: listingType,
      ),
    );

    return result.fold((failure) {
      throw Exception(failure.message);
    }, (canCreate) => canCreate);
  }

  /// Check if seller can access messages
  /// Returns true if allowed (active subscription or in grace period), false otherwise
  /// Returns true on error (fail open) to avoid blocking users unnecessarily
  /// Uses caching to avoid repeated checks
  static Future<bool> canAccessMessages({
    required String sellerId,
    bool useCache = true,
  }) async {
    // Check cache first
    if (useCache) {
      final cached = _cacheService.getCachedAccess(sellerId);
      if (cached != null) {
        return cached;
      }

      // Try persisted cache
      final persisted = await _cacheService.getPersistedAccess(sellerId);
      if (persisted != null) {
        // Restore to memory cache
        await _cacheService.cacheAccess(sellerId, persisted);
        return persisted;
      }
    }

    // Cache miss - check subscription
    try {
      final result = await _checkSubscriptionStatus(
        CheckSubscriptionStatusParams(
          sellerId: sellerId,
          listingType: 'product', // We just need to check subscription status
        ),
      );

      final canAccess = result.fold(
        (failure) => true, // Fail open - allow access on error
        (canCreate) =>
            canCreate, // Use same logic as listing creation (includes grace period)
      );

      // Cache the result
      await _cacheService.cacheAccess(sellerId, canAccess);

      return canAccess;
    } catch (e) {
      // Fail open - allow access on exception
      // Cache the fail-open result
      await _cacheService.cacheAccess(sellerId, true);
      return true;
    }
  }

  /// Clear subscription cache (call after subscription updates)
  static Future<void> clearCache(String sellerId) async {
    await _cacheService.clearCache(sellerId);
  }
}
