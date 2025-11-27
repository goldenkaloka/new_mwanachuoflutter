import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/subscriptions/domain/entities/seller_subscription_entity.dart';
import 'package:mwanachuo/features/subscriptions/domain/repositories/subscription_repository.dart';

class UpdateSubscription
    implements UseCase<SellerSubscriptionEntity, UpdateSubscriptionParams> {
  final SubscriptionRepository repository;

  UpdateSubscription(this.repository);

  @override
  Future<Either<Failure, SellerSubscriptionEntity>> call(
    UpdateSubscriptionParams params,
  ) async {
    return await repository.updateSubscription(
      subscriptionId: params.subscriptionId,
      billingPeriod: params.billingPeriod,
      autoRenew: params.autoRenew,
    );
  }
}

class UpdateSubscriptionParams extends Equatable {
  final String subscriptionId;
  final String? billingPeriod;
  final bool? autoRenew;

  const UpdateSubscriptionParams({
    required this.subscriptionId,
    this.billingPeriod,
    this.autoRenew,
  });

  @override
  List<Object?> get props => [subscriptionId, billingPeriod, autoRenew];
}

