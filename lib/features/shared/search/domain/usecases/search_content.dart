import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/search/domain/entities/search_filter_entity.dart';
import 'package:mwanachuo/features/shared/search/domain/entities/search_result_entity.dart';
import 'package:mwanachuo/features/shared/search/domain/repositories/search_repository.dart';

/// Use case for searching content
class SearchContent
    implements UseCase<List<SearchResultEntity>, SearchContentParams> {
  final SearchRepository repository;

  SearchContent(this.repository);

  @override
  Future<Either<Failure, List<SearchResultEntity>>> call(
    SearchContentParams params,
  ) async {
    // Validate query
    // Allow empty query for "Browse" mode
    // if (params.query.trim().isEmpty) {
    //   return Left(ValidationFailure('Search query cannot be empty'));
    // }

    return await repository.search(
      query: params.query.trim(),
      filter: params.filter,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class SearchContentParams extends Equatable {
  final String query;
  final SearchFilterEntity? filter;
  final int? limit;
  final int? offset;

  const SearchContentParams({
    required this.query,
    this.filter,
    this.limit,
    this.offset,
  });

  @override
  List<Object?> get props => [query, filter, limit, offset];
}
