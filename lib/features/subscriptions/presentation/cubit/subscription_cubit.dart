import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/subscriptions/domain/usecases/cancel_subscription.dart';
import 'package:mwanachuo/features/subscriptions/domain/usecases/check_subscription_status.dart';

import 'package:mwanachuo/features/subscriptions/domain/usecases/create_subscription.dart';
import 'package:mwanachuo/features/subscriptions/domain/usecases/get_payment_history.dart';
import 'package:mwanachuo/features/subscriptions/domain/usecases/get_seller_subscription.dart';
import 'package:mwanachuo/features/subscriptions/domain/usecases/get_subscription_plans.dart';
import 'package:mwanachuo/features/subscriptions/domain/usecases/update_subscription.dart';
import 'package:mwanachuo/features/subscriptions/presentation/cubit/subscription_state.dart';

class SubscriptionCubit extends Cubit<SubscriptionState> {
  final GetSubscriptionPlans getSubscriptionPlans;
  final GetSellerSubscription getSellerSubscription;
  final CheckSubscriptionStatus checkSubscriptionStatus;
  final CreateSubscription createSubscription;
  final CancelSubscription cancelSubscription;
  final UpdateSubscription updateSubscription;
  final GetPaymentHistory getPaymentHistory;


  SubscriptionCubit({
    required this.getSubscriptionPlans,
    required this.getSellerSubscription,
    required this.checkSubscriptionStatus,
    required this.createSubscription,
    required this.cancelSubscription,
    required this.updateSubscription,
    required this.getPaymentHistory,

  }) : super(SubscriptionInitial());

  /// Load subscription plans
  Future<void> loadSubscriptionPlans() async {
    emit(SubscriptionLoading());
    final result = await getSubscriptionPlans(NoParams());
    result.fold(
      (failure) => emit(SubscriptionError(failure.message)),
      (plans) => emit(SubscriptionPlansLoaded(plans)),
    );
  }

  /// Load seller's current subscription
  Future<void> loadSellerSubscription(String sellerId) async {
    emit(SubscriptionLoading());
    final result = await getSellerSubscription(sellerId);
    result.fold((failure) => emit(SubscriptionError(failure.message)), (
      subscription,
    ) {
      if (subscription == null) {
        emit(const SubscriptionLoaded(null));
      } else if (subscription.isTrial) {
        emit(SubscriptionTrial(subscription));
      } else if (!subscription.isActive) {
        final inGracePeriod =
            subscription.gracePeriodEnd != null &&
            DateTime.now().isBefore(subscription.gracePeriodEnd!);
        emit(
          SubscriptionExpired(
            subscription: subscription,
            inGracePeriod: inGracePeriod,
          ),
        );
      } else {
        emit(SubscriptionLoaded(subscription));
      }
    });
  }

  /// Check if seller can create listing
  Future<bool> canCreateListing({
    required String sellerId,
    required String listingType,
  }) async {
    final result = await checkSubscriptionStatus(
      CheckSubscriptionStatusParams(
        sellerId: sellerId,
        listingType: listingType,
      ),
    );
    return result.fold((failure) => false, (canCreate) => canCreate);
  }



  /// Create subscription (after payment)
  Future<void> subscribe({
    required String sellerId,
    required String planId,
    required String billingPeriod,
    required String sellerId,
    required String planId,
    required String billingPeriod,
  }) async {
    emit(SubscriptionLoading());
    final result = await createSubscription(
      CreateSubscriptionParams(
        sellerId: sellerId,
        planId: planId,
        billingPeriod: billingPeriod,
        billingPeriod: billingPeriod,
      ),
    );
    result.fold(
      (failure) => emit(SubscriptionError(failure.message)),
      (subscription) => emit(SubscriptionLoaded(subscription)),
    );
  }

  /// Cancel subscription
  Future<void> cancel(String subscriptionId) async {
    emit(SubscriptionLoading());
    final result = await cancelSubscription(subscriptionId);
    result.fold((failure) => emit(SubscriptionError(failure.message)), (_) {
      // Reload subscription to reflect cancellation
      if (state is SubscriptionLoaded) {
        final currentSubscription = (state as SubscriptionLoaded).subscription;
        if (currentSubscription != null) {
          loadSellerSubscription(currentSubscription.sellerId);
        }
      }
    });
  }

  /// Update subscription
  Future<void> update({
    required String subscriptionId,
    String? billingPeriod,
    bool? autoRenew,
  }) async {
    emit(SubscriptionLoading());
    final result = await updateSubscription(
      UpdateSubscriptionParams(
        subscriptionId: subscriptionId,
        billingPeriod: billingPeriod,
        autoRenew: autoRenew,
      ),
    );
    result.fold(
      (failure) => emit(SubscriptionError(failure.message)),
      (subscription) => emit(SubscriptionLoaded(subscription)),
    );
  }

  /// Load payment history
  Future<void> loadPaymentHistory(String subscriptionId) async {
    emit(SubscriptionLoading());
    final result = await getPaymentHistory(subscriptionId);
    result.fold(
      (failure) => emit(SubscriptionError(failure.message)),
      (payments) => emit(PaymentHistoryLoaded(payments)),
    );
  }
}
