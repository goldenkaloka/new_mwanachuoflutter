import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/subscriptions/domain/repositories/subscription_repository.dart';

class CancelSubscription implements UseCase<void, String> {
  final SubscriptionRepository repository;

  CancelSubscription(this.repository);

  @override
  Future<Either<Failure, void>> call(String subscriptionId) async {
    return await repository.cancelSubscription(subscriptionId);
  }
}

