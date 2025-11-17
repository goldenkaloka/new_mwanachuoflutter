import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/accommodations/domain/repositories/accommodation_repository.dart';

class IncrementViewCount implements UseCase<void, IncrementViewCountParams> {
  final AccommodationRepository repository;

  IncrementViewCount(this.repository);

  @override
  Future<Either<Failure, void>> call(IncrementViewCountParams params) async {
    return await repository.incrementViewCount(params.accommodationId);
  }
}

class IncrementViewCountParams extends Equatable {
  final String accommodationId;

  const IncrementViewCountParams({required this.accommodationId});

  @override
  List<Object?> get props => [accommodationId];
}

