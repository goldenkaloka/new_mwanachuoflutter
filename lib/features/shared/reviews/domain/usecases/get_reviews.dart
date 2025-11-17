import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/reviews/domain/entities/review_entity.dart';
import 'package:mwanachuo/features/shared/reviews/domain/repositories/review_repository.dart';

/// Use case for getting reviews
class GetReviews implements UseCase<List<ReviewEntity>, GetReviewsParams> {
  final ReviewRepository repository;

  GetReviews(this.repository);

  @override
  Future<Either<Failure, List<ReviewEntity>>> call(
    GetReviewsParams params,
  ) async {
    return await repository.getReviews(
      itemId: params.itemId,
      itemType: params.itemType,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class GetReviewsParams extends Equatable {
  final String itemId;
  final ReviewType itemType;
  final int? limit;
  final int? offset;

  const GetReviewsParams({
    required this.itemId,
    required this.itemType,
    this.limit,
    this.offset,
  });

  @override
  List<Object?> get props => [itemId, itemType, limit, offset];
}

