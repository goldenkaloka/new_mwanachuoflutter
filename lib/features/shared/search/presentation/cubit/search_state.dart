import 'package:equatable/equatable.dart';
import 'package:mwanachuo/features/shared/search/domain/entities/search_filter_entity.dart';
import 'package:mwanachuo/features/shared/search/domain/entities/search_result_entity.dart';

/// Base class for all search states
abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SearchInitial extends SearchState {}

/// Searching
class Searching extends SearchState {}

/// Search results loaded
class SearchResults extends SearchState {
  final List<SearchResultEntity> results;
  final String query;
  final SearchFilterEntity? filter;
  final bool hasMore;
  final bool isLoadingMore;

  const SearchResults({
    required this.results,
    required this.query,
    this.filter,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  @override
  List<Object?> get props => [results, query, filter, hasMore, isLoadingMore];
}

/// No search results found
class SearchNoResults extends SearchState {
  final String query;

  const SearchNoResults({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Loading suggestions
class SuggestionsLoading extends SearchState {}

/// Suggestions loaded
class SuggestionsLoaded extends SearchState {
  final List<String> suggestions;

  const SuggestionsLoaded({required this.suggestions});

  @override
  List<Object?> get props => [suggestions];
}

/// Recent searches loaded
class RecentSearchesLoaded extends SearchState {
  final List<String> searches;

  const RecentSearchesLoaded({required this.searches});

  @override
  List<Object?> get props => [searches];
}

/// Popular searches loaded
class PopularSearchesLoaded extends SearchState {
  final List<String> searches;

  const PopularSearchesLoaded({required this.searches});

  @override
  List<Object?> get props => [searches];
}

/// Search history cleared
class SearchHistoryCleared extends SearchState {}

/// Error state
class SearchError extends SearchState {
  final String message;

  const SearchError({required this.message});

  @override
  List<Object?> get props => [message];
}
