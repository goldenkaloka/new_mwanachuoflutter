import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/accommodations/domain/entities/accommodation_entity.dart';
import 'package:mwanachuo/features/accommodations/domain/repositories/accommodation_repository.dart';

class GetMyAccommodations
    implements UseCase<List<AccommodationEntity>, GetMyAccommodationsParams> {
  final AccommodationRepository repository;

  GetMyAccommodations(this.repository);

  @override
  Future<Either<Failure, List<AccommodationEntity>>> call(
      GetMyAccommodationsParams params) async {
    return await repository.getMyAccommodations(
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class GetMyAccommodationsParams extends Equatable {
  final int? limit;
  final int? offset;

  const GetMyAccommodationsParams({
    this.limit,
    this.offset,
  });

  @override
  List<Object?> get props => [limit, offset];
}

