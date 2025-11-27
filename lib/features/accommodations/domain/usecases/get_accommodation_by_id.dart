import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/accommodations/domain/entities/accommodation_entity.dart';
import 'package:mwanachuo/features/accommodations/domain/repositories/accommodation_repository.dart';

class GetAccommodationById implements UseCase<AccommodationEntity, GetAccommodationByIdParams> {
  final AccommodationRepository repository;

  GetAccommodationById(this.repository);

  @override
  Future<Either<Failure, AccommodationEntity>> call(GetAccommodationByIdParams params) async {
    return await repository.getAccommodationById(params.accommodationId);
  }
}

class GetAccommodationByIdParams extends Equatable {
  final String accommodationId;

  const GetAccommodationByIdParams({required this.accommodationId});

  @override
  List<Object?> get props => [accommodationId];
}

