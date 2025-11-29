import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/core/widgets/network_image_with_fallback.dart';
import 'package:mwanachuo/core/widgets/comments_and_ratings_section.dart';
import 'package:mwanachuo/core/widgets/empty_state.dart';
import 'package:mwanachuo/core/widgets/sliver_image_carousel.dart';
import 'package:mwanachuo/core/widgets/sliver_section.dart';
import 'package:mwanachuo/core/widgets/sticky_action_bar.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_bloc.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_event.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_state.dart';
import 'package:mwanachuo/features/services/domain/entities/service_entity.dart';
import 'package:mwanachuo/features/shared/reviews/presentation/cubit/review_cubit.dart';
import 'package:mwanachuo/features/shared/reviews/domain/entities/review_entity.dart';
import 'package:mwanachuo/features/shared/recommendations/domain/entities/recommendation_type.dart';
import 'package:mwanachuo/features/shared/recommendations/domain/entities/recommendation_criteria_entity.dart';
import 'package:mwanachuo/features/shared/recommendations/presentation/widgets/recommendation_section.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/message_bloc.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/message_event.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/message_state.dart';

class ServiceDetailPage extends StatelessWidget {
  const ServiceDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get service ID from route arguments
    final serviceId = ModalRoute.of(context)?.settings.arguments as String?;

    if (serviceId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Invalid service ID'),
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
          create: (context) => sl<ServiceBloc>()
            ..add(LoadServiceByIdEvent(serviceId: serviceId)),
        ),
        BlocProvider(
          create: (context) => sl<ReviewCubit>()
            ..loadReviewsWithStats(
              itemId: serviceId,
              itemType: ReviewType.service,
              limit: 10,
            ),
        ),
        BlocProvider(
          create: (context) => sl<MessageBloc>(),
        ),
      ],
      child: const _ServiceDetailView(),
    );
  }
}

class _ServiceDetailView extends StatelessWidget {
  const _ServiceDetailView();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? kTextPrimaryDark : kTextPrimary;
    final secondaryTextColor = isDarkMode ? kTextSecondaryDark : kTextSecondary;
    final surfaceColor = isDarkMode ? kSurfaceColorDark : kSurfaceColorLight;

