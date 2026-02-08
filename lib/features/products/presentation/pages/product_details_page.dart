import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/widgets/network_image_with_fallback.dart';
import 'package:mwanachuo/core/widgets/comments_and_ratings_section.dart';
import 'package:mwanachuo/core/widgets/empty_state.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_bloc.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_event.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_state.dart';
import 'package:mwanachuo/features/products/domain/entities/product_entity.dart';
import 'package:mwanachuo/features/shared/reviews/presentation/cubit/review_cubit.dart';
import 'package:mwanachuo/features/shared/reviews/domain/entities/review_entity.dart';

class ProductDetailsPage extends StatelessWidget {
  const ProductDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get product ID from route arguments
    final productId = ModalRoute.of(context)?.settings.arguments as String?;

    if (productId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Invalid product ID'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<ProductBloc>()
            ..add(LoadProductByIdEvent(productId: productId))
            ..add(IncrementViewCountEvent(productId: productId)),
        ),
        BlocProvider(
          create: (context) => sl<ReviewCubit>()
            ..loadReviewsWithStats(
              itemId: productId,
              itemType: ReviewType.product,
              limit: 10,
            ),
        ),
      ],
      child: const _ProductDetailsView(),
    );
  }
}

class _ProductDetailsView extends StatefulWidget {
  const _ProductDetailsView();

  @override
  State<_ProductDetailsView> createState() => _ProductDetailsViewState();
}

