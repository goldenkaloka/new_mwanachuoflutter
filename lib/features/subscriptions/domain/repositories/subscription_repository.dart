import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/subscriptions/domain/entities/subscription_plan_entity.dart';
import 'package:mwanachuo/features/subscriptions/domain/entities/seller_subscription_entity.dart';
import 'package:mwanachuo/features/subscriptions/domain/entities/subscription_payment_entity.dart';

abstract class SubscriptionRepository {
  /// Get all active subscription plans
  Future<Either<Failure, List<SubscriptionPlanEntity>>> getSubscriptionPlans();

  /// Get seller's current subscription
  Future<Either<Failure, SellerSubscriptionEntity?>> getSellerSubscription(
    String sellerId,
  );

  /// Check if seller can create a listing
  Future<Either<Failure, bool>> canCreateListing({
    required String sellerId,
    required String listingType,
  });

  /// Create a new subscription (after payment)
  Future<Either<Failure, SellerSubscriptionEntity>> createSubscription({
    required String sellerId,
    required String planId,
    required String billingPeriod, // 'monthly' or 'yearly'
    required String stripeCheckoutSessionId,
  });

  /// Cancel a subscription
  Future<Either<Failure, void>> cancelSubscription(String subscriptionId);

  /// Update subscription (e.g., change billing period)
  Future<Either<Failure, SellerSubscriptionEntity>> updateSubscription({
    required String subscriptionId,
    String? billingPeriod,
    bool? autoRenew,
  });

  /// Get payment history for a subscription
  Future<Either<Failure, List<SubscriptionPaymentEntity>>> getPaymentHistory(
    String subscriptionId,
  );

  /// Create Stripe checkout session or Payment Intent
  Future<Either<Failure, Map<String, dynamic>>> createCheckoutSession({
    required String sellerId,
    required String planId,
    required String billingPeriod,
  });
}
