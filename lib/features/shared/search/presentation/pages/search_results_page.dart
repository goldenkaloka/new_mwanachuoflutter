import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/widgets/network_image_with_fallback.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/features/shared/search/domain/entities/search_filter_entity.dart';
import 'package:mwanachuo/features/shared/search/domain/entities/search_result_entity.dart';
import 'package:mwanachuo/features/shared/search/presentation/cubit/search_cubit.dart';
import 'package:mwanachuo/features/shared/search/presentation/cubit/search_state.dart';

class SearchResultsPage extends StatelessWidget {
  final String? searchQuery;

  const SearchResultsPage({super.key, this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SearchCubit>(
      create: (context) {
        final cubit = sl<SearchCubit>();
        if (searchQuery != null && searchQuery!.isNotEmpty) {
          cubit.search(query: searchQuery!);
        } else {
          cubit.loadPopularSearches();
        }
        return cubit;
      },
      child: _SearchResultsView(initialQuery: searchQuery),
    );
  }
}

class _SearchResultsView extends StatefulWidget {
  final String? initialQuery;

  const _SearchResultsView({this.initialQuery});

  @override
  State<_SearchResultsView> createState() => _SearchResultsViewState();
}

class _SearchResultsViewState extends State<_SearchResultsView> {
  late TextEditingController _searchController;
  String _selectedCategory = 'All';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      }
    });
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    List<SearchResultType>? types;
    if (_selectedCategory == 'Products') {
      types = [SearchResultType.product];
    } else if (_selectedCategory == 'Services') {
      types = [SearchResultType.service];
    } else if (_selectedCategory == 'Accommodations') {
      types = [SearchResultType.accommodation];
    }

    context.read<SearchCubit>().search(
      query: query,
      filter: SearchFilterEntity(types: types),
    );
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory == category) return;

    setState(() {
      _selectedCategory = category;
    });

    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _performSearch(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? Colors.white : kTextPrimary;

    return Scaffold(
      backgroundColor: isDarkMode
          ? kBackgroundColorDark
          : kBackgroundColorLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(context, isDarkMode, primaryTextColor),
            Expanded(
              child: BlocBuilder<SearchCubit, SearchState>(
                builder: (context, state) {
                  if (state is SearchInitial ||
                      state is PopularSearchesLoaded ||
                      state is RecentSearchesLoaded) {
                    return _buildInitialView(
                      state,
                      isDarkMode,
                      primaryTextColor,
                    );
                  }

                  // For other states (results, loading, error), show tabs + content
                  return Column(
                    children: [
                      _buildCategoryTabs(isDarkMode, primaryTextColor),
                      Expanded(
                        child: _buildContent(
                          state,
                          isDarkMode,
                          primaryTextColor,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(
    BuildContext context,
    bool isDarkMode,
    Color primaryTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? kBackgroundColorDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: primaryTextColor),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: widget.initialQuery == null,
              style: GoogleFonts.plusJakartaSans(
                color: primaryTextColor,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[500]),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Colors.grey[500],
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          context.read<SearchCubit>().reset();
                          context.read<SearchCubit>().loadPopularSearches();
                          setState(() {
                            _selectedCategory = 'All';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999.0),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.white10 : Colors.grey.shade300,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999.0),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.white10 : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999.0),
                  borderSide: const BorderSide(
                    color: kPrimaryColor,
                    width: 2.0,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              onChanged: (value) {
                setState(() {}); // Update to show/hide suffix icon
                _onSearchChanged(value);
              },
              onSubmitted: _performSearch,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(bool isDarkMode, Color primaryTextColor) {
    final categories = ['All', 'Products', 'Services', 'Accommodations'];

    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == _selectedCategory;
          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (_) => _onCategorySelected(category),
            selectedColor: kPrimaryColor,
            backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            labelStyle: GoogleFonts.plusJakartaSans(
              color: isSelected ? Colors.white : primaryTextColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildInitialView(
    SearchState state,
    bool isDarkMode,
    Color primaryTextColor,
  ) {
    if (state is PopularSearchesLoaded) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Popular Searches 🔥',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.searches.map((search) {
                return ActionChip(
                  label: Text(search),
                  onPressed: () {
                    _searchController.text = search;
                    _performSearch(search);
                  },
                  backgroundColor: isDarkMode
                      ? Colors.grey[800]
                      : Colors.grey[50],
                  labelStyle: GoogleFonts.plusJakartaSans(
                    color: primaryTextColor,
                  ),
                  side: BorderSide(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildContent(
    SearchState state,
    bool isDarkMode,
    Color primaryTextColor,
  ) {
    if (state is Searching) {
      return const Center(
        child: CircularProgressIndicator(color: kPrimaryColor),
      );
    }

    if (state is SearchError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: GoogleFonts.plusJakartaSans(
                color: primaryTextColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (state is SearchNoResults) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No results found for "${state.query}"',
              style: GoogleFonts.plusJakartaSans(
                color: primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Try adjusting your search or filters',
              style: GoogleFonts.plusJakartaSans(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (state is SearchResults) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.results.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final result = state.results[index];
          return _buildResultItem(result, isDarkMode, primaryTextColor);
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildResultItem(
    SearchResultEntity result,
    bool isDarkMode,
    Color primaryTextColor,
  ) {
    return GestureDetector(
      onTap: () {
        final route = _getRouteForType(result.type);
        if (route != null) {
          Navigator.pushNamed(context, route, arguments: result.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: NetworkImageWithFallback(
                imageUrl: result.imageUrl ?? '',
                width: 90,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getTypeLabel(result.type),
                          style: GoogleFonts.plusJakartaSans(
                            color: kPrimaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (result.price != null)
                        Text(
                          'TZS ${result.price!.toStringAsFixed(0)}',
                          style: GoogleFonts.plusJakartaSans(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.title,
                    style: GoogleFonts.plusJakartaSans(
                      color: primaryTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (result.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      result.description,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.grey[600],
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 2,
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

  String _getTypeLabel(SearchResultType type) {
    switch (type) {
      case SearchResultType.product:
        return 'PRODUCT';
      case SearchResultType.service:
        return 'SERVICE';
      case SearchResultType.accommodation:
        return 'HOUSING';
    }
  }

  String? _getRouteForType(SearchResultType type) {
    switch (type) {
      case SearchResultType.product:
        return '/product-details';
      case SearchResultType.service:
        return '/service-details';
      case SearchResultType.accommodation:
        return '/accommodation-details';
    }
  }
}
