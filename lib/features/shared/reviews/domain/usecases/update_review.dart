import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/reviews/domain/entities/review_entity.dart';
import 'package:mwanachuo/features/shared/reviews/domain/repositories/review_repository.dart';

/// Use case for updating a review
class UpdateReview implements UseCase<ReviewEntity, UpdateReviewParams> {
  final ReviewRepository repository;

  UpdateReview(this.repository);

  @override
  Future<Either<Failure, ReviewEntity>> call(
    UpdateReviewParams params,
  ) async {
    // Validate rating
    if (params.rating < 1 || params.rating > 5) {
      return Left(ValidationFailure('Rating must be between 1 and 5'));
    }

    return await repository.updateReview(
      reviewId: params.reviewId,
      rating: params.rating,
      comment: params.comment,
      imageUrls: params.imageUrls,
    );
  }
}

class UpdateReviewParams extends Equatable {
  final String reviewId;
  final double rating;
  final String? comment;
  final List<String>? imageUrls;

  const UpdateReviewParams({
    required this.reviewId,
    required this.rating,
    this.comment,
    this.imageUrls,
  });

  @override
  List<Object?> get props => [reviewId, rating, comment, imageUrls];
}

