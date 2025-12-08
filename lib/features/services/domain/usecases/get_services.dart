import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/models/filter_model.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/services/domain/entities/service_entity.dart';
import 'package:mwanachuo/features/services/domain/repositories/service_repository.dart';

class GetServices implements UseCase<List<ServiceEntity>, GetServicesParams> {
  final ServiceRepository repository;

  GetServices(this.repository);

  @override
  Future<Either<Failure, List<ServiceEntity>>> call(
    GetServicesParams params,
  ) async {
    return await repository.getServices(
      category: params.filter?.category ?? params.category,
      universityId: params.universityId,
      providerId: params.providerId,
      isFeatured: params.isFeatured,
      limit: params.limit,
      offset: params.offset,
      searchQuery: params.filter?.searchQuery,
      minPrice: params.filter?.minPrice,
      maxPrice: params.filter?.maxPrice,
      location: params.filter?.location,
      sortBy: params.filter?.sortBy,
      sortAscending: params.filter?.sortAscending ?? true,
    );
  }
}

class GetServicesParams extends Equatable {
  final String? category;
  final String? universityId;
  final String? providerId;
  final bool? isFeatured;
  final int? limit;
  final int? offset;
  final ServiceFilter? filter;

  const GetServicesParams({
    this.category,
    this.universityId,
    this.providerId,
    this.isFeatured,
    this.limit,
    this.offset,
    this.filter,
  });

  @override
  List<Object?> get props => [
        category,
        universityId,
        providerId,
        isFeatured,
        limit,
        offset,
        filter,
      ];
}

