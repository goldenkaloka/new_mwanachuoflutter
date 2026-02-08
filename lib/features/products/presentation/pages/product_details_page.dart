import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/constants/typography_constants.dart';
import 'package:mwanachuo/core/widgets/network_image_with_fallback.dart';
import 'package:mwanachuo/core/widgets/comments_and_ratings_section.dart';
import 'package:mwanachuo/core/widgets/empty_state.dart';
import 'package:mwanachuo/core/widgets/sliver_image_carousel.dart';
import 'package:mwanachuo/core/widgets/sliver_section.dart';
import 'package:mwanachuo/core/widgets/sticky_action_bar.dart';
import 'package:mwanachuo/core/widgets/responsive_container.dart';
import 'package:mwanachuo/core/utils/responsive.dart' hide ResponsiveContainer;
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
    final isExpanded = ResponsiveBreakpoints.isExpanded(context);

    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: kPrimaryColor),
                  SizedBox(height: kSpacingLg),
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
            isExpanded,
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
    bool isExpanded,
  ) {
    return Scaffold(
      body: ResponsiveBuilder(
        builder: (context, screenSize) {
          if (isExpanded) {
            return _buildExpandedLayout(
              context,
              product,
              isDarkMode,
              primaryTextColor,
              secondaryTextColor,
              cardBgColor,
            );
          }

          // Use sliver layout for compact/medium screens
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
      ),
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
                              isActive: true,
                              isDarkMode: isDarkMode,
                            ),
                            const SizedBox(width: 32),
                            _buildTabItem(
                              'Specs',
                              isActive: false,
                              isDarkMode: isDarkMode,
                            ),
                            const SizedBox(width: 32),
                            _buildTabItem(
                              'Reviews',
                              isActive: false,
                              isDarkMode: isDarkMode,
                            ),
                          ],
                        ),
                        const Divider(height: 1),
                        const SizedBox(height: 24),

                        // Description
                        Text(
                          product.description,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            height: 1.6,
                            color:
                                (isDarkMode
                                        ? Colors.white
                                        : const Color(0xFF11221F))
                                    .withValues(alpha: 0.7),
                          ),
                        ),

                        const SizedBox(height: 32),
                        // Specs Grid
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
                            _buildSpecCard(
                              Icons.fitbit,
                              'Sport',
                              '80+ Modes',
                              isDarkMode,
                          ],
                        ),

                        const SizedBox(height: 32),
                        // Reviews Section
                        CommentsAndRatingsSection(
                          itemId: product.id,
                          itemType: 'product',
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
        ],
      ),
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
            size: const Size.square(40),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.bottom(12),
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
    );
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


  Widget _buildExpandedLayout(
    BuildContext context,
    ProductEntity product,
    bool isDarkMode,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color cardBgColor,
  ) {
    return ResponsiveContainer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column - Images
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildImageCarousel(product, ScreenSize.expanded),
                  _buildPageIndicators(
                    product,
                    isDarkMode,
                    ScreenSize.expanded,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 0.0,
              medium: 24.0,
              expanded: 48.0,
            ),
          ),
          // Right Column - Details
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildTopAppBar(
                    isDarkMode,
                    primaryTextColor,
                    ScreenSize.expanded,
                  ),
                  _buildProductInfo(
                    product,
                    primaryTextColor,
                    ScreenSize.expanded,
                  ),
                  _buildSectionDivider(isDarkMode),
                  _buildDescription(
                    product,
                    primaryTextColor,
                    secondaryTextColor,
                    ScreenSize.expanded,
                  ),
                  _buildSectionDivider(isDarkMode),
                  _buildSellerInfo(
                    product,
                    primaryTextColor,
                    secondaryTextColor,
                    cardBgColor,
                    ScreenSize.expanded,
                  ),
                  const SizedBox(height: 48),
                  // Comments and Ratings Section
                  CommentsAndRatingsSection(
                    itemId: product.id,
                    itemType: 'product',
                  ),
                  const SizedBox(height: 48),
                  _buildCtaButton(product, isDarkMode),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildSectionDivider(bool isDarkMode) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(
      context,
    );
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: kSpacing2xl,
      ),
      child: Divider(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.1),
      ),
    );
  }

  Widget _buildDescription(
    ProductEntity product,
    Color primaryTextColor,
    Color secondaryTextColor,
    ScreenSize screenSize,
  ) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(
      context,
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            product.description,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: secondaryTextColor,
              height: 1.5,
            ),
          ),
        ],
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
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(
      context,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
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
              child: Text(
                'S',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seller Name', // Placeholder
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                  Text(
                    'Verified Seller',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: secondaryTextColor,
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

  Widget _buildCtaButton(ProductEntity product, bool isDarkMode) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(
      context,
    );
    return Padding(
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        bottom: 32,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
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
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            shadowColor: kPrimaryColor.withValues(alpha: 0.4),
          ),
          child: const Text(
            'Message Seller',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
