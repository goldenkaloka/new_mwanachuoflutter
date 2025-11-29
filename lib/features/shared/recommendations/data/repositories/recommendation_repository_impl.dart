import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/network/network_info.dart';
import 'package:mwanachuo/features/shared/recommendations/data/datasources/recommendation_remote_data_source.dart';
import 'package:mwanachuo/features/shared/recommendations/domain/entities/recommendation_criteria_entity.dart';
import 'package:mwanachuo/features/shared/recommendations/domain/entities/recommendation_entity.dart';
import 'package:mwanachuo/features/shared/recommendations/domain/entities/recommendation_type.dart';
import 'package:mwanachuo/features/shared/recommendations/domain/repositories/recommendation_repository.dart';

/// Implementation of RecommendationRepository
class RecommendationRepositoryImpl implements RecommendationRepository {
  final RecommendationRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  RecommendationRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<RecommendationEntity>>>
  getProductRecommendations({
    required String currentProductId,
    RecommendationCriteriaEntity? criteria,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final recommendations = await remoteDataSource.getProductRecommendations(
        currentProductId: currentProductId,
        criteria: criteria,
      );

      return Right(recommendations.map((r) => r.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get product recommendations: $e'));
    }
  }

  @override
  Future<Either<Failure, List<RecommendationEntity>>>
  getServiceRecommendations({
    required String currentServiceId,
    RecommendationCriteriaEntity? criteria,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final recommendations = await remoteDataSource.getServiceRecommendations(
        currentServiceId: currentServiceId,
        criteria: criteria,
      );

      return Right(recommendations.map((r) => r.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get service recommendations: $e'));
    }
  }

  @override
  Future<Either<Failure, List<RecommendationEntity>>>
  getAccommodationRecommendations({
    required String currentAccommodationId,
    RecommendationCriteriaEntity? criteria,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final recommendations = await remoteDataSource
          .getAccommodationRecommendations(
            currentAccommodationId: currentAccommodationId,
            criteria: criteria,
          );

      return Right(recommendations.map((r) => r.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(
        ServerFailure('Failed to get accommodation recommendations: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<RecommendationEntity>>> getRecommendations({
    required String currentItemId,
    required RecommendationType type,
    RecommendationCriteriaEntity? criteria,
  }) async {
    switch (type) {
      case RecommendationType.product:
        return getProductRecommendations(
          currentProductId: currentItemId,
          criteria: criteria,
        );
      case RecommendationType.service:
        return getServiceRecommendations(
          currentServiceId: currentItemId,
          criteria: criteria,
        );
      case RecommendationType.accommodation:
        return getAccommodationRecommendations(
          currentAccommodationId: currentItemId,
          criteria: criteria,
        );
    }
  }
}