    return BlocBuilder<ServiceBloc, ServiceState>(
      builder: (context, state) {
        if (state is ServiceLoading) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: kPrimaryColor),
                  SizedBox(height: kSpacingLg),
                  Text(
                    'Loading service...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }

        if (state is ServiceError) {
          return Scaffold(
            body: ErrorState(
              title: 'Failed to Load Service',
              message: state.message,
              onRetry: () => Navigator.pop(context),
              retryLabel: 'Go Back',
            ),
          );
        }

        if (state is ServiceLoaded) {
          final service = state.service;
          return _buildServiceContent(
            context,
            service,
            isDarkMode,
            primaryTextColor,
            secondaryTextColor,
            surfaceColor,
          );
        }

        return Scaffold(
          body: Center(
            child: Text(
              'Something went wrong',
              style: TextStyle(color: secondaryTextColor),
            ),
          ),
        );
      },
    );
  }

  Widget _buildServiceContent(
    BuildContext context,
    ServiceEntity service,
    bool isDarkMode,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color surfaceColor,
  ) {

    return Scaffold(
      backgroundColor: isDarkMode ? kBackgroundColorDark : kBackgroundColorLight,
      body: ResponsiveBuilder(
        builder: (context, screenSize) {
          return _buildSliverLayout(
            context,
            service,
            isDarkMode,
            primaryTextColor,
            secondaryTextColor,
            surfaceColor,
            screenSize,
          );
        },
      ),
    );
  }

  Widget _buildSliverLayout(
    BuildContext context,
    ServiceEntity service,
    bool isDarkMode,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color surfaceColor,
    ScreenSize screenSize,
  ) {
    final images = service.images.isNotEmpty ? service.images : [''];

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
                  style: GoogleFonts.inter(),
                ),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          // Navigate to chat with the conversation ID
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
                style: GoogleFonts.inter(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Stack(
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
            // Service info section
            SliverSection(
              child: _buildServiceInfoSliver(
                context,
                service,
                primaryTextColor,
                secondaryTextColor,
                screenSize,
              ),
            ),
            // Similar services (mid-page recommendations)
            SliverToBoxAdapter(
              child: RecommendationSection(
                currentItemId: service.id,
                type: RecommendationType.service,
                title: 'Similar Services',
                onItemTap: (itemId, type) {
                  Navigator.pushNamed(
                    context,
                    '/service-details',
                    arguments: itemId,
                  );
                },
              ),
            ),
            // Provider info section
            SliverSection(
              child: _buildProviderInfo(
                context,
                service,
                primaryTextColor,
                secondaryTextColor,
                surfaceColor,
              ),
            ),
            // Description section
            SliverSection(
              child: _buildDescriptionSliver(
                context,
                service,
                primaryTextColor,
                secondaryTextColor,
                screenSize,
              ),
            ),
            // Availability section
            if (service.availability.isNotEmpty)
              SliverSection(
                child: _buildAvailabilitySliver(
                  context,
                  service,
                  primaryTextColor,
                  secondaryTextColor,
                  surfaceColor,
                ),
              ),
            // Reviews section
            SliverSection(
              child: CommentsAndRatingsSection(
                itemId: service.id,
                itemType: 'service',
              ),
            ),
            // More recommendations (bottom)
            SliverToBoxAdapter(
              child: RecommendationSection(
                currentItemId: service.id,
                type: RecommendationType.service,
                title: 'More Recommendations',
                criteria: RecommendationCriteriaEntity(
                  limit: 8,
                ),
                onItemTap: (itemId, type) {
                  Navigator.pushNamed(
                    context,
                    '/service-details',
                    arguments: itemId,
                  );
                },
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
              price: 'TZS ${service.price.toStringAsFixed(2)}/${service.priceType}',
              actionButtonText: 'Contact Provider',
              onActionTap: () {
                // Handle contact provider
                context.read<MessageBloc>().add(
                      GetOrCreateConversationEvent(
                        otherUserId: service.providerId,
                        listingId: service.id,
                        listingType: 'service',
                        listingTitle: service.title,
                        listingImageUrl: service.images.isNotEmpty ? service.images.first : null,
                        listingPrice: 'TZS ${service.price.toStringAsFixed(2)}',
                        listingPriceType: service.priceType,
                      ),
                    );
              },
            ),
          ),
      ],
      ),
    );
  }

  Widget _buildServiceInfoSliver(
    BuildContext context,
    ServiceEntity service,
    Color primaryTextColor,
    Color secondaryTextColor,
    ScreenSize screenSize,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Service Category Badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 6.0,
          ),
          decoration: BoxDecoration(
            color: kPrimaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Text(
            service.category,
            style: GoogleFonts.inter(
              color: kPrimaryColor,
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        // Service Title
        Text(
          service.title,
          style: GoogleFonts.inter(
            color: primaryTextColor,
            fontSize: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 24.0,
              medium: 28.0,
              expanded: 32.0,
            ),
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12.0),
        // Rating and Price
        Row(
          children: [
            if (service.rating != null) ...[
              Icon(Icons.star, color: Colors.amber[600], size: 20.0),
              const SizedBox(width: 4.0),
              Text(
                service.rating!.toStringAsFixed(1),
                style: GoogleFonts.inter(
                  color: primaryTextColor,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                ' (${service.reviewCount} reviews)',
                style: GoogleFonts.inter(
                  color: secondaryTextColor,
                  fontSize: 14.0,
                ),
              ),
            ],
            const Spacer(),
            Text(
              'TZS ${service.price.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                color: kPrimaryColor,
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '/${service.priceType}',
              style: GoogleFonts.inter(
                color: secondaryTextColor,
                fontSize: 14.0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionSliver(
    BuildContext context,
    ServiceEntity service,
    Color primaryTextColor,
    Color secondaryTextColor,
    ScreenSize screenSize,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About This Service',
          style: GoogleFonts.inter(
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
        const SizedBox(height: 12.0),
        Text(
          service.description,
          style: GoogleFonts.inter(
            color: secondaryTextColor,
            fontSize: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 14.0,
              medium: 15.0,
              expanded: 16.0,
            ),
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilitySliver(
    BuildContext context,
    ServiceEntity service,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color surfaceColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Availability',
          style: GoogleFonts.inter(
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
        const SizedBox(height: 12.0),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]!
                  : Colors.grey[200]!,
            ),
          ),
          child: Column(
            children: [
              ...service.availability.asMap().entries.map((entry) {
                final index = entry.key;
                final availabilityItem = entry.value;
                final parts = availabilityItem.split(':');
                final day = parts.length > 1 ? parts[0].trim() : availabilityItem;
                final time = parts.length > 1 ? parts[1].trim() : 'Available';
                
                return Column(
                  children: [
                    if (index > 0) const Divider(),
                    _buildAvailabilityRow(day, time, secondaryTextColor),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProviderInfo(
    BuildContext context,
    ServiceEntity service,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color surfaceColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]!
              : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60.0,
            height: 60.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kPrimaryColor.withValues(alpha: 0.3),
            ),
            child: ClipOval(
              child: NetworkImageWithFallback(
                imageUrl: service.providerAvatar ?? '',
                width: 60.0,
                height: 60.0,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.providerName,
                  style: GoogleFonts.inter(
                    color: primaryTextColor,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  service.location,
                  style: GoogleFonts.inter(
                    color: secondaryTextColor,
                    fontSize: 13.0,
                  ),
                ),
                const SizedBox(height: 4.0),
                if (service.rating != null && service.reviewCount != null && service.reviewCount! > 0)
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16.0),
                      const SizedBox(width: 4.0),
                      Text(
                        '${service.rating!.toStringAsFixed(1)} (${service.reviewCount} ${service.reviewCount == 1 ? 'review' : 'reviews'})',
                        style: GoogleFonts.inter(
                          color: secondaryTextColor,
                          fontSize: 13.0,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'No reviews yet',
                    style: GoogleFonts.inter(
                      color: secondaryTextColor,
                      fontSize: 13.0,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // Dispatch event - navigation will be handled by parent BlocListener
              context.read<MessageBloc>().add(
                    GetOrCreateConversationEvent(
                      otherUserId: service.providerId,
                      listingId: service.id,
                      listingType: 'service',
                      listingTitle: service.title,
                      listingImageUrl: service.images.isNotEmpty ? service.images.first : null,
                      listingPrice: 'TZS ${service.price.toStringAsFixed(2)}',
                      listingPriceType: service.priceType,
                    ),
                  );
            },
            icon: Icon(Icons.chat_bubble_outline, color: kPrimaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityRow(String day, String time, Color secondaryTextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: GoogleFonts.inter(
              color: secondaryTextColor,
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            time,
            style: GoogleFonts.inter(
              color: kPrimaryColor,
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

