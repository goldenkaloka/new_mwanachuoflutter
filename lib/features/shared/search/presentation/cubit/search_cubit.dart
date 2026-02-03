import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/search/domain/entities/search_filter_entity.dart';
import 'package:mwanachuo/features/shared/search/domain/usecases/clear_search_history.dart';
import 'package:mwanachuo/features/shared/search/domain/usecases/get_popular_searches.dart';
import 'package:mwanachuo/features/shared/search/domain/usecases/get_recent_searches.dart';
import 'package:mwanachuo/features/shared/search/domain/usecases/get_search_suggestions.dart';
import 'package:mwanachuo/features/shared/search/domain/usecases/save_search_query.dart';
import 'package:mwanachuo/features/shared/search/domain/usecases/search_content.dart';
import 'package:mwanachuo/features/shared/search/presentation/cubit/search_state.dart';

/// Cubit for managing search state
class SearchCubit extends Cubit<SearchState> {
  final SearchContent searchContent;
  final GetSearchSuggestions getSearchSuggestions;
  final GetRecentSearches getRecentSearches;
  final SaveSearchQuery saveSearchQuery;
  final ClearSearchHistory clearSearchHistory;
  final GetPopularSearches getPopularSearches;

  SearchCubit({
    required this.searchContent,
    required this.getSearchSuggestions,
    required this.getRecentSearches,
    required this.saveSearchQuery,
    required this.clearSearchHistory,
    required this.getPopularSearches,
  }) : super(SearchInitial());

  /// Perform search
  Future<void> search({
    required String query,
    SearchFilterEntity? filter,
    int? limit,
    int? offset,
  }) async {
    // Allow empty query to fetch all items (Browse mode)
    // if (query.trim().isEmpty) {
    //   emit(SearchInitial());
    //   return;
    // }

    emit(Searching());

    final result = await searchContent(
      SearchContentParams(
        query: query,
        filter: filter,
        limit: limit,
        offset: offset,
      ),
    );

    if (isClosed) return;
    result.fold((failure) => emit(SearchError(message: failure.message)), (
      results,
    ) {
      if (results.isEmpty) {
        emit(SearchNoResults(query: query));
      } else {
        emit(
          SearchResults(
            results: results,
            query: query,
            filter: filter,
            hasMore: results.length == (limit ?? 20),
          ),
        );
      }
    });
  }

  /// Load more search results (pagination)
  Future<void> loadMore({
    required String query,
    required int offset,
    SearchFilterEntity? filter,
    int? limit,
  }) async {
    if (state is! SearchResults) return;

    final currentState = state as SearchResults;

    final result = await searchContent(
      SearchContentParams(
        query: query,
        filter: filter,
        limit: limit,
        offset: offset,
      ),
    );

    if (isClosed) return;
    result.fold((failure) => emit(SearchError(message: failure.message)), (
      results,
    ) {
      final allResults = [...currentState.results, ...results];
      emit(
        SearchResults(
          results: allResults,
          query: query,
          filter: filter,
          hasMore: results.length == (limit ?? 20),
        ),
      );
    });
  }

  /// Get search suggestions
  Future<void> getSuggestions({required String query, int? limit}) async {
    if (query.trim().isEmpty) {
      emit(SearchInitial());
      return;
    }

    emit(SuggestionsLoading());

    final result = await getSearchSuggestions(
      GetSearchSuggestionsParams(query: query, limit: limit),
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(SearchError(message: failure.message)),
      (suggestions) => emit(SuggestionsLoaded(suggestions: suggestions)),
    );
  }

  /// Load recent searches
  Future<void> loadRecentSearches({int? limit}) async {
    final result = await getRecentSearches(
      GetRecentSearchesParams(limit: limit),
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(SearchError(message: failure.message)),
      (searches) => emit(RecentSearchesLoaded(searches: searches)),
    );
  }

  /// Load popular searches
  Future<void> loadPopularSearches({int? limit}) async {
    final result = await getPopularSearches(
      GetPopularSearchesParams(limit: limit),
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(SearchError(message: failure.message)),
      (searches) => emit(PopularSearchesLoaded(searches: searches)),
    );
  }

  /// Save search query to history
  Future<void> saveQuery(String query) async {
    if (query.trim().isEmpty) return;

    await saveSearchQuery(SaveSearchQueryParams(query: query));
  }

  /// Clear search history
  Future<void> clearHistory() async {
    final result = await clearSearchHistory(NoParams());

    if (isClosed) return;
    result.fold(
      (failure) => emit(SearchError(message: failure.message)),
      (_) => emit(SearchHistoryCleared()),
    );
  }

  /// Reset to initial state
  void reset() {
    emit(SearchInitial());
  }
}
