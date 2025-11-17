import 'package:mwanachuo/core/constants/database_constants.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/features/shared/search/data/models/search_result_model.dart';
import 'package:mwanachuo/features/shared/search/domain/entities/search_filter_entity.dart';
import 'package:mwanachuo/features/shared/search/domain/entities/search_result_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Abstract class defining search remote data source operations
abstract class SearchRemoteDataSource {
  /// Search across all content
  Future<List<SearchResultModel>> search({
    required String query,
    SearchFilterEntity? filter,
    int? limit,
    int? offset,
  });

  /// Get search suggestions
  Future<List<String>> getSearchSuggestions({
    required String query,
    int? limit,
  });

  /// Get popular searches
  Future<List<String>> getPopularSearches({int? limit});
}

/// Implementation of SearchRemoteDataSource using Supabase
class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  final SupabaseClient supabaseClient;

  SearchRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<SearchResultModel>> search({
    required String query,
    SearchFilterEntity? filter,
    int? limit,
    int? offset,
  }) async {
    try {
      final results = <SearchResultModel>[];
      final searchLimit = limit ?? 20;
      final searchOffset = offset ?? 0;

      // Determine which types to search
      final typesToSearch = filter?.types ??
          [
            SearchResultType.product,
            SearchResultType.service,
            SearchResultType.accommodation,
          ];

      // Search products
      if (typesToSearch.contains(SearchResultType.product)) {
        final productResults = await _searchProducts(
          query,
          filter,
          searchLimit,
          searchOffset,
        );
        results.addAll(productResults);
      }

      // Search services
      if (typesToSearch.contains(SearchResultType.service)) {
        final serviceResults = await _searchServices(
          query,
          filter,
          searchLimit,
          searchOffset,
        );
        results.addAll(serviceResults);
      }

      // Search accommodations
      if (typesToSearch.contains(SearchResultType.accommodation)) {
        final accommodationResults = await _searchAccommodations(
          query,
          filter,
          searchLimit,
          searchOffset,
        );
        results.addAll(accommodationResults);
      }

      // Sort results based on filter
      if (filter != null) {
        results.sort((a, b) => _compareResults(a, b, filter));
      }

      return results.take(searchLimit).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to search: $e');
    }
  }

  Future<List<SearchResultModel>> _searchProducts(
    String query,
    SearchFilterEntity? filter,
    int limit,
    int offset,
  ) async {
    var queryBuilder = supabaseClient
        .from(DatabaseConstants.productsTable)
        .select()
        .or('title.ilike.%$query%,description.ilike.%$query%')
        .eq('is_active', true);

    if (filter != null) {
      if (filter.minPrice != null) {
        queryBuilder = queryBuilder.gte('price', filter.minPrice!);
      }
      if (filter.maxPrice != null) {
        queryBuilder = queryBuilder.lte('price', filter.maxPrice!);
      }
      if (filter.category != null) {
        queryBuilder = queryBuilder.eq('category', filter.category!);
      }
      if (filter.location != null) {
        queryBuilder = queryBuilder.eq('location', filter.location!);
      }
    }

    final response = await queryBuilder.limit(limit).range(offset, offset + limit - 1);
    return (response as List)
        .map((json) =>
            SearchResultModel.fromJson(json, SearchResultType.product))
        .toList();
  }

  Future<List<SearchResultModel>> _searchServices(
    String query,
    SearchFilterEntity? filter,
    int limit,
    int offset,
  ) async {
    var queryBuilder = supabaseClient
        .from(DatabaseConstants.servicesTable)
        .select()
        .or('title.ilike.%$query%,description.ilike.%$query%')
        .eq('is_active', true);

    if (filter != null) {
      if (filter.minPrice != null) {
        queryBuilder = queryBuilder.gte('price', filter.minPrice!);
      }
      if (filter.maxPrice != null) {
        queryBuilder = queryBuilder.lte('price', filter.maxPrice!);
      }
      if (filter.category != null) {
        queryBuilder = queryBuilder.eq('category', filter.category!);
      }
      if (filter.location != null) {
        queryBuilder = queryBuilder.eq('location', filter.location!);
      }
    }

    final response = await queryBuilder.limit(limit).range(offset, offset + limit - 1);
    return (response as List)
        .map((json) =>
            SearchResultModel.fromJson(json, SearchResultType.service))
        .toList();
  }

  Future<List<SearchResultModel>> _searchAccommodations(
    String query,
    SearchFilterEntity? filter,
    int limit,
    int offset,
  ) async {
    var queryBuilder = supabaseClient
        .from(DatabaseConstants.accommodationsTable)
        .select()
        .or('name.ilike.%$query%,description.ilike.%$query%')
        .eq('is_active', true);

    if (filter != null) {
      if (filter.minPrice != null) {
        queryBuilder = queryBuilder.gte('price', filter.minPrice!);
      }
      if (filter.maxPrice != null) {
        queryBuilder = queryBuilder.lte('price', filter.maxPrice!);
      }
      if (filter.location != null) {
        queryBuilder = queryBuilder.eq('location', filter.location!);
      }
    }

    final response = await queryBuilder.limit(limit).range(offset, offset + limit - 1);
    return (response as List)
        .map((json) =>
            SearchResultModel.fromJson(json, SearchResultType.accommodation))
        .toList();
  }

  int _compareResults(
    SearchResultModel a,
    SearchResultModel b,
    SearchFilterEntity filter,
  ) {
    switch (filter.sortBy) {
      case SearchSortBy.priceAsc:
        final priceA = a.price ?? double.infinity;
        final priceB = b.price ?? double.infinity;
        return priceA.compareTo(priceB);

      case SearchSortBy.priceDesc:
        final priceA = a.price ?? 0;
        final priceB = b.price ?? 0;
        return priceB.compareTo(priceA);

      case SearchSortBy.rating:
        final ratingA = a.rating ?? 0;
        final ratingB = b.rating ?? 0;
        return filter.sortDescending
            ? ratingB.compareTo(ratingA)
            : ratingA.compareTo(ratingB);

      case SearchSortBy.newest:
        if (a.createdAt == null || b.createdAt == null) return 0;
        return b.createdAt!.compareTo(a.createdAt!);

      case SearchSortBy.oldest:
        if (a.createdAt == null || b.createdAt == null) return 0;
        return a.createdAt!.compareTo(b.createdAt!);

      case SearchSortBy.relevance:
        return 0; // Keep original order (database relevance)
    }
  }

  @override
  Future<List<String>> getSearchSuggestions({
    required String query,
    int? limit,
  }) async {
    try {
      final suggestions = <String>[];
      final searchLimit = limit ?? 5;

      // Get suggestions from products
      final productSuggestions = await supabaseClient
          .from(DatabaseConstants.productsTable)
          .select('title')
          .ilike('title', '%$query%')
          .eq('is_active', true)
          .limit(searchLimit);

      suggestions.addAll(
        (productSuggestions as List).map((e) => e['title'] as String),
      );

      // Get suggestions from services
      final serviceSuggestions = await supabaseClient
          .from(DatabaseConstants.servicesTable)
          .select('title')
          .ilike('title', '%$query%')
          .eq('is_active', true)
          .limit(searchLimit);

      suggestions.addAll(
        (serviceSuggestions as List).map((e) => e['title'] as String),
      );

      // Remove duplicates and limit
      return suggestions.toSet().take(searchLimit).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get search suggestions: $e');
    }
  }

  @override
  Future<List<String>> getPopularSearches({int? limit}) async {
    try {
      // In a real implementation, this would query a table tracking search counts
      // For now, return some popular categories
      return [
        'Electronics',
        'Textbooks',
        'Tutoring',
        'Accommodation',
        'Furniture',
        'Laptops',
        'Phones',
        'Stationery',
      ].take(limit ?? 8).toList();
    } catch (e) {
      throw ServerException('Failed to get popular searches: $e');
    }
  }
}

