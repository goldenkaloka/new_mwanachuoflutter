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

  // Debounce support
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Initial fetch of all items
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
      // Re-fetch when tab changes, using current text
      _performSearch(_searchController.text);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final cubit = context.read<SearchCubit>();
      if (cubit.state is SearchResults &&
          !(cubit.state as SearchResults).isLoadingMore) {
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
      case 0: // All
        // No specific type filter, search all
        break;
      case 1: // Products
        types.add(SearchResultType.product);
        break;
      case 2: // Services
        types.add(SearchResultType.service);
        break;
      case 3: // Accommodations
        types.add(SearchResultType.accommodation);
        break;
    }
    return SearchFilterEntity(
      types: types.isNotEmpty ? types : null,
      sortBy: SearchSortBy.newest,
    );
  }

  void _performSearch(String query) {
    // Debounce/prevent duplicate calls if needed, but for now direct call
    // Allow empty query for "Browse" mode
    context.read<SearchCubit>().search(
      query: query,
      filter: _getCurrentFilter(),
    );
  }

  void _onSearchChanged(String value) {
    // Simple debounce
    // Cancel previous timer if exists? (Not implemented for brevity, leveraging simplistic debounce or Relying on user to stop typing)
    // For now, just call search on submit or with delay.
    // Let's rely on onSubmitted for explicit search or implement debounce:

    // Actually, "Browse" page usually filters instantly?
    // Let's implement a small delay
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
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Browse Listings',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search products, services...',
                      hintStyle: GoogleFonts.outfit(color: Colors.grey[500]),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.grey[500],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),

              // Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: colorScheme.primary,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                indicatorColor: colorScheme.primary,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Products'),
                  Tab(text: 'Services'),
                  Tab(text: 'Housing'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) {
          if (state is Searching) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SearchError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    state.message, // Show actual error
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
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
            );
          } else if (state is SearchResults) {
            if (state.results.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No listings found',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _performSearch(_searchController.text);
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: state.results.length + (state.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= state.results.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  return _buildListOption(
                    context: context,
                    result: state.results[index],
                    colorScheme: colorScheme,
                    isDark: isDark,
                  );
                },
              ),
            );
          }

          // Initial state / Empty
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildListOption({
    required BuildContext context,
    required SearchResultEntity result,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
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
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: 120,
                height: 120,
                child: result.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: result.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey[200]),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getTypeColor(
                          result.type,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getTypeName(result.type),
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getTypeColor(result.type),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Title
                    Text(
                      result.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Description
                    if (result.description.isNotEmpty)
                      Text(
                        result.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Price & Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (result.price != null)
                          Text(
                            'TZS ${result.price!.toStringAsFixed(0)}',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                        if (result.rating != null)
                          Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: Colors.amber[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                result.rating!.toStringAsFixed(1),
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(SearchResultType type) {
    switch (type) {
      case SearchResultType.product:
        return Colors.blue;
      case SearchResultType.service:
        return Colors.purple;
      case SearchResultType.accommodation:
        return Colors.orange;
    }
  }

  String _getTypeName(SearchResultType type) {
    switch (type) {
      case SearchResultType.product:
        return 'Product';
      case SearchResultType.service:
        return 'Service';
      case SearchResultType.accommodation:
        return 'Accommodation';
    }
  }
}
