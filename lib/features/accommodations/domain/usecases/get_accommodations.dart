import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/models/filter_model.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/accommodations/domain/entities/accommodation_entity.dart';
import 'package:mwanachuo/features/accommodations/domain/repositories/accommodation_repository.dart';

class GetAccommodations implements UseCase<List<AccommodationEntity>, GetAccommodationsParams> {
  final AccommodationRepository repository;

  GetAccommodations(this.repository);

  @override
  Future<Either<Failure, List<AccommodationEntity>>> call(GetAccommodationsParams params) async {
    return await repository.getAccommodations(
      roomType: params.filter?.accommodationType ?? params.roomType,
      universityId: params.universityId,
      ownerId: params.ownerId,
      isFeatured: params.isFeatured,
      limit: params.limit,
      offset: params.offset,
      searchQuery: params.filter?.searchQuery,
      minPrice: params.filter?.minPrice,
      maxPrice: params.filter?.maxPrice,
      location: params.filter?.location,
      amenities: params.filter?.amenities,
      priceType: params.filter?.priceType,
      sortBy: params.filter?.sortBy,
      sortAscending: params.filter?.sortAscending ?? true,
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
  final AccommodationFilter? filter;

  const GetAccommodationsParams({
    this.roomType,
    this.universityId,
    this.ownerId,
    this.isFeatured,
    this.limit,
    this.offset,
    this.filter,
  });

  @override
  List<Object?> get props => [roomType, universityId, ownerId, isFeatured, limit, offset, filter];
}

