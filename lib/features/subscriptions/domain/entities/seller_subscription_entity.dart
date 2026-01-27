import 'package:equatable/equatable.dart';

enum SubscriptionStatus {
  trial,
  active,
  expired,
  cancelled,
  pastDue,
}

enum BillingPeriod {
  monthly,
  yearly,
  trial,
}

class SellerSubscriptionEntity extends Equatable {
  final String id;
  final String sellerId;
  final String planId;
  final SubscriptionStatus status;
  final BillingPeriod billingPeriod;
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final DateTime? gracePeriodEnd;
  final bool isTrial;
  final DateTime? trialEndsAt;

  final bool autoRenew;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SellerSubscriptionEntity({
    required this.id,
    required this.sellerId,
    required this.planId,
    required this.status,
    required this.billingPeriod,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    this.gracePeriodEnd,
    required this.isTrial,
    this.trialEndsAt,

    required this.autoRenew,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isActive {
    if (status == SubscriptionStatus.trial || status == SubscriptionStatus.active) {
      return true;
    }
    if (status == SubscriptionStatus.expired && gracePeriodEnd != null) {
      return DateTime.now().isBefore(gracePeriodEnd!);
    }
    return false;
  }

  int get daysRemaining {
    if (isTrial && trialEndsAt != null) {
      final remaining = trialEndsAt!.difference(DateTime.now()).inDays;
      return remaining > 0 ? remaining : 0;
    }
    final remaining = currentPeriodEnd.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  @override
  List<Object?> get props => [
        id,
        sellerId,
        planId,
        status,
        billingPeriod,
        currentPeriodStart,
        currentPeriodEnd,
        gracePeriodEnd,
        isTrial,
        trialEndsAt,

        autoRenew,
        createdAt,
        updatedAt,
      ];
}

