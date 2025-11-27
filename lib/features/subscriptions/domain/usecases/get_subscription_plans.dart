import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/subscriptions/domain/entities/subscription_plan_entity.dart';
import 'package:mwanachuo/features/subscriptions/domain/repositories/subscription_repository.dart';

class GetSubscriptionPlans implements UseCase<List<SubscriptionPlanEntity>, NoParams> {
  final SubscriptionRepository repository;

  GetSubscriptionPlans(this.repository);

  @override
  Future<Either<Failure, List<SubscriptionPlanEntity>>> call(NoParams params) async {
    return await repository.getSubscriptionPlans();
  }
}

