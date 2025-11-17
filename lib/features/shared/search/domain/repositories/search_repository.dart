import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/shared/search/domain/entities/search_filter_entity.dart';
import 'package:mwanachuo/features/shared/search/domain/entities/search_result_entity.dart';

/// Search repository interface
abstract class SearchRepository {
  /// Search across all content types
  Future<Either<Failure, List<SearchResultEntity>>> search({
    required String query,
    SearchFilterEntity? filter,
    int? limit,
    int? offset,
  });

  /// Get search suggestions/autocomplete
  Future<Either<Failure, List<String>>> getSearchSuggestions({
    required String query,
    int? limit,
  });

  /// Get recent searches
  Future<Either<Failure, List<String>>> getRecentSearches({
    int? limit,
  });

  /// Save search query to history
  Future<Either<Failure, void>> saveSearchQuery(String query);

  /// Clear search history
  Future<Either<Failure, void>> clearSearchHistory();

  /// Get popular searches
  Future<Either<Failure, List<String>>> getPopularSearches({
    int? limit,
  });
}

