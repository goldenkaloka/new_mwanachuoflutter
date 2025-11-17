import 'package:equatable/equatable.dart';
import 'package:mwanachuo/features/shared/search/domain/entities/search_result_entity.dart';

/// Search filter entity for filtering search results
class SearchFilterEntity extends Equatable {
  final List<SearchResultType>? types;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final String? location;
  final String? category;
  final SearchSortBy sortBy;
  final bool sortDescending;

  const SearchFilterEntity({
    this.types,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.location,
    this.category,
    this.sortBy = SearchSortBy.relevance,
    this.sortDescending = true,
  });

  SearchFilterEntity copyWith({
    List<SearchResultType>? types,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? location,
    String? category,
    SearchSortBy? sortBy,
    bool? sortDescending,
  }) {
    return SearchFilterEntity(
      types: types ?? this.types,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      location: location ?? this.location,
      category: category ?? this.category,
      sortBy: sortBy ?? this.sortBy,
      sortDescending: sortDescending ?? this.sortDescending,
    );
  }

  @override
  List<Object?> get props => [
        types,
        minPrice,
        maxPrice,
        minRating,
        location,
        category,
        sortBy,
        sortDescending,
      ];
}

/// Enum for search sort options
enum SearchSortBy {
  relevance,
  priceAsc,
  priceDesc,
  rating,
  newest,
  oldest,
}

