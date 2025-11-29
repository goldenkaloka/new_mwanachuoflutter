import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/shared/recommendations/domain/entities/recommendation_criteria_entity.dart';
import 'package:mwanachuo/features/shared/recommendations/domain/entities/recommendation_entity.dart';
import 'package:mwanachuo/features/shared/recommendations/domain/entities/recommendation_type.dart';

/// Repository interface for recommendation operations
abstract class RecommendationRepository {
  /// Get product recommendations based on criteria
  Future<Either<Failure, List<RecommendationEntity>>>
  getProductRecommendations({
    required String currentProductId,
    RecommendationCriteriaEntity? criteria,
  });

  /// Get service recommendations based on criteria
  Future<Either<Failure, List<RecommendationEntity>>>
  getServiceRecommendations({
    required String currentServiceId,
    RecommendationCriteriaEntity? criteria,
  });

  /// Get accommodation recommendations based on criteria
  Future<Either<Failure, List<RecommendationEntity>>>
  getAccommodationRecommendations({
    required String currentAccommodationId,
    RecommendationCriteriaEntity? criteria,
  });

  /// Get recommendations for any item type
  Future<Either<Failure, List<RecommendationEntity>>> getRecommendations({
    required String currentItemId,
    required RecommendationType type,
    RecommendationCriteriaEntity? criteria,
  });
}


