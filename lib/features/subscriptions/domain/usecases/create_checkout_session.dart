import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/subscriptions/domain/repositories/subscription_repository.dart';

class CreateCheckoutSession
    implements UseCase<String, CreateCheckoutSessionParams> {
  final SubscriptionRepository repository;

  CreateCheckoutSession(this.repository);

  @override
  Future<Either<Failure, String>> call(
    CreateCheckoutSessionParams params,
  ) async {
    return await repository.createCheckoutSession(
      sellerId: params.sellerId,
      planId: params.planId,
      billingPeriod: params.billingPeriod,
    );
  }
}

class CreateCheckoutSessionParams extends Equatable {
  final String sellerId;
  final String planId;
  final String billingPeriod; // 'monthly' or 'yearly'

  const CreateCheckoutSessionParams({
    required this.sellerId,
    required this.planId,
    required this.billingPeriod,
  });

  @override
  List<Object> get props => [sellerId, planId, billingPeriod];
}

