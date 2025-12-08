import 'package:equatable/equatable.dart';

/// Base filter class
abstract class BaseFilter extends Equatable {
  final String? searchQuery;
  final double? minPrice;
  final double? maxPrice;
  final String? location;
  final String? sortBy;
  final bool sortAscending;

  const BaseFilter({
    this.searchQuery,
    this.minPrice,
    this.maxPrice,
    this.location,
    this.sortBy,
    this.sortAscending = true,
  });

  bool get hasFilters =>
      searchQuery != null ||
      minPrice != null ||
      maxPrice != null ||
      location != null ||
      sortBy != null;

  int get activeFilterCount {
    int count = 0;
    if (searchQuery != null && searchQuery!.isNotEmpty) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (location != null && location!.isNotEmpty) count++;
    if (sortBy != null) count++;
    return count;
  }

  @override
  List<Object?> get props => [
        searchQuery,
        minPrice,
        maxPrice,
        location,
        sortBy,
        sortAscending,
      ];
}

/// Product filter model
class ProductFilter extends BaseFilter {
  final String? category;
  final String? condition;

  const ProductFilter({
    super.searchQuery,
    super.minPrice,
    super.maxPrice,
    super.location,
    super.sortBy,
    super.sortAscending,
    this.category,
    this.condition,
  });

  ProductFilter copyWith({
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    String? location,
    String? sortBy,
    bool? sortAscending,
    String? category,
    String? condition,
    bool clearSearch = false,
    bool clearPrice = false,
    bool clearLocation = false,
    bool clearCategory = false,
    bool clearCondition = false,
    bool clearSort = false,
  }) {
    return ProductFilter(
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
      location: clearLocation ? null : (location ?? this.location),
      sortBy: clearSort ? null : (sortBy ?? this.sortBy),
      sortAscending: sortAscending ?? this.sortAscending,
      category: clearCategory ? null : (category ?? this.category),
      condition: clearCondition ? null : (condition ?? this.condition),
    );
  }

  @override
  bool get hasFilters =>
      super.hasFilters || category != null || condition != null;

  @override
  int get activeFilterCount {
    int count = super.activeFilterCount;
    if (category != null && category!.isNotEmpty) count++;
    if (condition != null && condition!.isNotEmpty) count++;
    return count;
  }

  @override
  List<Object?> get props => [
        ...super.props,
        category,
        condition,
      ];
}

/// Service filter model
class ServiceFilter extends BaseFilter {
  final String? category;
  final String? serviceType;

  const ServiceFilter({
    super.searchQuery,
    super.minPrice,
    super.maxPrice,
    super.location,
    super.sortBy,
    super.sortAscending,
    this.category,
    this.serviceType,
  });

  ServiceFilter copyWith({
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    String? location,
    String? sortBy,
    bool? sortAscending,
    String? category,
    String? serviceType,
    bool clearSearch = false,
    bool clearPrice = false,
    bool clearLocation = false,
    bool clearCategory = false,
    bool clearServiceType = false,
    bool clearSort = false,
  }) {
    return ServiceFilter(
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
      location: clearLocation ? null : (location ?? this.location),
      sortBy: clearSort ? null : (sortBy ?? this.sortBy),
      sortAscending: sortAscending ?? this.sortAscending,
      category: clearCategory ? null : (category ?? this.category),
      serviceType: clearServiceType ? null : (serviceType ?? this.serviceType),
    );
  }

  @override
  bool get hasFilters =>
      super.hasFilters || category != null || serviceType != null;

  @override
  int get activeFilterCount {
    int count = super.activeFilterCount;
    if (category != null && category!.isNotEmpty) count++;
    if (serviceType != null && serviceType!.isNotEmpty) count++;
    return count;
  }

  @override
  List<Object?> get props => [
        ...super.props,
        category,
        serviceType,
      ];
}

/// Accommodation filter model
class AccommodationFilter extends BaseFilter {
  final String? accommodationType;
  final List<String>? amenities;
  final String? priceType; // 'monthly' or 'weekly'

  const AccommodationFilter({
    super.searchQuery,
    super.minPrice,
    super.maxPrice,
    super.location,
    super.sortBy,
    super.sortAscending,
    this.accommodationType,
    this.amenities,
    this.priceType,
  });

  AccommodationFilter copyWith({
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    String? location,
    String? sortBy,
    bool? sortAscending,
    String? accommodationType,
    List<String>? amenities,
    String? priceType,
    bool clearSearch = false,
    bool clearPrice = false,
    bool clearLocation = false,
    bool clearType = false,
    bool clearAmenities = false,
    bool clearPriceType = false,
    bool clearSort = false,
  }) {
    return AccommodationFilter(
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
      location: clearLocation ? null : (location ?? this.location),
      sortBy: clearSort ? null : (sortBy ?? this.sortBy),
      sortAscending: sortAscending ?? this.sortAscending,
      accommodationType: clearType ? null : (accommodationType ?? this.accommodationType),
      amenities: clearAmenities ? null : (amenities ?? this.amenities),
      priceType: clearPriceType ? null : (priceType ?? this.priceType),
    );
  }

  @override
  bool get hasFilters =>
      super.hasFilters ||
      accommodationType != null ||
      (amenities != null && amenities!.isNotEmpty) ||
      priceType != null;

  @override
  int get activeFilterCount {
    int count = super.activeFilterCount;
    if (accommodationType != null && accommodationType!.isNotEmpty) count++;
    if (amenities != null && amenities!.isNotEmpty) count++;
    if (priceType != null && priceType!.isNotEmpty) count++;
    return count;
  }

  @override
  List<Object?> get props => [
        ...super.props,
        accommodationType,
        amenities,
        priceType,
      ];
}

/// Sort options for listings
class SortOption {
  final String value;
  final String label;
  final bool ascending;

  const SortOption({
    required this.value,
    required this.label,
    this.ascending = true,
  });

  static const priceLowHigh = SortOption(
    value: 'price',
    label: 'Price: Low to High',
    ascending: true,
  );

  static const priceHighLow = SortOption(
    value: 'price',
    label: 'Price: High to Low',
    ascending: false,
  );

  static const newest = SortOption(
    value: 'created_at',
    label: 'Newest First',
    ascending: false,
  );

  static const oldest = SortOption(
    value: 'created_at',
    label: 'Oldest First',
    ascending: true,
  );

  static const popularity = SortOption(
    value: 'popularity',
    label: 'Most Popular',
    ascending: false,
  );

  static List<SortOption> get all => [
        priceLowHigh,
        priceHighLow,
        newest,
        oldest,
        popularity,
      ];
}

