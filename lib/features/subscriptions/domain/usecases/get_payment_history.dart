import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/subscriptions/domain/entities/subscription_payment_entity.dart';
import 'package:mwanachuo/features/subscriptions/domain/repositories/subscription_repository.dart';

class GetPaymentHistory
    implements UseCase<List<SubscriptionPaymentEntity>, String> {
  final SubscriptionRepository repository;

  GetPaymentHistory(this.repository);

  @override
  Future<Either<Failure, List<SubscriptionPaymentEntity>>> call(
    String subscriptionId,
  ) async {
    return await repository.getPaymentHistory(subscriptionId);
  }
}

