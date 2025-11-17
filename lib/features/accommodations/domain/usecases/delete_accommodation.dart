import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/accommodations/domain/repositories/accommodation_repository.dart';

class DeleteAccommodation implements UseCase<void, DeleteAccommodationParams> {
  final AccommodationRepository repository;

  DeleteAccommodation(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteAccommodationParams params) async {
    return await repository.deleteAccommodation(params.accommodationId);
  }
}

class DeleteAccommodationParams extends Equatable {
  final String accommodationId;

  const DeleteAccommodationParams({required this.accommodationId});

  @override
  List<Object?> get props => [accommodationId];
}

