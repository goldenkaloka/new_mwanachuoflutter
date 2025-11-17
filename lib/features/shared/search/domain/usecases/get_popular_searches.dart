import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/search/domain/repositories/search_repository.dart';

/// Use case for getting popular searches
class GetPopularSearches
    implements UseCase<List<String>, GetPopularSearchesParams> {
  final SearchRepository repository;

  GetPopularSearches(this.repository);

  @override
  Future<Either<Failure, List<String>>> call(
    GetPopularSearchesParams params,
  ) async {
    return await repository.getPopularSearches(limit: params.limit);
  }
}

class GetPopularSearchesParams extends Equatable {
  final int? limit;

  const GetPopularSearchesParams({this.limit});

  @override
  List<Object?> get props => [limit];
}

