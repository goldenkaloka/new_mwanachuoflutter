import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/core/models/filter_model.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/core/widgets/app_card.dart';
import 'package:mwanachuo/core/widgets/empty_state.dart';
import 'package:mwanachuo/core/widgets/filter_bottom_sheet.dart';
import 'package:mwanachuo/core/widgets/filter_chips.dart';
import 'package:mwanachuo/core/widgets/search_filter_bar.dart';
import 'package:mwanachuo/core/widgets/shimmer_loading.dart';
import 'package:mwanachuo/features/accommodations/domain/entities/accommodation_constants.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_bloc.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_event.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_state.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class StudentHousingScreen extends StatelessWidget {
  const StudentHousingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<AccommodationBloc>()
            ..add(const LoadAccommodationsEvent(limit: 50)),
      child: const _HousingView(),
    );
  }
}

class _HousingView extends StatefulWidget {
  const _HousingView();

  @override
  State<_HousingView> createState() => _HousingViewState();
}

class _HousingViewState extends State<_HousingView> {
  final TextEditingController _searchController = TextEditingController();
  AccommodationFilter? _currentFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final newFilter = (_currentFilter ?? const AccommodationFilter()).copyWith(
      searchQuery: query.isEmpty ? null : query,
    );
    _currentFilter = newFilter.hasFilters ? newFilter : null;
    context.read<AccommodationBloc>().add(
      ApplyAccommodationFilterEvent(filter: newFilter),
    );
  }

  void _showFilterBottomSheet() {
    final currentState = context.read<AccommodationBloc>().state;
    AccommodationFilter? currentFilter = _currentFilter;
    if (currentState is AccommodationsLoaded) {
      currentFilter = currentState.currentFilter ?? _currentFilter;
    }

    // Room Type is now in chips, not in bottom sheet
    final sections = [
      FilterSection(
        title: 'Amenities',
        options: Amenities.all.map((amenity) {
          return FilterOption(
            label: amenity,
            value: amenity,
            isSelected: currentFilter?.amenities?.contains(amenity) ?? false,
          );
        }).toList(),
        isMultiSelect: true,
      ),
      FilterSection(
        title: 'Price Type',
        options: PriceTypes.all.map((priceType) {
          return FilterOption(
            label: PriceTypes.getDisplayName(priceType),
            value: priceType,
            isSelected: currentFilter?.priceType == priceType,
          );
        }).toList(),
      ),
    ];

    FilterBottomSheet.show(
      context: context,
      sections: sections,
      priceRange: currentFilter != null
          ? PriceRange(min: currentFilter.minPrice, max: currentFilter.maxPrice)
          : null,
      onApply: (updatedSections, priceRange) {
        // Room Type is handled by chips, not bottom sheet
        final selectedAmenities = updatedSections[0].options
            .where((opt) => opt.isSelected)
            .map((opt) => opt.value)
            .toList();
        final selectedPriceType = updatedSections[1].options
            .firstWhere(
              (opt) => opt.isSelected,
              orElse: () => const FilterOption(label: '', value: ''),
            )
            .value;

        final newFilter = AccommodationFilter(
          searchQuery: currentFilter?.searchQuery,
          minPrice: priceRange?.min,
          maxPrice: priceRange?.max,
          location: currentFilter?.location,
          accommodationType:
              currentFilter?.accommodationType, // Keep existing from chips
          amenities: selectedAmenities.isEmpty ? null : selectedAmenities,
          priceType: selectedPriceType.isEmpty ? null : selectedPriceType,
          sortBy: currentFilter?.sortBy,
          sortAscending: currentFilter?.sortAscending ?? true,
        );

        setState(() {
          _currentFilter = newFilter.hasFilters ? newFilter : null;
        });

        context.read<AccommodationBloc>().add(
          ApplyAccommodationFilterEvent(filter: newFilter),
        );
      },
      onReset: () {
        setState(() {
          _currentFilter = null;
        });
        context.read<AccommodationBloc>().add(
          const ClearAccommodationFilterEvent(),
        );
      },
    );
  }

  Widget _buildRoomTypeChips() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? kBackgroundColorDark : kBackgroundColorLight;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // "All" option
            _buildRoomTypeChip(
              'All',
              _currentFilter?.accommodationType == null,
            ),
            // Room type chips
            ...RoomTypes.all.map((roomType) {
              return _buildRoomTypeChip(
                roomType,
                _currentFilter?.accommodationType == roomType,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomTypeChip(String label, bool isSelected) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          final newFilter = (_currentFilter ?? const AccommodationFilter())
              .copyWith(accommodationType: label == 'All' ? null : label);
          setState(() {
            _currentFilter = newFilter.hasFilters ? newFilter : null;
          });
          context.read<AccommodationBloc>().add(
            ApplyAccommodationFilterEvent(filter: newFilter),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? kPrimaryColor
                : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: kPrimaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDarkMode ? Colors.grey[300] : Colors.grey[700]),
            ),
          ),
        ),
      ),
    );
  }

  List<FilterChipData> _buildFilterChips() {
    final filter = _currentFilter;
    if (filter == null || !filter.hasFilters) {
      return [];
    }

    final chips = <FilterChipData>[];

    if (filter.accommodationType != null) {
      chips.add(
        FilterChipData(
          label: 'Type: ${filter.accommodationType}',
          value: filter.accommodationType!,
          onRemove: () {
            final newFilter = filter.copyWith(clearType: true);
            setState(() {
              _currentFilter = newFilter.hasFilters ? newFilter : null;
            });
            context.read<AccommodationBloc>().add(
              ApplyAccommodationFilterEvent(filter: newFilter),
            );
          },
        ),
      );
    }

    if (filter.amenities != null && filter.amenities!.isNotEmpty) {
      for (final amenity in filter.amenities!) {
        chips.add(
          FilterChipData(
            label: amenity,
            value: amenity,
            onRemove: () {
              final updatedAmenities = List<String>.from(filter.amenities!)
                ..remove(amenity);
              final newFilter = filter.copyWith(
                amenities: updatedAmenities.isEmpty ? null : updatedAmenities,
              );
              setState(() {
                _currentFilter = newFilter.hasFilters ? newFilter : null;
              });
              context.read<AccommodationBloc>().add(
                ApplyAccommodationFilterEvent(filter: newFilter),
              );
            },
          ),
        );
      }
    }

    if (filter.priceType != null) {
      chips.add(
        FilterChipData(
          label: 'Price: ${PriceTypes.getDisplayName(filter.priceType!)}',
          value: filter.priceType!,
          onRemove: () {
            final newFilter = filter.copyWith(clearPriceType: true);
            setState(() {
              _currentFilter = newFilter.hasFilters ? newFilter : null;
            });
            context.read<AccommodationBloc>().add(
              ApplyAccommodationFilterEvent(filter: newFilter),
            );
          },
        ),
      );
    }

    if (filter.minPrice != null || filter.maxPrice != null) {
      final priceLabel = filter.minPrice != null && filter.maxPrice != null
          ? 'Price: ${filter.minPrice!.toStringAsFixed(0)} - ${filter.maxPrice!.toStringAsFixed(0)}'
          : filter.minPrice != null
          ? 'Price: From ${filter.minPrice!.toStringAsFixed(0)}'
          : 'Price: Up to ${filter.maxPrice!.toStringAsFixed(0)}';
      chips.add(
        FilterChipData(
          label: priceLabel,
          value: 'price',
          onRemove: () {
            final newFilter = filter.copyWith(clearPrice: true);
            setState(() {
              _currentFilter = newFilter.hasFilters ? newFilter : null;
            });
            context.read<AccommodationBloc>().add(
              ApplyAccommodationFilterEvent(filter: newFilter),
            );
          },
        ),
      );
    }

    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveBreakpoints.responsiveGridColumns(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Student Housing',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: BlocListener<AccommodationBloc, AccommodationState>(
        listener: (context, state) {
          if (state is AccommodationsLoaded) {
            _currentFilter = state.currentFilter ?? _currentFilter;
          }
        },
        child: Column(
          children: [
            // Search and Filter Bar
            SearchFilterBar(
              controller: _searchController,
              hintText: 'Search accommodations...',
              onSearchChanged: _onSearchChanged,
              onFilterPressed: _showFilterBottomSheet,
              activeFilterCount: _currentFilter?.activeFilterCount ?? 0,
            ),
            // Room Type Chips (Alibaba-style)
            BlocBuilder<AccommodationBloc, AccommodationState>(
              buildWhen: (previous, current) {
                // Rebuild when filter changes
                if (previous is AccommodationsLoaded &&
                    current is AccommodationsLoaded) {
                  return previous.currentFilter?.accommodationType !=
                      current.currentFilter?.accommodationType;
                }
                return current is AccommodationsLoaded;
              },
              builder: (context, state) {
                // Update _currentFilter from state
                if (state is AccommodationsLoaded &&
                    state.currentFilter != null) {
                  _currentFilter = state.currentFilter;
                }
                return _buildRoomTypeChips();
              },
            ),
            // Filter Chips
            FilterChips(
              filters: _buildFilterChips(),
              onClearAll: () {
                setState(() {
                  _currentFilter = null;
                  _searchController.clear();
                });
                context.read<AccommodationBloc>().add(
                  const ClearAccommodationFilterEvent(),
                );
              },
            ),
            // Accommodations List
            Expanded(
              child: BlocBuilder<AccommodationBloc, AccommodationState>(
                builder: (context, state) {
                  // Loading state - show shimmer skeleton
                  if (state is AccommodationsLoading) {
                    return ProductGridSkeleton(
                      itemCount: 6,
                      crossAxisCount: crossAxisCount,
                    );
                  }

                  // Error state
                  if (state is AccommodationError) {
                    return ErrorState(
                      title: 'Failed to Load Accommodations',
                      message: state.message,
                      onRetry: () {
                        context.read<AccommodationBloc>().add(
                          const LoadAccommodationsEvent(limit: 20),
                        );
                      },
                    );
                  }

                  // Success state
                  if (state is AccommodationsLoaded) {
                    // Empty state
                    if (state.accommodations.isEmpty) {
                      return EmptyState(
                        type: EmptyStateType.noAccommodations,
                        onAction: () => Navigator.pop(context),
                        actionLabel: 'Go Back',
                      );
                    }

                    // Accommodations masonry grid
                    return MasonryGridView.count(
                      padding: EdgeInsets.all(
                        ResponsiveBreakpoints.responsiveHorizontalPadding(
                          context,
                        ),
                      ),
                      physics: const BouncingScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: kSpacingMd,
                      crossAxisSpacing: kSpacingMd,
                      itemCount: state.accommodations.length,
                      itemBuilder: (context, index) {
                        final accommodation = state.accommodations[index];
                        return AccommodationCard(
                          key: ValueKey('accommodation_${accommodation.id}'),
                          imageUrl: accommodation.images.isNotEmpty
                              ? accommodation.images.first
                              : '',
                          title: accommodation.name,
                          price:
                              'TZS ${accommodation.price.toStringAsFixed(0)}',
                          priceType: accommodation.priceType,
                          location: accommodation.location,
                          bedrooms: accommodation.bedrooms,
                          bathrooms: accommodation.bathrooms,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/accommodation-details',
                            arguments: accommodation.id,
                          ),
                        );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
