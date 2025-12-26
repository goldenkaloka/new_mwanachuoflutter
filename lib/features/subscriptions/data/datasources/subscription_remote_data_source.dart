import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mwanachuo/core/constants/database_constants.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/features/subscriptions/data/models/subscription_plan_model.dart';
import 'package:mwanachuo/features/subscriptions/data/models/seller_subscription_model.dart';
import 'package:mwanachuo/features/subscriptions/data/models/subscription_payment_model.dart';

abstract class SubscriptionRemoteDataSource {
  Future<List<SubscriptionPlanModel>> getSubscriptionPlans();
  Future<SellerSubscriptionModel?> getSellerSubscription(String sellerId);
  Future<bool> canCreateListing({
    required String sellerId,
    required String listingType,
  });
  Future<SellerSubscriptionModel> createSubscription({
    required String sellerId,
    required String planId,
    required String billingPeriod,
    required String stripeCheckoutSessionId,
  });
  Future<void> cancelSubscription(String subscriptionId);
  Future<SellerSubscriptionModel> updateSubscription({
    required String subscriptionId,
    String? billingPeriod,
    bool? autoRenew,
  });
  Future<List<SubscriptionPaymentModel>> getPaymentHistory(
    String subscriptionId,
  );
  Future<Map<String, dynamic>> createCheckoutSession({
    required String sellerId,
    required String planId,
    required String billingPeriod,
  });
}

class SubscriptionRemoteDataSourceImpl implements SubscriptionRemoteDataSource {
  final SupabaseClient supabaseClient;

  SubscriptionRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<List<SubscriptionPlanModel>> getSubscriptionPlans() async {
    try {
      final response = await supabaseClient
          .from(DatabaseConstants.subscriptionPlansTable)
          .select()
          .eq('is_active', true)
          .order('created_at');

      return (response as List)
          .map((json) => SubscriptionPlanModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(
        'Failed to fetch subscription plans: ${e.toString()}',
      );
    }
  }

  @override
  Future<SellerSubscriptionModel?> getSellerSubscription(
    String sellerId,
  ) async {
    try {
      final response = await supabaseClient
          .from(DatabaseConstants.sellerSubscriptionsTable)
          .select()
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return SellerSubscriptionModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        // No rows returned
        return null;
      }
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(
        'Failed to fetch seller subscription: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> canCreateListing({
    required String sellerId,
    required String listingType,
  }) async {
    try {
      final response = await supabaseClient.rpc(
        'can_create_listing',
        params: {'p_user_id': sellerId, 'p_listing_type': listingType},
      );

      if (response == null) {
        return false;
      }

      // Response is a list with one row containing can_create and reason
      if (response is List && response.isNotEmpty) {
        final result = response[0] as Map<String, dynamic>;
        return result['can_create'] as bool? ?? false;
      }

      return false;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(
        'Failed to check subscription status: ${e.toString()}',
      );
    }
  }

  @override
  Future<SellerSubscriptionModel> createSubscription({
    required String sellerId,
    required String planId,
    required String billingPeriod,
    required String stripeCheckoutSessionId,
  }) async {
    try {
      // This will be handled by Stripe webhook after payment
      // For now, we'll create a placeholder that will be updated by webhook
      final response = await supabaseClient
          .from(DatabaseConstants.sellerSubscriptionsTable)
          .insert({
            'seller_id': sellerId,
            'plan_id': planId,
            'status': 'active',
            'billing_period': billingPeriod,
            'current_period_start': DateTime.now().toIso8601String(),
            'current_period_end': billingPeriod == 'monthly'
                ? DateTime.now().add(const Duration(days: 30)).toIso8601String()
                : DateTime.now()
                      .add(const Duration(days: 365))
                      .toIso8601String(),
            'grace_period_end': billingPeriod == 'monthly'
                ? DateTime.now().add(const Duration(days: 37)).toIso8601String()
                : DateTime.now()
                      .add(const Duration(days: 372))
                      .toIso8601String(),
            'is_trial': false,
            'auto_renew': true,
          })
          .select()
          .single();

      return SellerSubscriptionModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to create subscription: ${e.toString()}');
    }
  }

  @override
  Future<void> cancelSubscription(String subscriptionId) async {
    try {
      await supabaseClient
          .from(DatabaseConstants.sellerSubscriptionsTable)
          .update({
            'status': 'cancelled',
            'auto_renew': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', subscriptionId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to cancel subscription: ${e.toString()}');
    }
  }

  @override
  Future<SellerSubscriptionModel> updateSubscription({
    required String subscriptionId,
    String? billingPeriod,
    bool? autoRenew,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (billingPeriod != null) {
        updateData['billing_period'] = billingPeriod;
      }

      if (autoRenew != null) {
        updateData['auto_renew'] = autoRenew;
      }

      final response = await supabaseClient
          .from(DatabaseConstants.sellerSubscriptionsTable)
          .update(updateData)
          .eq('id', subscriptionId)
          .select()
          .single();

      return SellerSubscriptionModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to update subscription: ${e.toString()}');
    }
  }

  @override
  Future<List<SubscriptionPaymentModel>> getPaymentHistory(
    String subscriptionId,
  ) async {
    try {
      final response = await supabaseClient
          .from(DatabaseConstants.subscriptionPaymentsTable)
          .select()
          .eq('subscription_id', subscriptionId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => SubscriptionPaymentModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to fetch payment history: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> createCheckoutSession({
    required String sellerId,
    required String planId,
    required String billingPeriod,
  }) async {
    try {
      // Call Supabase Edge Function to create Stripe payment intent
      // The function name 'create-subscription-checkout' is kept for backwards compatibility
      // but the implementation should now return payment_intent, ephemeral_key, and customer
      final response = await supabaseClient.functions.invoke(
        'create-subscription-checkout',
        body: {
          'seller_id': sellerId,
          'plan_id': planId,
          'billing_period': billingPeriod,
          'use_payment_sheet':
              true, // Tell edge function to return payment intent data
        },
      );

      // Debug logging to inspect backend response
      debugPrint('Stripe Checkout Response: ${response.data}');

      if (response.data != null && response.data['paymentIntent'] != null) {
        return Map<String, dynamic>.from(response.data);
      }

      // Fallback for old checkout URL if the edge function wasn't updated yet
      if (response.data != null && response.data['checkout_url'] != null) {
        return {'checkout_url': response.data['checkout_url']};
      }

      // Handle error response from Edge Function
      if (response.data != null && response.data['error'] != null) {
        throw ServerException(
          response.data['message'] as String? ??
              response.data['error'] as String? ??
              'Failed to create checkout session',
        );
      }

      throw ServerException(
        'Failed to create checkout session: No payment data returned',
      );
    } on PostgrestException catch (e) {
      throw ServerException('Failed to create checkout session: ${e.message}');
    } catch (e) {
      throw ServerException(
        'Failed to create checkout session: ${e.toString()}',
      );
    }
  }
}
