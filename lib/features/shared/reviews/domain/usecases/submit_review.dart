import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/reviews/domain/entities/review_entity.dart';
import 'package:mwanachuo/features/shared/reviews/domain/repositories/review_repository.dart';

/// Use case for submitting a review
class SubmitReview implements UseCase<ReviewEntity, SubmitReviewParams> {
  final ReviewRepository repository;

  SubmitReview(this.repository);

  @override
  Future<Either<Failure, ReviewEntity>> call(
    SubmitReviewParams params,
  ) async {
    // Validate rating
    if (params.rating < 1 || params.rating > 5) {
      return Left(ValidationFailure('Rating must be between 1 and 5'));
    }

    return await repository.submitReview(
      itemId: params.itemId,
      itemType: params.itemType,
      rating: params.rating,
      comment: params.comment,
      imageUrls: params.imageUrls,
    );
  }
}

class SubmitReviewParams extends Equatable {
  final String itemId;
  final ReviewType itemType;
  final double rating;
  final String? comment;
  final List<String>? imageUrls;

  const SubmitReviewParams({
    required this.itemId,
    required this.itemType,
    required this.rating,
    this.comment,
    this.imageUrls,
  });

  @override
  List<Object?> get props => [itemId, itemType, rating, comment, imageUrls];
}

