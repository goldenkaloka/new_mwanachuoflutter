import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/reviews/domain/entities/review_entity.dart';
import 'package:mwanachuo/features/shared/reviews/domain/entities/review_stats_entity.dart';
import 'package:mwanachuo/features/shared/reviews/domain/repositories/review_repository.dart';

/// Use case for getting review statistics
class GetReviewStats
    implements UseCase<ReviewStatsEntity, GetReviewStatsParams> {
  final ReviewRepository repository;

  GetReviewStats(this.repository);

  @override
  Future<Either<Failure, ReviewStatsEntity>> call(
    GetReviewStatsParams params,
  ) async {
    return await repository.getReviewStats(
      itemId: params.itemId,
      itemType: params.itemType,
    );
  }
}

class GetReviewStatsParams extends Equatable {
  final String itemId;
  final ReviewType itemType;

  const GetReviewStatsParams({
    required this.itemId,
    required this.itemType,
  });

  @override
  List<Object?> get props => [itemId, itemType];
}

