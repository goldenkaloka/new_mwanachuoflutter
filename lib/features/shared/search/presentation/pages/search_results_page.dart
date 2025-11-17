import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/widgets/network_image_with_fallback.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_bloc.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_event.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_state.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_bloc.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_event.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_state.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_bloc.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_event.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_state.dart';

class SearchResultsPage extends StatelessWidget {
  final String? searchQuery;
  
  const SearchResultsPage({
    super.key,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<ProductBloc>()
            ..add(const LoadProductsEvent(limit: 50)),
        ),
        BlocProvider(
          create: (context) => sl<ServiceBloc>()
            ..add(const LoadServicesEvent(limit: 50)),
        ),
        BlocProvider(
          create: (context) => sl<AccommodationBloc>()
            ..add(const LoadAccommodationsEvent(limit: 50)),
        ),
      ],
      child: _SearchResultsView(searchQuery: searchQuery),
    );
  }
}

class _SearchResultsView extends StatefulWidget {
  final String? searchQuery;

  const _SearchResultsView({this.searchQuery});

  @override
  State<_SearchResultsView> createState() => _SearchResultsViewState();
}

class _SearchResultsViewState extends State<_SearchResultsView> {
  late TextEditingController _searchController;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  void _performSearch(String query) {
    if (query.isEmpty) return;
    
    // Load all data - client-side filtering happens in BlocBuilder
    context.read<ProductBloc>().add(const LoadProductsEvent(limit: 100));
    context.read<ServiceBloc>().add(const LoadServicesEvent(limit: 100));
    context.read<AccommodationBloc>().add(const LoadAccommodationsEvent(limit: 100));
  }
  
