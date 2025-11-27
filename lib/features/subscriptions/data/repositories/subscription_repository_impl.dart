import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/network/network_info.dart';
import 'package:mwanachuo/features/subscriptions/data/datasources/subscription_remote_data_source.dart';
import 'package:mwanachuo/features/subscriptions/domain/entities/subscription_plan_entity.dart';
import 'package:mwanachuo/features/subscriptions/domain/entities/seller_subscription_entity.dart';
import 'package:mwanachuo/features/subscriptions/domain/entities/subscription_payment_entity.dart';
import 'package:mwanachuo/features/subscriptions/domain/repositories/subscription_repository.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  SubscriptionRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<SubscriptionPlanEntity>>> getSubscriptionPlans() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final plans = await remoteDataSource.getSubscriptionPlans();
      return Right(plans);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SellerSubscriptionEntity?>> getSellerSubscription(
    String sellerId,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final subscription = await remoteDataSource.getSellerSubscription(sellerId);
      return Right(subscription);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> canCreateListing({
    required String sellerId,
    required String listingType,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final canCreate = await remoteDataSource.canCreateListing(
        sellerId: sellerId,
        listingType: listingType,
      );
      return Right(canCreate);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SellerSubscriptionEntity>> createSubscription({
    required String sellerId,
    required String planId,
    required String billingPeriod,
    required String stripeCheckoutSessionId,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final subscription = await remoteDataSource.createSubscription(
        sellerId: sellerId,
        planId: planId,
        billingPeriod: billingPeriod,
        stripeCheckoutSessionId: stripeCheckoutSessionId,
      );
      return Right(subscription);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelSubscription(String subscriptionId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.cancelSubscription(subscriptionId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SellerSubscriptionEntity>> updateSubscription({
    required String subscriptionId,
    String? billingPeriod,
    bool? autoRenew,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final subscription = await remoteDataSource.updateSubscription(
        subscriptionId: subscriptionId,
        billingPeriod: billingPeriod,
        autoRenew: autoRenew,
      );
      return Right(subscription);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SubscriptionPaymentEntity>>> getPaymentHistory(
    String subscriptionId,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final payments = await remoteDataSource.getPaymentHistory(subscriptionId);
      return Right(payments);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createCheckoutSession({
    required String sellerId,
    required String planId,
    required String billingPeriod,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final checkoutUrl = await remoteDataSource.createCheckoutSession(
        sellerId: sellerId,
        planId: planId,
        billingPeriod: billingPeriod,
      );
      return Right(checkoutUrl);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

