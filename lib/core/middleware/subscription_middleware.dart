import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/features/subscriptions/domain/usecases/check_subscription_status.dart';

/// Middleware to check if a seller can perform an action (e.g., create listing)
class SubscriptionMiddleware {
  static final CheckSubscriptionStatus _checkSubscriptionStatus =
      sl<CheckSubscriptionStatus>();

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

    return result.fold(
      (failure) {
        throw Exception(failure.message);
      },
      (canCreate) => canCreate,
    );
  }

  /// Check if seller can access messages
  /// Returns true if allowed (active subscription or in grace period), false otherwise
  /// Returns true on error (fail open) to avoid blocking users unnecessarily
  static Future<bool> canAccessMessages({
    required String sellerId,
  }) async {
    try {
      final result = await _checkSubscriptionStatus(
        CheckSubscriptionStatusParams(
          sellerId: sellerId,
          listingType: 'product', // We just need to check subscription status
        ),
      );

      return result.fold(
        (failure) => true, // Fail open - allow access on error
        (canCreate) => canCreate, // Use same logic as listing creation (includes grace period)
      );
    } catch (e) {
      // Fail open - allow access on exception
      return true;
    }
  }
}

