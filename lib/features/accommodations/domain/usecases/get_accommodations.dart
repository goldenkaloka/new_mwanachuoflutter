import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/accommodations/domain/entities/accommodation_entity.dart';
import 'package:mwanachuo/features/accommodations/domain/repositories/accommodation_repository.dart';

class GetAccommodations implements UseCase<List<AccommodationEntity>, GetAccommodationsParams> {
  final AccommodationRepository repository;

  GetAccommodations(this.repository);

  @override
  Future<Either<Failure, List<AccommodationEntity>>> call(GetAccommodationsParams params) async {
    return await repository.getAccommodations(
      roomType: params.roomType,
      universityId: params.universityId,
      ownerId: params.ownerId,
      isFeatured: params.isFeatured,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class GetAccommodationsParams extends Equatable {
  final String? roomType;
  final String? universityId;
  final String? ownerId;
  final bool? isFeatured;
  final int? limit;
  final int? offset;

  const GetAccommodationsParams({
    this.roomType,
    this.universityId,
    this.ownerId,
    this.isFeatured,
    this.limit,
    this.offset,
  });

  @override
  List<Object?> get props => [roomType, universityId, ownerId, isFeatured, limit, offset];
}

