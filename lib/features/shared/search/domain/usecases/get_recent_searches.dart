import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/search/domain/repositories/search_repository.dart';

/// Use case for getting recent searches
class GetRecentSearches
    implements UseCase<List<String>, GetRecentSearchesParams> {
  final SearchRepository repository;

  GetRecentSearches(this.repository);

  @override
  Future<Either<Failure, List<String>>> call(
    GetRecentSearchesParams params,
  ) async {
    return await repository.getRecentSearches(limit: params.limit);
  }
}

class GetRecentSearchesParams extends Equatable {
  final int? limit;

  const GetRecentSearchesParams({this.limit});

  @override
  List<Object?> get props => [limit];
}

