import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/features/shared/search/domain/entities/search_filter_entity.dart';
import 'package:mwanachuo/features/shared/search/domain/entities/search_result_entity.dart';
import 'package:mwanachuo/features/shared/search/presentation/cubit/search_cubit.dart';
import 'package:mwanachuo/features/shared/search/presentation/cubit/search_state.dart';
import 'package:mwanachuo/features/products/presentation/pages/product_details_page.dart';
import 'package:mwanachuo/features/services/presentation/pages/service_detail_page.dart';
import 'package:mwanachuo/features/accommodations/presentation/pages/accommodation_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mwanachuo/core/widgets/app_background.dart';
import 'package:mwanachuo/core/widgets/shimmer_loading.dart';
import 'package:mwanachuo/core/widgets/empty_state.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';

class ListingsPage extends StatefulWidget {
  const ListingsPage({super.key});

  @override
  State<ListingsPage> createState() => _ListingsPageState();
}

class _ListingsPageState extends State<ListingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSearch('');
    });

    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _performSearch(_searchController.text);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final cubit = context.read<SearchCubit>();
      final state = cubit.state;
      if (state is SearchResults && !state.isLoadingMore && state.hasMore) {
        cubit.loadMore(
          query: _searchController.text,
          offset: (cubit.state as SearchResults).results.length,
          filter: _getCurrentFilter(),
        );
      }
    }
  }

  SearchFilterEntity _getCurrentFilter() {
    final types = <SearchResultType>[];
    switch (_tabController.index) {
      case 0:
        break; // All
      case 1:
        types.add(SearchResultType.product);
        break;
      case 2:
        types.add(SearchResultType.service);
        break;
      case 3:
        types.add(SearchResultType.accommodation);
        break;
    }
    return SearchFilterEntity(
      types: types.isNotEmpty ? types : null,
      sortBy: SearchSortBy.newest,
    );
  }

  void _performSearch(String query) {
    context.read<SearchCubit>().search(
      query: query,
      filter: _getCurrentFilter(),
    );
  }

  void _onSearchChanged(String value) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && value == _searchController.text && value != _lastQuery) {
        _lastQuery = value;
        _performSearch(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildSearchAndTabs(context, isDark, colorScheme),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 8,
                ),
                sliver: _buildContent(colorScheme, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndTabs(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search products, services...',
                hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[500]),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colorScheme.primary,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999.0),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999.0),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999.0),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 2.0,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
            ),
          ),
          // Tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: isDark ? Colors.white : Colors.black,
            unselectedLabelColor: Colors.grey[400],
            indicatorColor: isDark ? Colors.white : Colors.black,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            labelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14, // Slightly increased for readability
              fontWeight: FontWeight.w600,
            ),
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(
                width: 2.0,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            tabs: [
              const Tab(height: 44, child: Text('All')),
              const Tab(height: 44, child: Text('Products')),
              const Tab(height: 44, child: Text('Services')),
              const Tab(height: 44, child: Text('Accommodations')),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildContent(ColorScheme colorScheme, bool isDark) {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        if (state is Searching) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: ProductGridSkeleton(itemCount: 6),
            ),
          );
        } else if (state is SearchError) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.red[300],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _performSearch(_searchController.text),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        } else if (state is SearchResults) {
          if (state.results.isEmpty && !state.isLoadingMore) {
            return SliverFillRemaining(
              child: EmptyState(type: EmptyStateType.noResults),
            );
          }

          final crossAxisCount = 3;

          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              itemBuilder: (context, index) {
                if (index == state.results.length && state.isLoadingMore) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                // Ensure index is within bounds for results list
                if (index < state.results.length) {
                  return _ListingCard(
                    result: state.results[index],
                    colorScheme: colorScheme,
                    isDark: isDark,
                  );
                }
                return const SizedBox.shrink(); // Should not happen with correct itemCount
              },
              childCount: state.results.length + (state.isLoadingMore ? 1 : 0),
            ),
          );
        }
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    );
  }
}

class _ListingCard extends StatelessWidget {
  final SearchResultEntity result;
  final ColorScheme colorScheme;
  final bool isDark;

  const _ListingCard({
    required this.result,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (result.type == SearchResultType.product) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProductDetailsPage(),
              settings: RouteSettings(arguments: result.id),
            ),
          );
        } else if (result.type == SearchResultType.service) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ServiceDetailPage(),
              settings: RouteSettings(arguments: result.id),
            ),
          );
        } else if (result.type == SearchResultType.accommodation) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AccommodationDetailPage(),
              settings: RouteSettings(arguments: result.id),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          // No rounded corners and no shadows as requested
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade100,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image Section with Dynamic Height for Masonry
            AspectRatio(
              // Allow some variation in aspect ratio for staggered effect
              aspectRatio: result.type == SearchResultType.accommodation
                  ? 0.8
                  : 1.0,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: result.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: result.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: isDark
                                  ? Colors.grey[900]
                                  : Colors.grey[100],
                            ),
                            errorWidget: (context, url, _) => Container(
                              color: isDark
                                  ? Colors.grey[900]
                                  : Colors.grey[100],
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: isDark ? Colors.white24 : Colors.black12,
                                size: 24,
                              ),
                            ),
                          )
                        : Container(
                            color: isDark ? Colors.grey[900] : Colors.grey[100],
                            child: Icon(
                              Icons.image_outlined,
                              color: isDark ? Colors.white24 : Colors.black12,
                              size: 24,
                            ),
                          ),
                  ),
                  // Icon Badge
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getTypeIcon(result.type),
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Text Section
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.title,
                    style: GoogleFonts.plusJakartaSans(
                      color: isDark ? Colors.grey[300] : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (result.price != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'TZS ${result.price!.toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(SearchResultType type) {
    switch (type) {
      case SearchResultType.product:
        return Icons.shopping_bag_rounded;
      case SearchResultType.service:
        return Icons.handyman_rounded;
      case SearchResultType.accommodation:
        return Icons.home_work_rounded;
    }
  }
}