class _ProductDetailsViewState extends State<_ProductDetailsView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _activeTab = 'Overview'; // 'Overview', 'Specs', 'Reviews'

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (_pageController.page != null) {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? kTextPrimaryDark : kTextPrimary;
    final secondaryTextColor = isDarkMode ? kTextSecondaryDark : kTextSecondary;
    final cardBgColor = isDarkMode ? kSurfaceColorDark : kSurfaceColorLight;

    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: kPrimaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'Loading product...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }

        if (state is ProductError) {
          return Scaffold(
            body: ErrorState(
              title: 'Failed to Load Product',
              message: state.message,
              onRetry: () => Navigator.pop(context),
              retryLabel: 'Go Back',
            ),
          );
        }

        if (state is ProductLoaded) {
          final product = state.product;
          return _buildProductContent(
            context,
            product,
            isDarkMode,
            primaryTextColor,
            secondaryTextColor,
            cardBgColor,
          );
        }

        return Scaffold(
          body: Center(
            child: Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductContent(
    BuildContext context,
    ProductEntity product,
    bool isDarkMode,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color cardBgColor,
  ) {
    return ResponsiveBuilder(
      builder: (context, screenSize) {
        return _buildSliverLayout(
          context,
          product,
          isDarkMode,
          primaryTextColor,
          secondaryTextColor,
          cardBgColor,
          screenSize,
        );
      },
    );
  }

  Widget _buildSliverLayout(
    BuildContext context,
    ProductEntity product,
    bool isDarkMode,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color cardBgColor,
    ScreenSize screenSize,
  ) {
    final images = product.images.isNotEmpty ? product.images : [''];
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = screenHeight * 0.55;

    return Scaffold(
      backgroundColor: isDarkMode
          ? kBackgroundColorDark
          : kBackgroundColorLight,
      body: Stack(
        children: [
          // Main Scroll Content
          SingleChildScrollView(
            child: Column(
              children: [
                // 1. Immersive Header (55vh)
                Stack(
                  children: [
                    SizedBox(
                      height: headerHeight,
                      width: double.infinity,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return NetworkImageWithFallback(
                            imageUrl: images[index],
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                    // Vignette Overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.1),
                              Colors.black.withValues(alpha: 0.4),
                            ],
                            stops: const [0.6, 0.8, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Floating Buttons
                    Positioned(
                      top: safeAreaTop + 16,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildGlassButton(
                            icon: Icons.arrow_back,
                            onTap: () => Navigator.pop(context),
                          ),
                          _buildGlassButton(
                            icon: Icons.favorite_border,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                    // Pagination Indicators
                    Positioned(
                      bottom: 50, // Above the content area overlap
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length, (index) {
                          final isSelected = index == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: isSelected ? 24 : 6,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? kPrimaryColor
                                  : Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),

                // 2. Overlapping Content Area
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? kBackgroundColorDark : Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(40),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 40,
                          offset: const Offset(0, -10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Rating
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.title,
                                    style: GoogleFonts.inter(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? Colors.white
                                          : const Color(0xFF11221F),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: kPrimaryColor,
                                        size: 16,
                                      ),
                                      const Icon(
                                        Icons.star,
                                        color: kPrimaryColor,
                                        size: 16,
                                      ),
                                      const Icon(
                                        Icons.star,
                                        color: kPrimaryColor,
                                        size: 16,
                                      ),
                                      const Icon(
                                        Icons.star,
                                        color: kPrimaryColor,
                                        size: 16,
                                      ),
                                      const Icon(
                                        Icons.star_half,
                                        color: kPrimaryColor,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '(${product.reviewCount ?? "1,248"} Reviews)',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color:
                                              (isDarkMode
                                                      ? Colors.white
                                                      : const Color(0xFF11221F))
                                                  .withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Tshs ${product.price.toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.white
                                        : const Color(0xFF11221F),
                                  ),
                                ),
                                const Text(
                                  'Free Shipping',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: kPrimaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),
                        // Tabs Placeholder
                        Row(
                          children: [
                            _buildTabItem(
                              'Overview',
                              isActive: _activeTab == 'Overview',
                              isDarkMode: isDarkMode,
                            ),
                            const SizedBox(width: 32),
                            _buildTabItem(
                              'Specs',
                              isActive: _activeTab == 'Specs',
                              isDarkMode: isDarkMode,
                            ),
                            const SizedBox(width: 32),
                            _buildTabItem(
                              'Reviews',
                              isActive: _activeTab == 'Reviews',
                              isDarkMode: isDarkMode,
                            ),
                          ],
                        ),
                        const Divider(height: 1),
                        const SizedBox(height: 24),

                        // Tab Content Area
                        _buildTabContent(
                          product,
                          isDarkMode,
                          primaryTextColor,
                          secondaryTextColor,
                          cardBgColor,
                          screenSize,
                        ),

                        const SizedBox(
                          height: 120,
                        ), // Bottom padding for footer
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Fixed Blurred Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildImmersiveBottomBar(context, product, isDarkMode),
          ),

          // 4. Floating Action Button (Only for Reviews Tab)
          if (_activeTab == 'Reviews')
            Positioned(
              bottom: 110, // Above the bottom bar
              right: 24,
              child: _buildReviewFAB(context, product, isDarkMode),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewFAB(
    BuildContext context,
    ProductEntity product,
    bool isDarkMode,
  ) {
    return GestureDetector(
      onTap: () => _showReviewSheet(context, product),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: kPrimaryColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.rate_review, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              'Write a Review',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewSheet(BuildContext context, ProductEntity product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReviewSheet(product: product),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: const Color(0xFF11221F)),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(
    String label, {
    required bool isActive,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = label;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: isActive
                    ? (isDarkMode ? Colors.white : const Color(0xFF11221F))
                    : (isDarkMode ? Colors.white : const Color(0xFF11221F))
                          .withValues(alpha: 0.4),
              ),
            ),
          ),
          if (isActive)
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: kPrimaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabContent(
    ProductEntity product,
    bool isDarkMode,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color cardBgColor,
    ScreenSize screenSize,
  ) {
    switch (_activeTab) {
      case 'Overview':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Specs Grid (Moved here if Overview should have it, or keep it above? Mockup shows tabs below specs or above?
            // Re-evaluating based on mockup: Tabs are usually for distinct sections.
            Text(
              product.description,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.6,
                color: (isDarkMode ? Colors.white : const Color(0xFF11221F))
                    .withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),
            _buildSellerInfo(
              product,
              primaryTextColor,
              secondaryTextColor,
              cardBgColor,
              screenSize,
            ),
          ],
        );
      case 'Specs':
        return Column(
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildSpecCard(
                  Icons.battery_charging_full,
                  'Battery',
                  '48 Hours',
                  isDarkMode,
                ),
                _buildSpecCard(
                  Icons.water_drop,
                  'Waterproof',
                  '50m depth',
                  isDarkMode,
                ),
                _buildSpecCard(
                  Icons.favorite,
                  'Health',
                  'HR Monitor',
                  isDarkMode,
                ),
                _buildSpecCard(Icons.fitbit, 'Sport', '80+ Modes', isDarkMode),
              ],
            ),
          ],
        );
      case 'Reviews':
        return CommentsAndRatingsSection(
          itemId: product.id,
          itemType: 'product',
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSpecCard(
    IconData icon,
    String label,
    String value,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPrimaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: kPrimaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.bold,
                    color: (isDarkMode ? Colors.white : const Color(0xFF11221F))
                        .withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF11221F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImmersiveBottomBar(
    BuildContext context,
    ProductEntity product,
    bool isDarkMode,
  ) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            color: (isDarkMode ? kBackgroundColorDark : Colors.white)
                .withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(
                color: (isDarkMode ? Colors.white : const Color(0xFF11221F))
                    .withValues(alpha: 0.05),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: (isDarkMode ? Colors.white : const Color(0xFF11221F))
                        .withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.shopping_bag_outlined,
                      color: isDarkMode
                          ? Colors.white
                          : const Color(0xFF11221F),
                    ),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryColor.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/chat',
                          arguments: {
                            'conversationId': 'new',
                            'otherUserId': product.sellerId,
                          },
                        );
                      },
                      child: const Text(
                        'Buy Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSellerInfo(
    ProductEntity product,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color cardBgColor,
    ScreenSize screenSize,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seller Information',
          style: textTheme.titleLarge?.copyWith(
            color: primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryTextColor.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: kPrimaryColor.withValues(alpha: 0.1),
                child: Icon(Icons.person, color: kPrimaryColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.sellerName,
                      style: textTheme.titleMedium?.copyWith(
                        color: primaryTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Trusted Seller • 4.9 Rating',
                      style: textTheme.bodySmall?.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  // View seller profile
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimaryColor,
                  side: const BorderSide(color: kPrimaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('View'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewSheet extends StatefulWidget {
  final ProductEntity product;
  const _ReviewSheet({required this.product});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  final _commentController = TextEditingController();
  double _userRating = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? kBackgroundColorDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: (isDarkMode ? Colors.white : Colors.black).withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Write a Review',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF11221F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How was your experience with this product?',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: (isDarkMode ? Colors.white : const Color(0xFF11221F))
                  .withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),

          // Star Selection
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => setState(() => _userRating = index + 1.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    index < _userRating ? Icons.star : Icons.star_border,
                    color: kPrimaryColor,
                    size: 40,
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 24),
          TextField(
            controller: _commentController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Describe your experience...',
              hintStyle: GoogleFonts.inter(
                color: (isDarkMode ? Colors.white : const Color(0xFF11221F))
                    .withValues(alpha: 0.4),
              ),
              filled: true,
              fillColor: kPrimaryColor.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _userRating == 0 || _commentController.text.isEmpty
                  ? null
                  : () {
                      // Actually submit using Bloc/Cubit
                      // For now we just close and show a snackbar
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Thank you for your review!'),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Submit Review',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
