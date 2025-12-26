import 'package:equatable/equatable.dart';
import 'package:mwanachuo/features/subscriptions/domain/entities/subscription_plan_entity.dart';
import 'package:mwanachuo/features/subscriptions/domain/entities/seller_subscription_entity.dart';
import 'package:mwanachuo/features/subscriptions/domain/entities/subscription_payment_entity.dart';

abstract class SubscriptionState extends Equatable {
  const SubscriptionState();

  @override
  List<Object?> get props => [];
}

class SubscriptionInitial extends SubscriptionState {}

class SubscriptionLoading extends SubscriptionState {}

class SubscriptionPlansLoaded extends SubscriptionState {
  final List<SubscriptionPlanEntity> plans;

  const SubscriptionPlansLoaded(this.plans);

  @override
  List<Object> get props => [plans];
}

class SubscriptionLoaded extends SubscriptionState {
  final SellerSubscriptionEntity? subscription;

  const SubscriptionLoaded(this.subscription);

  @override
  List<Object?> get props => [subscription];
}

class SubscriptionExpired extends SubscriptionState {
  final SellerSubscriptionEntity? subscription;
  final bool inGracePeriod;

  const SubscriptionExpired({this.subscription, this.inGracePeriod = false});

  @override
  List<Object?> get props => [subscription, inGracePeriod];
}

class SubscriptionTrial extends SubscriptionState {
  final SellerSubscriptionEntity subscription;

  const SubscriptionTrial(this.subscription);

  @override
  List<Object> get props => [subscription];
}

class PaymentHistoryLoaded extends SubscriptionState {
  final List<SubscriptionPaymentEntity> payments;

  const PaymentHistoryLoaded(this.payments);

  @override
  List<Object> get props => [payments];
}

class StripePaymentDataReady extends SubscriptionState {
  final Map<String, dynamic> data;

  const StripePaymentDataReady(this.data);

  @override
  List<Object> get props => [data];
}

class SubscriptionError extends SubscriptionState {
  final String message;

  const SubscriptionError(this.message);

  @override
  List<Object> get props => [message];
}
