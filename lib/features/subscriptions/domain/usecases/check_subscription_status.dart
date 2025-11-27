import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/subscriptions/domain/repositories/subscription_repository.dart';

class CheckSubscriptionStatus
    implements UseCase<bool, CheckSubscriptionStatusParams> {
  final SubscriptionRepository repository;

  CheckSubscriptionStatus(this.repository);

  @override
  Future<Either<Failure, bool>> call(CheckSubscriptionStatusParams params) async {
    return await repository.canCreateListing(
      sellerId: params.sellerId,
      listingType: params.listingType,
    );
  }
}

class CheckSubscriptionStatusParams extends Equatable {
  final String sellerId;
  final String listingType; // 'product', 'service', or 'accommodation'

  const CheckSubscriptionStatusParams({
    required this.sellerId,
    required this.listingType,
  });

  @override
  List<Object> get props => [sellerId, listingType];
}