  bool _matchesQuery(String text, String query) {
    return text.toLowerCase().contains(query.toLowerCase());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? Colors.white : kTextPrimary;
    final secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: isDarkMode ? kBackgroundColorDark : kBackgroundColorLight,
      body: Column(
        children: [
          _buildSearchHeader(context, isDarkMode, primaryTextColor),
          _buildCategoryTabs(isDarkMode, primaryTextColor),
          Expanded(
            child: _buildSearchResults(isDarkMode, primaryTextColor, secondaryTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context, bool isDarkMode, Color primaryTextColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      color: isDarkMode ? kBackgroundColorDark : Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: primaryTextColor),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: widget.searchQuery == null,
              decoration: InputDecoration(
                hintText: 'Search products, services, accommodations...',
                filled: true,
                fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: kPrimaryColor),
                  onPressed: () => _performSearch(_searchController.text),
                ),
              ),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: isDarkMode ? kBackgroundColorDark : Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: categories.map((category) {
            final isSelected = category == _selectedCategory;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                selectedColor: kPrimaryColor,
                backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : primaryTextColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSearchResults(bool isDarkMode, Color primaryTextColor, Color secondaryTextColor) {
    if (_selectedCategory == 'All') {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductsSection(isDarkMode, primaryTextColor, secondaryTextColor),
            const SizedBox(height: 24),
            _buildServicesSection(isDarkMode, primaryTextColor, secondaryTextColor),
            const SizedBox(height: 24),
            _buildAccommodationsSection(isDarkMode, primaryTextColor, secondaryTextColor),
          ],
        ),
      );
    } else if (_selectedCategory == 'Products') {
      return _buildProductsSection(isDarkMode, primaryTextColor, secondaryTextColor);
    } else if (_selectedCategory == 'Services') {
      return _buildServicesSection(isDarkMode, primaryTextColor, secondaryTextColor);
    } else {
      return _buildAccommodationsSection(isDarkMode, primaryTextColor, secondaryTextColor);
    }
  }

  Widget _buildProductsSection(bool isDarkMode, Color primaryTextColor, Color secondaryTextColor) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductsLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: kPrimaryColor),
            ),
          );
        }

        if (state is ProductError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                state.message,
                style: TextStyle(color: secondaryTextColor),
              ),
            ),
          );
        }

        if (state is ProductsLoaded) {
          // Client-side filtering by search query
          final query = _searchController.text.trim();
          final filteredProducts = query.isEmpty
              ? state.products
              : state.products.where((p) =>
                  _matchesQuery(p.title, query) ||
                  _matchesQuery(p.description, query) ||
                  _matchesQuery(p.category, query)).toList();
          
          if (filteredProducts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  query.isEmpty ? 'No products available' : 'No products found for "$query"',
                  style: TextStyle(color: secondaryTextColor),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedCategory == 'All')
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Products (${filteredProducts.length})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredProducts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return _buildResultCard(
                    title: product.title,
                    price: '\$${product.price.toStringAsFixed(2)}',
                    description: product.description,
                    imageUrl: product.images.isNotEmpty ? product.images.first : '',
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/product-details',
                      arguments: product.id,
                    ),
                    isDarkMode: isDarkMode,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                  );
                },
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildServicesSection(bool isDarkMode, Color primaryTextColor, Color secondaryTextColor) {
    return BlocBuilder<ServiceBloc, ServiceState>(
      builder: (context, state) {
        if (state is ServicesLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: kPrimaryColor),
            ),
          );
        }

        if (state is ServiceError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                state.message,
                style: TextStyle(color: secondaryTextColor),
              ),
            ),
          );
        }

        if (state is ServicesLoaded) {
          // Client-side filtering by search query
          final query = _searchController.text.trim();
          final filteredServices = query.isEmpty
              ? state.services
              : state.services.where((s) =>
                  _matchesQuery(s.title, query) ||
                  _matchesQuery(s.description, query) ||
                  _matchesQuery(s.category, query)).toList();
          
          if (filteredServices.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  query.isEmpty ? 'No services available' : 'No services found for "$query"',
                  style: TextStyle(color: secondaryTextColor),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedCategory == 'All')
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Services (${filteredServices.length})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredServices.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final service = filteredServices[index];
                  return _buildResultCard(
                    title: service.title,
                    price: '\$${service.price.toStringAsFixed(2)}/${service.priceType}',
                    description: service.description,
                    imageUrl: service.images.isNotEmpty ? service.images.first : '',
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/service-details',
                      arguments: service.id,
                    ),
                    isDarkMode: isDarkMode,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                  );
                },
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAccommodationsSection(bool isDarkMode, Color primaryTextColor, Color secondaryTextColor) {
    return BlocBuilder<AccommodationBloc, AccommodationState>(
      builder: (context, state) {
        if (state is AccommodationsLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: kPrimaryColor),
            ),
          );
        }

        if (state is AccommodationError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                state.message,
                style: TextStyle(color: secondaryTextColor),
              ),
            ),
          );
        }

        if (state is AccommodationsLoaded) {
          // Client-side filtering by search query
          final query = _searchController.text.trim();
          final filteredAccommodations = query.isEmpty
              ? state.accommodations
              : state.accommodations.where((a) =>
                  _matchesQuery(a.name, query) ||
                  _matchesQuery(a.description, query) ||
                  _matchesQuery(a.location, query) ||
                  _matchesQuery(a.roomType, query)).toList();
          
          if (filteredAccommodations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  query.isEmpty ? 'No accommodations available' : 'No accommodations found for "$query"',
                  style: TextStyle(color: secondaryTextColor),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedCategory == 'All')
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Accommodations (${filteredAccommodations.length})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredAccommodations.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final accommodation = filteredAccommodations[index];
                  return _buildResultCard(
                    title: accommodation.name,
                    price: '\$${accommodation.price.toStringAsFixed(2)}/${accommodation.priceType}',
                    description: accommodation.description,
                    imageUrl: accommodation.images.isNotEmpty ? accommodation.images.first : '',
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/accommodation-details',
                      arguments: accommodation.id,
                    ),
                    isDarkMode: isDarkMode,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                  );
                },
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildResultCard({
    required String title,
    required String price,
    required String description,
    required String imageUrl,
    required VoidCallback onTap,
    required bool isDarkMode,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: NetworkImageWithFallback(
                imageUrl: imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    price,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
