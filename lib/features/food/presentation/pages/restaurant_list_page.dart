import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/features/food/domain/entities/restaurant.dart';
import 'package:mwanachuo/features/food/presentation/bloc/food_bloc.dart';

class RestaurantListPage extends StatefulWidget {
  const RestaurantListPage({super.key});

  @override
  State<RestaurantListPage> createState() => _RestaurantListPageState();
}

class _RestaurantListPageState extends State<RestaurantListPage>
    with TickerProviderStateMixin {
  int _selectedCategoryIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.flash_on_rounded, 'label': 'All'},
    {'icon': Icons.fastfood_rounded, 'label': 'Fast Food'},
    {'icon': Icons.restaurant_rounded, 'label': 'Local'},
    {'icon': Icons.coffee_rounded, 'label': 'Cafe'},
    {'icon': Icons.eco_rounded, 'label': 'Healthy'},
  ];

  @override
  void initState() {
    super.initState();
    // Fetch data in parallel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<FoodBloc>();
      if (bloc.state.restaurants.isEmpty && bloc.state.status != FoodStatus.loading) {
        bloc.add(LoadRestaurants());
      }
      if (bloc.state.userRestaurant == null) {
        bloc.add(CheckUserRestaurant());
      }
      if (bloc.state.userUniversityId == null) {
        bloc.add(LoadUserUniversity());
      }
    });

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutQuart,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final spotifyBlack = const Color(0xFF121212);
    final bgColor = isDarkMode ? spotifyBlack : const Color(0xFFF8FAFC);

    return BlocBuilder<FoodBloc, FoodState>(
      builder: (context, state) {
        if (state.status == FoodStatus.error) {
          return Scaffold(
            backgroundColor: bgColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.errorMessage}', style: GoogleFonts.inter(color: isDarkMode ? Colors.white70 : Colors.black87)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<FoodBloc>().add(LoadRestaurants()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state.restaurants.isEmpty && state.status == FoodStatus.loading) {
          return Scaffold(
            backgroundColor: bgColor,
            body: const Center(child: CircularProgressIndicator(color: kPrimaryColor, strokeWidth: 2)),
          );
        }

        final restaurants = state.restaurants;
        if (restaurants.isEmpty && state.status != FoodStatus.loading) {
           return Scaffold(
            backgroundColor: bgColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_rounded, size: 64, color: isDarkMode ? Colors.white10 : Colors.black12),
                  const SizedBox(height: 16),
                  Text(
                    'No restaurants nearby yet.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white38 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: bgColor,
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildMinimalAppBar(isDarkMode),
                SliverToBoxAdapter(child: _buildMinimalSearchBar(isDarkMode)),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _CategoryDelegate(
                    child: _buildMinimalCategoryScroll(isDarkMode),
                    isDarkMode: isDarkMode,
                  ),
                ),
                if (state.userRestaurant == null)
                  SliverToBoxAdapter(child: _buildModernPartnerCard(context, isDarkMode)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Nearby Selection',
                          style: GoogleFonts.montserrat(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: isDarkMode ? Colors.white : kTextPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• ${restaurants.length} places',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode ? Colors.white38 : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildMinimalRestaurantCard(
                        context,
                        restaurants[index],
                        isDarkMode,
                        index,
                      ),
                      childCount: restaurants.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMinimalAppBar(bool isDarkMode) {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        expandedTitleScale: 1.3,
        centerTitle: false,
        title: Text(
          'Campus Cravings',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: isDarkMode ? Colors.white : kTextPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalSearchBar(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
          ),
        ),
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.inter(color: isDarkMode ? Colors.white : kTextPrimary),
          decoration: InputDecoration(
            hintText: 'Search for flavors...',
            hintStyle: GoogleFonts.inter(
              color: isDarkMode ? Colors.white24 : Colors.grey.shade400,
              fontSize: 15,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: isDarkMode ? Colors.white38 : Colors.grey.shade400,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalCategoryScroll(bool isDarkMode) {
    return Container(
      height: 60,
      color: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemBuilder: (context, index) {
          final isSelected = index == _selectedCategoryIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _categories[index]['label'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? kPrimaryColor
                          : (isDarkMode ? Colors.white60 : Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 2,
                    width: isSelected ? 12 : 0,
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMinimalRestaurantCard(BuildContext context, Restaurant restaurant, bool isDarkMode, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 80)),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/food-menu', arguments: restaurant),
        child: Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    children: [
                      Hero(
                        tag: 'restaurant_image_${restaurant.id}',
                        child: Image.network(
                          restaurant.imageUrl ?? 'https://via.placeholder.com/600x400',
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: isDarkMode ? Colors.white.withValues(alpha:0.05) : Colors.grey.shade100,
                            child: const Icon(Icons.restaurant_rounded, size: 48, color: Colors.white12),
                          ),
                        ),
                      ),
                      // Rating & Distance badge overlay
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFBBF24)),
                                  const SizedBox(width: 4),
                                  Text(
                                    restaurant.rating?.toStringAsFixed(1) ?? 'New',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(width: 1, height: 10, color: Colors.white24),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${restaurant.deliveryTime ?? '20'}m',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurant.name,
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: isDarkMode ? Colors.white : kTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${restaurant.category ?? 'Variety'} • TZS ${restaurant.deliveryFee?.toInt() ?? 0} delivery',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDarkMode ? Colors.white38 : Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.more_horiz_rounded, color: Colors.white24),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernPartnerCard(BuildContext context, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Own a Restaurant?',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Join the network and reach students across campus.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => Navigator.pushNamed(context, '/register-restaurant'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      'Get Started',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: kPrimaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.storefront_rounded, size: 64, color: Colors.white24),
        ],
      ),
    );
  }
}

class _CategoryDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final bool isDarkMode;

  _CategoryDelegate({required this.child, required this.isDarkMode});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
        boxShadow: [
          if (shrinkOffset > 0)
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: child,
    );
  }

  @override
  double get maxExtent => 60;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
