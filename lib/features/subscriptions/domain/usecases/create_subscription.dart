import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/subscriptions/domain/entities/seller_subscription_entity.dart';
import 'package:mwanachuo/features/subscriptions/domain/repositories/subscription_repository.dart';

class CreateSubscription
    implements UseCase<SellerSubscriptionEntity, CreateSubscriptionParams> {
  final SubscriptionRepository repository;

  CreateSubscription(this.repository);

  @override
  Future<Either<Failure, SellerSubscriptionEntity>> call(
    CreateSubscriptionParams params,
  ) async {
    return await repository.createSubscription(
      sellerId: params.sellerId,
      planId: params.planId,
      billingPeriod: params.billingPeriod,
    );
  }
}

class CreateSubscriptionParams extends Equatable {
  final String sellerId;
  final String planId;
  final String billingPeriod; // 'monthly' or 'yearly'


  const CreateSubscriptionParams({
    required this.sellerId,
    required this.planId,
    required this.billingPeriod,

  });

  @override
  List<Object> get props => [sellerId, planId, billingPeriod];
}

