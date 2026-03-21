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

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.restaurant_menu, 'label': 'All'},
    {'icon': Icons.local_fire_department, 'label': 'Fast Food'},
    {'icon': Icons.emoji_food_beverage, 'label': 'Local'},
    {'icon': Icons.coffee, 'label': 'Cafe'},
    {'icon': Icons.eco, 'label': 'Healthy'},
  ];

  @override
  void initState() {
    super.initState();
    // Fetch restaurants if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<FoodBloc>();
      if (bloc.state.restaurants.isEmpty && bloc.state.status != FoodStatus.loading) {
        bloc.add(LoadRestaurants());
      }
    });

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<FoodBloc, FoodState>(
      builder: (context, state) {
        if (state.status == FoodStatus.error) {
          return Scaffold(
            backgroundColor: isDarkMode ? kBackgroundColorDark : const Color(0xFFF5F7FA),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.errorMessage}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<FoodBloc>().add(LoadRestaurants()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state.restaurants.isEmpty && state.status == FoodStatus.loading) {
          return Scaffold(
            backgroundColor: isDarkMode ? kBackgroundColorDark : const Color(0xFFF5F7FA),
            body: const Center(child: CircularProgressIndicator(color: kPrimaryColor)),
          );
        }

        final restaurants = state.restaurants;
        // If we are here and restaurants is empty (and not loading), it might be initial or empty list.
        if (restaurants.isEmpty && state.status != FoodStatus.loading) {
           return Scaffold(
            backgroundColor: isDarkMode ? kBackgroundColorDark : const Color(0xFFF5F7FA),
            body: const Center(child: Text('No restaurants found.')),
          );
        }

        return Scaffold(
          backgroundColor: isDarkMode ? kBackgroundColorDark : const Color(0xFFF5F7FA),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildGradientAppBar(isDarkMode),
                SliverToBoxAdapter(child: _buildSearchBar(isDarkMode)),
                SliverToBoxAdapter(child: _buildCategoryScroll(isDarkMode)),
                SliverToBoxAdapter(child: _buildBecomePartnerCard(context, isDarkMode)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Popular Nearby',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isDarkMode ? Colors.white : kTextPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${restaurants.length} places',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kPrimaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildRestaurantCard(
                        context,
                        restaurants[index],
                        isDarkMode,
                        index,
                      ),
                      childCount: restaurants.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradientAppBar(bool isDarkMode) {
    return SliverAppBar(
      expandedHeight: 140.0,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: isDarkMode ? kSurfaceColorDark : Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [const Color(0xFF0A3D2F), kSurfaceColorDark]
                  : [kPrimaryColor.withValues(alpha: 0.08), Colors.white],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [kPrimaryColor, kPrimaryColorLight],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.restaurant, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Campus Cravings',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: isDarkMode ? Colors.white : kTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 44),
                    child: Text(
                      'Delicious food, delivered to your door 🍕',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white54 : kTextTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isDarkMode ? kSurfaceColorDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode ? Colors.white10 : Colors.grey.shade200,
          ),
          boxShadow: [
            if (!isDarkMode)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Icons.search_rounded, color: isDarkMode ? Colors.white38 : Colors.grey.shade400),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search restaurants, dishes...',
                style: GoogleFonts.plusJakartaSans(
                  color: isDarkMode ? Colors.white30 : Colors.grey.shade400,
                  fontSize: 15,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [kPrimaryColor, kPrimaryColorLight]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryScroll(bool isDarkMode) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 20),
        itemBuilder: (context, index) {
          final isSelected = index == _selectedCategoryIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(right: 14),
              width: 76,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [kPrimaryColor, kPrimaryColorLight],
                      )
                    : null,
                color: isSelected
                    ? null
                    : isDarkMode ? kSurfaceColorDark : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: isSelected
                    ? null
                    : Border.all(
                        color: isDarkMode ? Colors.white10 : Colors.grey.shade200,
                      ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: kPrimaryColor.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _categories[index]['icon'] as IconData,
                    color: isSelected
                        ? Colors.white
                        : isDarkMode ? Colors.white54 : Colors.grey.shade500,
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _categories[index]['label'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : isDarkMode ? Colors.white60 : Colors.grey.shade600,
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

  Widget _buildRestaurantCard(BuildContext context, Restaurant restaurant, bool isDarkMode, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/food-menu', arguments: restaurant);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: isDarkMode ? kSurfaceColorDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.25 : 0.06),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              Stack(
                children: [
                  Hero(
                    tag: 'restaurant_image_${restaurant.id}',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: Image.network(
                        restaurant.imageUrl ?? 'https://via.placeholder.com/400x200',
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 180,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [kPrimaryColor.withValues(alpha: 0.3), kPrimaryColorLight.withValues(alpha: 0.2)],
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.restaurant, size: 48, color: Colors.white54),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Top gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.center,
                          colors: [Colors.black.withValues(alpha: 0.25), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  // Rating badge (glassmorphism)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFBBF24)),
                              const SizedBox(width: 4),
                              Text(
                                restaurant.rating?.toStringAsFixed(1) ?? 'New',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Delivery time badge
                  Positioned(
                    bottom: 14,
                    left: 14,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule_rounded, size: 14, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                '${restaurant.deliveryTime ?? '20-30'} min',
                                style: GoogleFonts.plusJakartaSans(
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
              // Info section
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            restaurant.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDarkMode ? Colors.white : kTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: kPrimaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  restaurant.category ?? 'Variety',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: kPrimaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.location_on_outlined, size: 14,
                                color: isDarkMode ? Colors.white38 : Colors.grey.shade400),
                              const SizedBox(width: 2),
                              Text(
                                '0.8 km',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: isDarkMode ? Colors.white54 : kTextTertiary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [kPrimaryColor, kPrimaryColorLight]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBecomePartnerCard(BuildContext context, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D9488), Color(0xFF06B6D4), Color(0xFF2DD4BF)],
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: -10,
            bottom: -10,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Own a Restaurant?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reach thousands of students on campus.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pushNamed(context, '/restaurant-register'),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        child: Text(
                          'Join',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            color: kPrimaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
