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
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_bloc.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_event.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_state.dart';
import 'package:mwanachuo/features/products/domain/entities/product_entity.dart';
import 'package:mwanachuo/features/shared/reviews/presentation/cubit/review_cubit.dart';
import 'package:mwanachuo/features/shared/reviews/domain/entities/review_entity.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/message_bloc.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/message_event.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/message_state.dart';
import 'package:mwanachuo/core/services/logger_service.dart';

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
        BlocProvider(create: (context) => sl<MessageBloc>()),
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

    return BlocListener<MessageBloc, MessageState>(
      listener: (context, state) {
        if (state is ConversationLoaded) {
          // Validate conversation ID before navigation
          final conversationId = state.conversation.id;
          if (conversationId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Invalid conversation: missing ID',
                  style: GoogleFonts.plusJakartaSans(),
                ),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          // Navigate to chat with the conversation ID
          LoggerService.debug(
            'Navigating to chat with conversation ID: $conversationId (type: ${conversationId.runtimeType})',
          );
          Navigator.pushNamed(
            context,
            '/chat',
            arguments: conversationId,
          );
        } else if (state is MessageError) {
          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: GoogleFonts.plusJakartaSans(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // App bar with back button and actions
                SliverAppBar(
                  floating: true,
                  pinned: false,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.favorite_border, color: Colors.white),
                        onPressed: () {
                          // Handle favorite
                        },
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.share, color: Colors.white),
                        onPressed: () {
                          // Handle share
                        },
                      ),
                    ),
                  ],
                ),
                // Hero image carousel - now uses SliverToBoxAdapter for proper gesture handling
                SliverImageCarousel(
                  images: images,
                  expandedHeight: ResponsiveBreakpoints.responsiveValue(
                    context,
                    compact: 400.0,
                    medium: 420.0,
                    expanded: 600.0,
                  ),
                ),
                // Product info section
                SliverSection(
                  child: _buildProductInfoSliver(
                    product,
                    primaryTextColor,
                    screenSize,
                  ),
                ),
                // Description section
                SliverSection(
                  child: _buildDescription(
                    product,
                    primaryTextColor,
                    secondaryTextColor,
                    screenSize,
                  ),
                ),
                // Seller info section
                SliverSection(
                  child: _buildSellerInfo(
                    product,
                    primaryTextColor,
                    secondaryTextColor,
                    cardBgColor,
                    screenSize,
                  ),
                ),
                // Reviews section
                SliverSection(
                  child: CommentsAndRatingsSection(
                    itemId: product.id,
                    itemType: 'product',
                  ),
                ),
                // Bottom padding
                SliverPadding(
                  padding: EdgeInsets.only(
                    bottom: ResponsiveBreakpoints.isCompact(context) ? 112 : 80,
                  ),
                ),
              ],
            ),
            // Sticky action bar (only for compact)
            if (ResponsiveBreakpoints.isCompact(context))
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: StickyActionBar(
                  price: 'TZS ${product.price.toStringAsFixed(2)}',
                  actionButtonText: 'Message Seller',
                  onActionTap: () {
                    // Handle message seller - dispatch event and wait for ConversationLoaded
                    context.read<MessageBloc>().add(
                      GetOrCreateConversationEvent(
                        otherUserId: product.sellerId,
                        listingId: product.id,
                        listingType: 'product',
                        listingTitle: product.title,
                        listingImageUrl: product.images.isNotEmpty
                            ? product.images.first
                            : null,
                        listingPrice: 'TZS ${product.price.toStringAsFixed(2)}',
                      ),
                    );
                    // Navigation will happen in BlocListener when ConversationLoaded is emitted
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInfoSliver(
    ProductEntity product,
    Color primaryTextColor,
    ScreenSize screenSize,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Chip
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: kSpacingMd,
            vertical: kSpacingXs,
          ),
          decoration: BoxDecoration(
            color: kPrimaryColor.withValues(alpha: 0.2),
            borderRadius: kBaseRadiusFull,
          ),
          child: Text(
            product.category,
            style: textTheme.labelMedium?.copyWith(
              color: primaryTextColor.withValues(alpha: kOpacityHigh),
            ),
          ),
        ),
        SizedBox(height: kSpacingMd),
        // Title
        Text(
          product.title,
          style: textTheme.headlineMedium?.copyWith(color: primaryTextColor),
        ),
        SizedBox(height: kSpacingMd),
        // Rating and reviews
        if (product.rating != null && product.reviewCount != null)
          Row(
            children: [
              ...List.generate(5, (index) {
                final rating = product.rating ?? 0.0;
                if (index < rating.floor()) {
                  return const Icon(Icons.star, color: Colors.amber, size: 20);
                } else if (index < rating) {
                  return const Icon(
                    Icons.star_half,
                    color: Colors.amber,
                    size: 20,
                  );
                } else {
                  return Icon(
                    Icons.star_border,
                    color: primaryTextColor.withValues(alpha: 0.3),
                    size: 20,
                  );
                }
              }),
              const SizedBox(width: 8),
              Text(
                '${product.rating!.toStringAsFixed(1)} (${product.reviewCount} ${product.reviewCount == 1 ? 'review' : 'reviews'})',
                style: textTheme.bodyMedium?.copyWith(
                  color: primaryTextColor.withValues(alpha: kOpacityMedium),
                ),
              ),
            ],
          ),
        SizedBox(height: kSpacingLg),
        // Price
        Text(
          'TZS ${product.price.toStringAsFixed(2)}',
          style: textTheme.headlineSmall?.copyWith(
            color: kPrimaryColor,
            fontWeight: AppTypography.bold,
          ),
        ),
      ],
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

  Widget _buildTopAppBar(
    bool isDarkMode,
    Color primaryTextColor,
    ScreenSize screenSize,
  ) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(
      context,
    );
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          color: isDarkMode
              ? kBackgroundColorDark.withValues(alpha: 0.8)
              : kBackgroundColorLight.withValues(alpha: 0.8),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            screenSize == ScreenSize.expanded ? 24.0 : 48.0,
            horizontalPadding,
            8.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button
              _buildAppBarButton(
                icon: Icons.arrow_back,
                isDarkMode: isDarkMode,
                primaryTextColor: primaryTextColor,
                screenSize: screenSize,
              ),
              const Spacer(),
              // Action Buttons
              Row(
                children: [
                  _buildAppBarButton(
                    icon: Icons.favorite_border,
                    isDarkMode: isDarkMode,
                    primaryTextColor: primaryTextColor,
                    screenSize: screenSize,
                  ),
                  SizedBox(
                    width: ResponsiveBreakpoints.responsiveValue(
                      context,
                      compact: 12.0,
                      medium: 16.0,
                      expanded: 20.0,
                    ),
                  ),
                  _buildAppBarButton(
                    icon: Icons.share,
                    isDarkMode: isDarkMode,
                    primaryTextColor: primaryTextColor,
                    screenSize: screenSize,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarButton({
    required IconData icon,
    required bool isDarkMode,
    required Color primaryTextColor,
    ScreenSize? screenSize,
  }) {
    final buttonSize = ResponsiveBreakpoints.responsiveValue(
      context,
      compact: 40.0,
      medium: 44.0,
      expanded: 48.0,
    );
    final iconSize = ResponsiveBreakpoints.responsiveValue(
      context,
      compact: 24.0,
      medium: 26.0,
      expanded: 28.0,
    );

    return GestureDetector(
      onTap: () {
        if (icon == Icons.arrow_back) {
          Navigator.pop(context);
        } else if (icon == Icons.favorite_border) {
          // Handle favorite
        } else if (icon == Icons.share) {
          // Handle share
        }
      },
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: primaryTextColor, size: iconSize),
      ),
    );
  }

  Widget _buildImageCarousel(ProductEntity product, ScreenSize screenSize) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(
      context,
    );
    final carouselHeight = ResponsiveBreakpoints.responsiveValue(
      context,
      compact: 400.0,
      medium: 420.0,
      expanded: 600.0,
    );

    final images = product.images.isNotEmpty ? product.images : [''];

    return SizedBox(
      height: carouselHeight,
      child: PageView.builder(
        controller: _pageController,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Hero(
              tag: 'product_${images[index]}',
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  color: kPrimaryColor.withValues(alpha: 0.3),
                ),
                child: NetworkImageWithFallback(
                  imageUrl: images[index],
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(16.0),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageIndicators(
    ProductEntity product,
    bool isDarkMode,
    ScreenSize screenSize,
  ) {
    final images = product.images.isNotEmpty ? product.images : [''];

    return Padding(
      padding: EdgeInsets.only(
        top: ResponsiveBreakpoints.responsiveValue(
          context,
          compact: 12.0,
          medium: 16.0,
          expanded: 20.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(images.length, (index) {
          final isSelected = index == _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            height: 8.0,
            width: isSelected ? 16.0 : 8.0,
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDarkMode ? kPrimaryColor : kBackgroundColorDark)
                  : (isDarkMode
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.grey[300]),
              borderRadius: BorderRadius.circular(4.0),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProductInfo(
    ProductEntity product,
    Color primaryTextColor,
    ScreenSize screenSize,
  ) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(
      context,
    );
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        top: kSpacingMd,
        left: horizontalPadding,
        right: horizontalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Chip
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: kSpacingMd,
              vertical: kSpacingXs,
            ),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.2),
              borderRadius: kBaseRadiusFull,
            ),
            child: Text(
              product.category,
              style: textTheme.labelMedium?.copyWith(
                color: primaryTextColor.withValues(alpha: kOpacityHigh),
              ),
            ),
          ),
          SizedBox(height: kSpacingMd),
          // Title
          Text(
            product.title,
            style: textTheme.headlineMedium?.copyWith(color: primaryTextColor),
          ),
          SizedBox(height: kSpacingLg),
          // Price
          Text(
            'TZS ${product.price.toStringAsFixed(2)}',
            style: textTheme.headlineSmall?.copyWith(
              color: kPrimaryColor,
              fontWeight: AppTypography.bold,
            ),
          ),
        ],
      ),
    );
  }

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
        color: isDarkMode ? kDividerColorDark : kDividerColor,
        thickness: 1,
        height: 0,
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
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: textTheme.titleLarge?.copyWith(color: primaryTextColor),
          ),
          SizedBox(height: kSpacingMd),
          Text(
            product.description,
            style: textTheme.bodyMedium?.copyWith(color: secondaryTextColor),
          ),
          SizedBox(height: kSpacingLg),
          // Condition
          Row(
            children: [
              Text(
                'Condition: ',
                style: GoogleFonts.plusJakartaSans(
                  color: primaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                product.condition,
                style: GoogleFonts.plusJakartaSans(
                  color: secondaryTextColor,
                  fontSize: 16,
                ),
              ),
            ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seller Information',
            style: GoogleFonts.plusJakartaSans(
              color: primaryTextColor,
              fontSize: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 18.0,
                medium: 20.0,
                expanded: 22.0,
              ),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            height: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 16.0,
              medium: 20.0,
              expanded: 24.0,
            ),
          ),
          Container(
            padding: EdgeInsets.all(
              ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 16.0,
                medium: 20.0,
                expanded: 24.0,
              ),
            ),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Row(
              children: [
                // Profile Image
                Container(
                  width: ResponsiveBreakpoints.responsiveValue(
                    context,
                    compact: 56.0,
                    medium: 64.0,
                    expanded: 72.0,
                  ),
                  height: ResponsiveBreakpoints.responsiveValue(
                    context,
                    compact: 56.0,
                    medium: 64.0,
                    expanded: 72.0,
                  ),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kPrimaryColor.withValues(alpha: 0.3),
                  ),
                  child: ClipOval(
                    child: NetworkImageWithFallback(
                      imageUrl: product.sellerAvatar ?? '',
                      width: ResponsiveBreakpoints.responsiveValue(
                        context,
                        compact: 56.0,
                        medium: 64.0,
                        expanded: 72.0,
                      ),
                      height: ResponsiveBreakpoints.responsiveValue(
                        context,
                        compact: 56.0,
                        medium: 64.0,
                        expanded: 72.0,
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(
                  width: ResponsiveBreakpoints.responsiveValue(
                    context,
                    compact: 16.0,
                    medium: 20.0,
                    expanded: 24.0,
                  ),
                ),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.sellerName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: ResponsiveBreakpoints.responsiveValue(
                            context,
                            compact: 16.0,
                            medium: 18.0,
                            expanded: 20.0,
                          ),
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveBreakpoints.responsiveValue(
                          context,
                          compact: 2.0,
                          medium: 4.0,
                          expanded: 6.0,
                        ),
                      ),
                      Text(
                        product.location,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: ResponsiveBreakpoints.responsiveValue(
                            context,
                            compact: 14.0,
                            medium: 15.0,
                            expanded: 16.0,
                          ),
                          color: secondaryTextColor,
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveBreakpoints.responsiveValue(
                          context,
                          compact: 4.0,
                          medium: 6.0,
                          expanded: 8.0,
                        ),
                      ),
                      if (product.rating != null &&
                          product.reviewCount != null &&
                          product.reviewCount! > 0)
                        Row(
                          children: [
                            // Star Rating
                            ...List.generate(5, (index) {
                              final rating = product.rating ?? 0.0;
                              if (index < rating.floor()) {
                                return const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                );
                              } else if (index < rating) {
                                return const Icon(
                                  Icons.star_half,
                                  color: Colors.amber,
                                  size: 16,
                                );
                              } else {
                                return Icon(
                                  Icons.star_border,
                                  color: secondaryTextColor,
                                  size: 16,
                                );
                              }
                            }),
                            const SizedBox(width: 8),
                            // Review Count
                            Text(
                              '(${product.reviewCount} ${product.reviewCount == 1 ? 'review' : 'reviews'})',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          'No reviews yet',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: secondaryTextColor,
                          ),
                        ),
                    ],
                  ),
                ),
                // Navigation Arrow
                Icon(Icons.chevron_right, color: primaryTextColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCtaButton(ProductEntity product, bool isDarkMode) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(
      context,
    );
    final buttonHeight = ResponsiveBreakpoints.responsiveValue(
      context,
      compact: 56.0,
      medium: 52.0,
      expanded: 54.0,
    );
    final containerHeight = ResponsiveBreakpoints.responsiveValue(
      context,
      compact: 112.0,
      medium: 100.0,
      expanded: 96.0,
    );

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: containerHeight,
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          ResponsiveBreakpoints.responsiveValue(
            context,
            compact: 16.0,
            medium: 12.0,
            expanded: 16.0,
          ),
          horizontalPadding,
          ResponsiveBreakpoints.responsiveValue(
            context,
            compact: 32.0,
            medium: 20.0,
            expanded: 24.0,
          ),
        ),
        decoration: BoxDecoration(
          color: isDarkMode ? kBackgroundColorDark : kBackgroundColorLight,
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black26
                  : Colors.grey.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: double.infinity,
                medium: 400.0,
                expanded: 450.0,
              ),
            ),
            child: SizedBox(
              width: ResponsiveBreakpoints.isCompact(context)
                  ? double.infinity
                  : null,
              height: buttonHeight,
              child: BlocListener<MessageBloc, MessageState>(
                listener: (context, state) {
                  if (state is ConversationLoaded) {
                    // Validate conversation ID before navigation
                    final conversationId = state.conversation.id;
                    if (conversationId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Invalid conversation: missing ID',
                            style: GoogleFonts.plusJakartaSans(),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    // Navigate to chat with the conversation ID
                    LoggerService.debug(
                      'Navigating to chat with conversation ID: $conversationId (type: ${conversationId.runtimeType})',
                    );
                    Navigator.pushNamed(
                      context,
                      '/chat',
                      arguments: conversationId,
                    );
                  } else if (state is MessageError) {
                    // Show error
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          state.message,
                          style: GoogleFonts.plusJakartaSans(),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: ElevatedButton(
                  onPressed: () {
                    // Get or create conversation with seller, including listing details
                    context.read<MessageBloc>().add(
                      GetOrCreateConversationEvent(
                        otherUserId: product.sellerId,
                        listingId: product.id,
                        listingType: 'product',
                        listingTitle: product.title,
                        listingImageUrl: product.images.isNotEmpty
                            ? product.images.first
                            : null,
                        listingPrice: 'TZS ${product.price.toStringAsFixed(2)}',
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: kBackgroundColorDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        ResponsiveBreakpoints.responsiveValue(
                          context,
                          compact: 16.0,
                          medium: 18.0,
                          expanded: 20.0,
                        ),
                      ),
                    ),
                    elevation: ResponsiveBreakpoints.responsiveValue(
                      context,
                      compact: 4.0,
                      medium: 5.0,
                      expanded: 6.0,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveBreakpoints.responsiveValue(
                        context,
                        compact: 24.0,
                        medium: 32.0,
                        expanded: 36.0,
                      ),
                    ),
                  ),
                  child: Text(
                    'Contact Seller',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: ResponsiveBreakpoints.responsiveValue(
                        context,
                        compact: 16.0,
                        medium: 17.0,
                        expanded: 18.0,
                      ),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
