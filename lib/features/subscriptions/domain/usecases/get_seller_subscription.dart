import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/subscriptions/domain/entities/seller_subscription_entity.dart';
import 'package:mwanachuo/features/subscriptions/domain/repositories/subscription_repository.dart';

class GetSellerSubscription implements UseCase<SellerSubscriptionEntity?, String> {
  final SubscriptionRepository repository;

  GetSellerSubscription(this.repository);

  @override
  Future<Either<Failure, SellerSubscriptionEntity?>> call(String sellerId) async {
    return await repository.getSellerSubscription(sellerId);
  }
}

