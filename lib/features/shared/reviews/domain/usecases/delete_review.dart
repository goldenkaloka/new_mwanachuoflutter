import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/reviews/domain/repositories/review_repository.dart';

/// Use case for deleting a review
class DeleteReview implements UseCase<void, DeleteReviewParams> {
  final ReviewRepository repository;

  DeleteReview(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteReviewParams params) async {
    return await repository.deleteReview(params.reviewId);
  }
}

class DeleteReviewParams extends Equatable {
  final String reviewId;

  const DeleteReviewParams({required this.reviewId});

  @override
  List<Object?> get props => [reviewId];
}

