import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/search/domain/repositories/search_repository.dart';

/// Use case for getting search suggestions
class GetSearchSuggestions
    implements UseCase<List<String>, GetSearchSuggestionsParams> {
  final SearchRepository repository;

  GetSearchSuggestions(this.repository);

  @override
  Future<Either<Failure, List<String>>> call(
    GetSearchSuggestionsParams params,
  ) async {
    if (params.query.trim().isEmpty) {
      return const Right([]);
    }

    return await repository.getSearchSuggestions(
      query: params.query.trim(),
      limit: params.limit,
    );
  }
}

class GetSearchSuggestionsParams extends Equatable {
  final String query;
  final int? limit;

  const GetSearchSuggestionsParams({
    required this.query,
    this.limit,
  });

  @override
  List<Object?> get props => [query, limit];
}

