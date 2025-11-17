import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/reviews/domain/entities/review_entity.dart';
import 'package:mwanachuo/features/shared/reviews/domain/repositories/review_repository.dart';

/// Use case for getting user's review
class GetUserReview implements UseCase<ReviewEntity?, GetUserReviewParams> {
  final ReviewRepository repository;

  GetUserReview(this.repository);

  @override
  Future<Either<Failure, ReviewEntity?>> call(
    GetUserReviewParams params,
  ) async {
    return await repository.getUserReview(
      itemId: params.itemId,
      itemType: params.itemType,
    );
  }
}

class GetUserReviewParams extends Equatable {
  final String itemId;
  final ReviewType itemType;

  const GetUserReviewParams({
    required this.itemId,
    required this.itemType,
  });

  @override
  List<Object?> get props => [itemId, itemType];
}

