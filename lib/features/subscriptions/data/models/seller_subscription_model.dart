import 'package:mwanachuo/features/subscriptions/domain/entities/seller_subscription_entity.dart';

class SellerSubscriptionModel extends SellerSubscriptionEntity {
  const SellerSubscriptionModel({
    required super.id,
    required super.sellerId,
    required super.planId,
    required super.status,
    required super.billingPeriod,
    required super.currentPeriodStart,
    required super.currentPeriodEnd,
    super.gracePeriodEnd,
    required super.isTrial,
    super.trialEndsAt,
    super.stripeSubscriptionId,
    super.stripeCustomerId,
    required super.autoRenew,
    required super.createdAt,
    super.updatedAt,
  });

  factory SellerSubscriptionModel.fromJson(Map<String, dynamic> json) {
    SubscriptionStatus status;
    final statusStr = json['status'] as String;
    switch (statusStr) {
      case 'trial':
        status = SubscriptionStatus.trial;
        break;
      case 'active':
        status = SubscriptionStatus.active;
        break;
      case 'expired':
        status = SubscriptionStatus.expired;
        break;
      case 'cancelled':
        status = SubscriptionStatus.cancelled;
        break;
      case 'past_due':
        status = SubscriptionStatus.pastDue;
        break;
      default:
        status = SubscriptionStatus.expired;
    }

    BillingPeriod billingPeriod;
    final billingPeriodStr = json['billing_period'] as String;
    switch (billingPeriodStr) {
      case 'monthly':
        billingPeriod = BillingPeriod.monthly;
        break;
      case 'yearly':
        billingPeriod = BillingPeriod.yearly;
        break;
      case 'trial':
        billingPeriod = BillingPeriod.trial;
        break;
      default:
        billingPeriod = BillingPeriod.monthly;
    }

    return SellerSubscriptionModel(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      planId: json['plan_id'] as String,
      status: status,
      billingPeriod: billingPeriod,
      currentPeriodStart: DateTime.parse(json['current_period_start'] as String),
      currentPeriodEnd: DateTime.parse(json['current_period_end'] as String),
      gracePeriodEnd: json['grace_period_end'] != null
          ? DateTime.parse(json['grace_period_end'] as String)
          : null,
      isTrial: json['is_trial'] as bool? ?? false,
      trialEndsAt: json['trial_ends_at'] != null
          ? DateTime.parse(json['trial_ends_at'] as String)
          : null,
      stripeSubscriptionId: json['stripe_subscription_id'] as String?,
      stripeCustomerId: json['stripe_customer_id'] as String?,
      autoRenew: json['auto_renew'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    String statusStr;
    switch (status) {
      case SubscriptionStatus.trial:
        statusStr = 'trial';
        break;
      case SubscriptionStatus.active:
        statusStr = 'active';
        break;
      case SubscriptionStatus.expired:
        statusStr = 'expired';
        break;
      case SubscriptionStatus.cancelled:
        statusStr = 'cancelled';
        break;
      case SubscriptionStatus.pastDue:
        statusStr = 'past_due';
        break;
    }

    String billingPeriodStr;
    switch (billingPeriod) {
      case BillingPeriod.monthly:
        billingPeriodStr = 'monthly';
        break;
      case BillingPeriod.yearly:
        billingPeriodStr = 'yearly';
        break;
      case BillingPeriod.trial:
        billingPeriodStr = 'trial';
        break;
    }

    return {
      'id': id,
      'seller_id': sellerId,
      'plan_id': planId,
      'status': statusStr,
      'billing_period': billingPeriodStr,
      'current_period_start': currentPeriodStart.toIso8601String(),
      'current_period_end': currentPeriodEnd.toIso8601String(),
      'grace_period_end': gracePeriodEnd?.toIso8601String(),
      'is_trial': isTrial,
      'trial_ends_at': trialEndsAt?.toIso8601String(),
      'stripe_subscription_id': stripeSubscriptionId,
      'stripe_customer_id': stripeCustomerId,
      'auto_renew': autoRenew,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

