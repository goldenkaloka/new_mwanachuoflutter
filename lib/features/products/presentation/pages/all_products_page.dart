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
import 'package:mwanachuo/core/widgets/shimmer_loading.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_bloc.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_event.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_state.dart';
import 'package:mwanachuo/features/shared/categories/presentation/cubit/category_cubit.dart';
import 'package:mwanachuo/features/shared/categories/presentation/cubit/category_state.dart';

class AllProductsPage extends StatelessWidget {
  const AllProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<ProductBloc>()..add(const LoadProductsEvent(limit: 50)),
        ),
        BlocProvider(
          create: (context) => sl<CategoryCubit>()..loadAll(),
        ),
      ],
      child: const _AllProductsView(),
    );
  }
}

class _AllProductsView extends StatefulWidget {
  const _AllProductsView();

  @override
  State<_AllProductsView> createState() => _AllProductsViewState();
}

class _AllProductsViewState extends State<_AllProductsView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  ProductFilter? _currentFilter;

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
      final state = context.read<ProductBloc>().state;
      if (state is ProductsLoaded && state.hasMore && !state.isLoadingMore) {
        context.read<ProductBloc>().add(
          LoadMoreProductsEvent(
            offset: state.products.length,
            filter: _currentFilter,
          ),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    final trimmedQuery = query.trim();
    final newFilter = (_currentFilter ?? const ProductFilter()).copyWith(
      searchQuery: trimmedQuery.isEmpty ? null : trimmedQuery,
    );
    // Always apply filter, even if only search query (hasFilters might not catch empty string)
    _currentFilter = (trimmedQuery.isNotEmpty || newFilter.hasFilters) ? newFilter : null;
    context.read<ProductBloc>().add(
      ApplyProductFilterEvent(filter: newFilter),
    );
  }

  void _showFilterBottomSheet() {
    final currentState = context.read<ProductBloc>().state;
    ProductFilter? currentFilter = _currentFilter;
    if (currentState is ProductsLoaded) {
      currentFilter = currentState.currentFilter ?? _currentFilter;
    }

    final categoryState = context.read<CategoryCubit>().state;
    
    // Get conditions from CategoryCubit (categories are now in chips, not in bottom sheet)
    List<String> conditions = [];
    
    if (categoryState is CategoriesLoaded) {
      conditions = categoryState.conditions.map((cond) => cond.name).toList();
    } else {
      // If conditions haven't loaded yet, show loading dialog and load them
      if (categoryState is CategoryLoading) {
        // Already loading, wait for it
        return;
      }
      context.read<CategoryCubit>().loadAll();
      // Show a snackbar to inform user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading filters...'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    
    final sections = [
      FilterSection(
        title: 'Condition',
        options: conditions.map((cond) {
          return FilterOption(
            label: cond,
            value: cond,
            isSelected: currentFilter?.condition == cond,
          );
        }).toList(),
      ),
    ];

    FilterBottomSheet.show(
      context: context,
      sections: sections,
      priceRange: currentFilter != null
          ? PriceRange(
              min: currentFilter.minPrice,
              max: currentFilter.maxPrice,
            )
          : null,
      onApply: (updatedSections, priceRange) {
        // Build new filter from selections (categories are handled by chips, not bottom sheet)
        final selectedCondition = updatedSections[0].options
            .firstWhere((opt) => opt.isSelected, orElse: () => const FilterOption(label: '', value: ''))
            .value;

        final newFilter = ProductFilter(
          searchQuery: currentFilter?.searchQuery,
          minPrice: priceRange?.min,
          maxPrice: priceRange?.max,
          location: currentFilter?.location,
          category: currentFilter?.category, // Keep existing category from chips
          condition: selectedCondition.isEmpty ? null : selectedCondition,
          sortBy: currentFilter?.sortBy,
          sortAscending: currentFilter?.sortAscending ?? true,
        );

        setState(() {
          _currentFilter = newFilter.hasFilters ? newFilter : null;
        });

        context.read<ProductBloc>().add(
          ApplyProductFilterEvent(filter: newFilter),
        );
      },
      onReset: () {
        setState(() {
          _currentFilter = null;
        });
        context.read<ProductBloc>().add(const ClearProductFilterEvent());
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
      chips.add(FilterChipData(
        label: 'Category: ${filter.category}',
        value: filter.category!,
        onRemove: () {
          final newFilter = filter.copyWith(clearCategory: true);
          setState(() {
            _currentFilter = newFilter.hasFilters ? newFilter : null;
          });
          context.read<ProductBloc>().add(
            ApplyProductFilterEvent(filter: newFilter),
          );
        },
      ));
    }

    if (filter.condition != null) {
      chips.add(FilterChipData(
        label: 'Condition: ${filter.condition}',
        value: filter.condition!,
        onRemove: () {
          final newFilter = filter.copyWith(clearCondition: true);
          setState(() {
            _currentFilter = newFilter.hasFilters ? newFilter : null;
          });
          context.read<ProductBloc>().add(
            ApplyProductFilterEvent(filter: newFilter),
          );
        },
      ));
    }

    if (filter.minPrice != null || filter.maxPrice != null) {
      final priceLabel = filter.minPrice != null && filter.maxPrice != null
          ? 'Price: ${filter.minPrice!.toStringAsFixed(0)} - ${filter.maxPrice!.toStringAsFixed(0)}'
          : filter.minPrice != null
              ? 'Price: From ${filter.minPrice!.toStringAsFixed(0)}'
              : 'Price: Up to ${filter.maxPrice!.toStringAsFixed(0)}';
      chips.add(FilterChipData(
        label: priceLabel,
        value: 'price',
        onRemove: () {
          final newFilter = filter.copyWith(clearPrice: true);
          setState(() {
            _currentFilter = newFilter.hasFilters ? newFilter : null;
          });
          context.read<ProductBloc>().add(
            ApplyProductFilterEvent(filter: newFilter),
          );
        },
      ));
    }

    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveBreakpoints.responsiveGridColumns(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Products',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: BlocListener<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state is ProductsLoaded) {
            _currentFilter = state.currentFilter ?? _currentFilter;
          }
        },
        child: Column(
          children: [
            // Search and Filter Bar
            SearchFilterBar(
              controller: _searchController,
              hintText: 'Search products...',
              onSearchChanged: _onSearchChanged,
              onFilterPressed: _showFilterBottomSheet,
              activeFilterCount: _currentFilter?.activeFilterCount ?? 0,
            ),
            // Category Chips (Alibaba-style)
            BlocBuilder<ProductBloc, ProductState>(
              buildWhen: (previous, current) {
                // Rebuild when filter changes
                if (previous is ProductsLoaded && current is ProductsLoaded) {
                  return previous.currentFilter?.category != current.currentFilter?.category;
                }
                return current is ProductsLoaded;
              },
              builder: (context, state) {
                final currentCategory = state is ProductsLoaded
                    ? (state.currentFilter?.category ?? _currentFilter?.category)
                    : _currentFilter?.category;
                return CategoryChipsWithBloc(
                  selectedCategory: currentCategory,
                  onCategorySelected: (category) {
                    final newFilter = (_currentFilter ?? const ProductFilter()).copyWith(
                      category: category,
                    );
                    setState(() {
                      _currentFilter = newFilter.hasFilters ? newFilter : null;
                    });
                    context.read<ProductBloc>().add(
                      ApplyProductFilterEvent(filter: newFilter),
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
                context.read<ProductBloc>().add(const ClearProductFilterEvent());
              },
            ),
            // Products List
            Expanded(
              child: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          // Loading state - show shimmer skeleton
          if (state is ProductsLoading) {
            return ProductGridSkeleton(
              itemCount: 6,
              crossAxisCount: crossAxisCount,
            );
          }

          // Error state - use new ErrorState widget
          if (state is ProductError) {
            return ErrorState(
              title: 'Failed to Load Products',
              message: state.message,
              onRetry: () {
                context.read<ProductBloc>().add(
                  const LoadProductsEvent(limit: 20),
                );
              },
            );
          }

          // Success state
          if (state is ProductsLoaded) {
            // Empty state - use new EmptyState widget
            if (state.products.isEmpty && !state.isLoadingMore) {
              return EmptyState(
                type: EmptyStateType.noProducts,
                onAction: () => Navigator.pop(context),
                actionLabel: 'Go Back',
              );
            }

            // Products grid with pagination
            return GridView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(
                ResponsiveBreakpoints.responsiveHorizontalPadding(context),
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.75,
                crossAxisSpacing: kSpacingLg,
                mainAxisSpacing: kSpacingLg,
              ),
              itemCount: state.products.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                // Show loading indicator at the bottom
                if (index == state.products.length && state.isLoadingMore) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(kSpacingLg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
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

                if (index >= state.products.length) {
                  return const SizedBox.shrink();
                }

                // Use new ProductCard component
                final product = state.products[index];
                return ProductCard(
                  imageUrl: product.images.isNotEmpty
                      ? product.images.first
                      : '',
                  title: product.title,
                  price: 'TZS ${product.price.toStringAsFixed(2)}',
                  category: product.category,
                  rating: product.rating,
                  reviewCount: product.reviewCount,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/product-details',
                    arguments: product.id,
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
