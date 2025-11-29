import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/shared/recommendations/domain/entities/recommendation_criteria_entity.dart';
import 'package:mwanachuo/features/shared/recommendations/domain/entities/recommendation_entity.dart';
import 'package:mwanachuo/features/shared/recommendations/domain/repositories/recommendation_repository.dart';

/// Use case for getting accommodation recommendations
class GetAccommodationRecommendations {
  final RecommendationRepository repository;

  GetAccommodationRecommendations(this.repository);

  Future<Either<Failure, List<RecommendationEntity>>> call({
    required String currentAccommodationId,
    RecommendationCriteriaEntity? criteria,
  }) async {
    return await repository.getAccommodationRecommendations(
      currentAccommodationId: currentAccommodationId,
      criteria: criteria,
    );
  }
}


