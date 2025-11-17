import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/reviews/domain/repositories/review_repository.dart';

/// Use case for marking a review as helpful
class MarkReviewHelpful implements UseCase<void, MarkReviewHelpfulParams> {
  final ReviewRepository repository;

  MarkReviewHelpful(this.repository);

  @override
  Future<Either<Failure, void>> call(MarkReviewHelpfulParams params) async {
    return await repository.markReviewHelpful(params.reviewId);
  }
}

class MarkReviewHelpfulParams extends Equatable {
  final String reviewId;

  const MarkReviewHelpfulParams({required this.reviewId});

  @override
  List<Object?> get props => [reviewId];
}

