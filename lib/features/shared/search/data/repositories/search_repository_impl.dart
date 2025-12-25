import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/network/network_info.dart';
import 'package:mwanachuo/features/shared/search/data/datasources/search_local_data_source.dart';
import 'package:mwanachuo/features/shared/search/data/datasources/search_remote_data_source.dart';
import 'package:mwanachuo/features/shared/search/domain/entities/search_filter_entity.dart';
import 'package:mwanachuo/features/shared/search/domain/entities/search_result_entity.dart';
import 'package:mwanachuo/features/shared/search/domain/repositories/search_repository.dart';

/// Implementation of SearchRepository
class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource remoteDataSource;
  final SearchLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  SearchRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<SearchResultEntity>>> search({
    required String query,
    SearchFilterEntity? filter,
    int? limit,
    int? offset,
  }) async {
    if (!await networkInfo.isConnected) {
      try {
        final cachedResults = await localDataSource.getCachedSearchResults();
        if (cachedResults.isNotEmpty) {
          return Right(cachedResults);
        }
      } catch (_) {}
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final results = await remoteDataSource.search(
        query: query,
        filter: filter,
        limit: limit,
        offset: offset,
      );

      // Cache results for offline use (only on first page search)
      if (offset == null || offset == 0) {
        await localDataSource.cacheSearchResults(results);
      }

      // Save search query to history
      if (query.isNotEmpty) {
        await localDataSource.saveSearchQuery(query);
      }

      return Right(results);
    } on ServerException catch (e) {
      // Fallback to cache if server error
      try {
        final cachedResults = await localDataSource.getCachedSearchResults();
        if (cachedResults.isNotEmpty) {
          return Right(cachedResults);
        }
      } catch (_) {}
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to search: $e'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getSearchSuggestions({
    required String query,
    int? limit,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final suggestions = await remoteDataSource.getSearchSuggestions(
        query: query,
        limit: limit,
      );
      return Right(suggestions);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get search suggestions: $e'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getRecentSearches({int? limit}) async {
    try {
      final searches = await localDataSource.getRecentSearches(limit: limit);
      return Right(searches);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to get recent searches: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveSearchQuery(String query) async {
    try {
      await localDataSource.saveSearchQuery(query);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to save search query: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearSearchHistory() async {
    try {
      await localDataSource.clearSearchHistory();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to clear search history: $e'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getPopularSearches({int? limit}) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final searches = await remoteDataSource.getPopularSearches(limit: limit);
      return Right(searches);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get popular searches: $e'));
    }
  }
}
