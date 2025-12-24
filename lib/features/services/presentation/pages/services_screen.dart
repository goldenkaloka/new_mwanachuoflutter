import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/core/models/filter_model.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/core/widgets/app_card.dart';
import 'package:mwanachuo/core/widgets/empty_state.dart';
import 'package:mwanachuo/core/widgets/category_chips.dart';
import 'package:mwanachuo/core/widgets/filter_bottom_sheet.dart';
import 'package:mwanachuo/core/widgets/filter_chips.dart';
import 'package:mwanachuo/core/widgets/search_filter_bar.dart';
import 'package:mwanachuo/features/shared/categories/presentation/cubit/category_cubit.dart';
import 'package:mwanachuo/core/widgets/shimmer_loading.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_bloc.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_event.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_state.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              sl<ServiceBloc>()..add(const LoadServicesEvent(limit: 50)),
        ),
        BlocProvider(
          create: (context) => sl<CategoryCubit>()..loadServiceCategories(),
        ),
      ],
      child: const _ServicesView(),
    );
  }
}

class _ServicesView extends StatefulWidget {
  const _ServicesView();

  @override
  State<_ServicesView> createState() => _ServicesViewState();
}

class _ServicesViewState extends State<_ServicesView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  ServiceFilter? _currentFilter;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      final state = context.read<ServiceBloc>().state;
      if (state is ServicesLoaded && state.hasMore && !state.isLoadingMore) {
        context.read<ServiceBloc>().add(
          LoadMoreServicesEvent(
            offset: state.services.length,
            filter: _currentFilter,
          ),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    final newFilter = (_currentFilter ?? const ServiceFilter()).copyWith(
      searchQuery: query.isEmpty ? null : query,
    );
    _currentFilter = newFilter.hasFilters ? newFilter : null;
    context.read<ServiceBloc>().add(ApplyServiceFilterEvent(filter: newFilter));
  }

  void _showFilterBottomSheet() {
    final currentState = context.read<ServiceBloc>().state;
    ServiceFilter? currentFilter = _currentFilter;
    if (currentState is ServicesLoaded) {
      currentFilter = currentState.currentFilter ?? _currentFilter;
    }

    // Categories are now in chips, not in bottom sheet
    final sections = <FilterSection>[];

    FilterBottomSheet.show(
      context: context,
      sections: sections,
      priceRange: currentFilter != null
          ? PriceRange(min: currentFilter.minPrice, max: currentFilter.maxPrice)
          : null,
      onApply: (updatedSections, priceRange) {
        // Categories are handled by chips, not bottom sheet
        final newFilter = ServiceFilter(
          searchQuery: currentFilter?.searchQuery,
          minPrice: priceRange?.min,
          maxPrice: priceRange?.max,
          location: currentFilter?.location,
          category:
              currentFilter?.category, // Keep existing category from chips
          sortBy: currentFilter?.sortBy,
          sortAscending: currentFilter?.sortAscending ?? true,
        );

        setState(() {
          _currentFilter = newFilter.hasFilters ? newFilter : null;
        });

        context.read<ServiceBloc>().add(
          ApplyServiceFilterEvent(filter: newFilter),
        );
      },
      onReset: () {
        setState(() {
          _currentFilter = null;
        });
        context.read<ServiceBloc>().add(const ClearServiceFilterEvent());
      },
    );
  }

  List<FilterChipData> _buildFilterChips() {
    final filter = _currentFilter;
    if (filter == null || !filter.hasFilters) {
      return [];
    }

    final chips = <FilterChipData>[];

    if (filter.category != null) {
      chips.add(
        FilterChipData(
          label: 'Category: ${filter.category}',
          value: filter.category!,
          onRemove: () {
            final newFilter = filter.copyWith(clearCategory: true);
            setState(() {
              _currentFilter = newFilter.hasFilters ? newFilter : null;
            });
            context.read<ServiceBloc>().add(
              ApplyServiceFilterEvent(filter: newFilter),
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
            context.read<ServiceBloc>().add(
              ApplyServiceFilterEvent(filter: newFilter),
            );
          },
        ),
      );
    }

    return chips;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Services',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: BlocListener<ServiceBloc, ServiceState>(
        listener: (context, state) {
          if (state is ServicesLoaded) {
            _currentFilter = state.currentFilter ?? _currentFilter;
          }
        },
        child: Column(
          children: [
            // Search and Filter Bar
            SearchFilterBar(
              controller: _searchController,
              hintText: 'Search services...',
              onSearchChanged: _onSearchChanged,
              onFilterPressed: _showFilterBottomSheet,
              activeFilterCount: _currentFilter?.activeFilterCount ?? 0,
            ),
            // Category Chips (Alibaba-style)
            BlocBuilder<ServiceBloc, ServiceState>(
              buildWhen: (previous, current) {
                // Rebuild when filter changes
                if (previous is ServicesLoaded && current is ServicesLoaded) {
                  return previous.currentFilter?.category !=
                      current.currentFilter?.category;
                }
                return current is ServicesLoaded;
              },
              builder: (context, state) {
                final currentCategory = state is ServicesLoaded
                    ? (state.currentFilter?.category ??
                          _currentFilter?.category)
                    : _currentFilter?.category;
                return CategoryChipsWithBloc(
                  selectedCategory: currentCategory,
                  onCategorySelected: (category) {
                    final newFilter = (_currentFilter ?? const ServiceFilter())
                        .copyWith(category: category);
                    setState(() {
                      _currentFilter = newFilter.hasFilters ? newFilter : null;
                    });
                    context.read<ServiceBloc>().add(
                      ApplyServiceFilterEvent(filter: newFilter),
                    );
                  },
                );
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
                context.read<ServiceBloc>().add(
                  const ClearServiceFilterEvent(),
                );
              },
            ),
            // Services List
            Expanded(
              child: BlocBuilder<ServiceBloc, ServiceState>(
                builder: (context, state) {
                  // Loading state - show shimmer skeleton
                  if (state is ServicesLoading) {
                    return Padding(
                      padding: EdgeInsets.all(
                        ResponsiveBreakpoints.responsiveHorizontalPadding(
                          context,
                        ),
                      ),
                      child: ListView.separated(
                        itemCount: 6,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: kSpacingMd),
                        itemBuilder: (context, index) => const ShimmerLoading(
                          height: 110,
                          width: double.infinity,
                        ),
                      ),
                    );
                  }

                  // Error state
                  if (state is ServiceError) {
                    return ErrorState(
                      title: 'Failed to Load Services',
                      message: state.message,
                      onRetry: () {
                        context.read<ServiceBloc>().add(
                          const LoadServicesEvent(limit: 20),
                        );
                      },
                    );
                  }

                  // Success state
                  if (state is ServicesLoaded) {
                    // Empty state
                    if (state.services.isEmpty && !state.isLoadingMore) {
                      return EmptyState(
                        type: EmptyStateType.noServices,
                        onAction: () => Navigator.pop(context),
                        actionLabel: 'Go Back',
                      );
                    }

                    // Services list with pagination
                    return ListView.separated(
                      controller: _scrollController,
                      padding: EdgeInsets.all(
                        ResponsiveBreakpoints.responsiveHorizontalPadding(
                          context,
                        ),
                      ),
                      itemCount:
                          state.services.length + (state.isLoadingMore ? 1 : 0),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: kSpacingMd),
                      itemBuilder: (context, index) {
                        // Show loading indicator at the bottom
                        if (index == state.services.length &&
                            state.isLoadingMore) {
                          return const Padding(
                            padding: EdgeInsets.all(kSpacingLg),
                            child: Center(
                              child: Column(
                                children: [
                                  CircularProgressIndicator(
                                    color: kPrimaryColor,
                                    strokeWidth: 2,
                                  ),
                                  SizedBox(height: kSpacingSm),
                                  Text(
                                    'Loading more...',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (index >= state.services.length) {
                          return const SizedBox.shrink();
                        }

                        // Use new ServiceCard component
                        final service = state.services[index];
                        return ServiceCard(
                          imageUrl: service.images.isNotEmpty
                              ? service.images.first
                              : '',
                          title: service.title,
                          price: 'TZS ${service.price.toStringAsFixed(2)}',
                          priceType: service.priceType,
                          category: service.category,
                          providerName: service.providerName,
                          location: service.location,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/service-details',
                            arguments: service.id,
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
