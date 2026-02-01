import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/core/widgets/comments_and_ratings_section.dart';
import 'package:mwanachuo/core/widgets/sliver_image_carousel.dart';
import 'package:mwanachuo/core/widgets/sliver_section.dart';
import 'package:mwanachuo/core/widgets/sticky_action_bar.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_bloc.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_event.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_state.dart';
import 'package:mwanachuo/features/accommodations/domain/entities/accommodation_entity.dart';
import 'package:mwanachuo/features/shared/reviews/presentation/cubit/review_cubit.dart';
import 'package:mwanachuo/features/shared/reviews/domain/entities/review_entity.dart';
import 'package:mwanachuo/core/utils/whatsapp_contact_helper.dart';

class AccommodationDetailPage extends StatelessWidget {
  const AccommodationDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get accommodation ID from route arguments
    final accommodationId =
        ModalRoute.of(context)?.settings.arguments as String?;

    if (accommodationId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Invalid accommodation ID'),
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
          create: (context) => sl<AccommodationBloc>()
            ..add(LoadAccommodationByIdEvent(accommodationId: accommodationId)),
        ),
        BlocProvider(
          create: (context) => sl<ReviewCubit>()
            ..loadReviewsWithStats(
              itemId: accommodationId,
              itemType: ReviewType.accommodation,
              limit: 10,
            ),
        ),
      ],
      child: const _AccommodationDetailView(),
    );
  }
}

class _AccommodationDetailView extends StatefulWidget {
  const _AccommodationDetailView();

  @override
  State<_AccommodationDetailView> createState() =>
      _AccommodationDetailViewState();
}

class _AccommodationDetailViewState extends State<_AccommodationDetailView> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? Colors.white : kTextPrimary;
    final secondaryTextColor = isDarkMode
        ? Colors.grey[400]!
        : Colors.grey[600]!;
    final surfaceColor = isDarkMode ? Colors.grey[900]! : Colors.white;

    return BlocBuilder<AccommodationBloc, AccommodationState>(
      builder: (context, state) {
        if (state is AccommodationLoading) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: kPrimaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'Loading accommodation...',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is AccommodationError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load accommodation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: secondaryTextColor),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: kBackgroundColorDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is AccommodationLoaded) {
          final accommodation = state.accommodation;
          return _buildAccommodationContent(
            context,
            accommodation,
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

  Widget _buildAccommodationContent(
    BuildContext context,
    AccommodationEntity accommodation,
    bool isDarkMode,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color surfaceColor,
  ) {
    return Scaffold(
      backgroundColor: isDarkMode
          ? kBackgroundColorDark
          : kBackgroundColorLight,
      body: ResponsiveBuilder(
        builder: (context, screenSize) {
          return _buildSliverLayout(
            context,
            accommodation,
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
    AccommodationEntity accommodation,
    bool isDarkMode,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color surfaceColor,
    ScreenSize screenSize,
  ) {
    final images = accommodation.images.isNotEmpty
        ? accommodation.images
        : [''];

    return Stack(
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
                    icon: const Icon(
                      Icons.favorite_border,
                      color: Colors.white,
                    ),
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
            // Accommodation info section
            SliverSection(
              child: _buildAccommodationInfoSliver(
                context,
                accommodation,
                primaryTextColor,
                secondaryTextColor,
                screenSize,
              ),
            ),
            // Owner info section
            SliverSection(
              child: _buildOwnerInfo(
                context,
                accommodation,
                primaryTextColor,
                secondaryTextColor,
                surfaceColor,
              ),
            ),
            // Description section
            SliverSection(
              child: _buildDescriptionSliver(
                context,
                accommodation,
                primaryTextColor,
                secondaryTextColor,
                screenSize,
              ),
            ),
            // Amenities section
            if (accommodation.amenities.isNotEmpty)
              SliverSection(
                child: _buildAmenitiesSliver(
                  context,
                  accommodation,
                  primaryTextColor,
                  secondaryTextColor,
                  surfaceColor,
                ),
              ),
            // Reviews section
            SliverSection(
              child: CommentsAndRatingsSection(
                itemId: accommodation.id,
                itemType: 'accommodation',
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
              price:
                  'TZS ${accommodation.price.toStringAsFixed(2)}/${accommodation.priceType}',
              actionButtonText: 'Contact Owner',
              onActionTap: () {
                final itemUrl =
                    'https://www.mwanachuoshop.com/accommodations/${accommodation.id}';
                WhatsAppContactHelper.contactSeller(
                  context: context,
                  phoneNumber: accommodation.contactPhone,
                  message:
                      'Habari ${accommodation.ownerName}, nimevutiwa na ${accommodation.name} ulichoweka Mwanachuoshop kwa bei ya ${accommodation.price.toStringAsFixed(0)}/=.\n\nAngalia hapa: $itemUrl\n\nJe tunaweza kuongea zaidi?',
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAccommodationInfoSliver(
    BuildContext context,
    AccommodationEntity accommodation,
    Color primaryTextColor,
    Color secondaryTextColor,
    ScreenSize screenSize,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Room type badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: kPrimaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Text(
            accommodation.roomType,
            style: GoogleFonts.inter(
              color: kPrimaryColor,
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        // Title
        Text(
          accommodation.name,
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
            if (accommodation.rating != null) ...[
              Icon(Icons.star, color: Colors.amber[600], size: 20.0),
              const SizedBox(width: 4.0),
              Text(
                accommodation.rating!.toStringAsFixed(1),
                style: GoogleFonts.inter(
                  color: primaryTextColor,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                ' (${accommodation.reviewCount} reviews)',
                style: GoogleFonts.inter(
                  color: secondaryTextColor,
                  fontSize: 14.0,
                ),
              ),
            ],
            const Spacer(),
            Text(
              'TZS ${accommodation.price.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                color: kPrimaryColor,
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '/${accommodation.priceType}',
              style: GoogleFonts.inter(
                color: secondaryTextColor,
                fontSize: 14.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        // Location
        Row(
          children: [
            Icon(Icons.location_on, color: kPrimaryColor, size: 20.0),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                accommodation.location,
                style: GoogleFonts.inter(
                  color: secondaryTextColor,
                  fontSize: 14.0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        // Room details
        Row(
          children: [
            if (accommodation.bedrooms > 0) ...[
              Icon(Icons.bed, color: primaryTextColor, size: 20.0),
              const SizedBox(width: 4.0),
              Text(
                '${accommodation.bedrooms} Bed${accommodation.bedrooms > 1 ? 's' : ''}',
                style: GoogleFonts.inter(
                  color: secondaryTextColor,
                  fontSize: 14.0,
                ),
              ),
              const SizedBox(width: 16.0),
            ],
            if (accommodation.bathrooms > 0) ...[
              Icon(Icons.bathroom, color: primaryTextColor, size: 20.0),
              const SizedBox(width: 4.0),
              Text(
                '${accommodation.bathrooms} Bath${accommodation.bathrooms > 1 ? 's' : ''}',
                style: GoogleFonts.inter(
                  color: secondaryTextColor,
                  fontSize: 14.0,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionSliver(
    BuildContext context,
    AccommodationEntity accommodation,
    Color primaryTextColor,
    Color secondaryTextColor,
    ScreenSize screenSize,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About This Accommodation',
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
          accommodation.description,
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

  Widget _buildAmenitiesSliver(
    BuildContext context,
    AccommodationEntity accommodation,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color surfaceColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amenities',
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
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: accommodation.amenities.map((amenity) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]!
                      : Colors.grey[200]!,
                ),
              ),
              child: Text(
                amenity,
                style: GoogleFonts.inter(
                  color: secondaryTextColor,
                  fontSize: 14.0,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOwnerInfo(
    BuildContext context,
    AccommodationEntity accommodation,
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
          CircleAvatar(
            radius: 30.0,
            backgroundColor: kPrimaryColor.withValues(alpha: 0.2),
            backgroundImage:
                accommodation.ownerAvatar != null &&
                    accommodation.ownerAvatar!.isNotEmpty
                ? NetworkImage(accommodation.ownerAvatar!)
                : null,
            child:
                accommodation.ownerAvatar == null ||
                    accommodation.ownerAvatar!.isEmpty
                ? Text(
                    accommodation.ownerName.isNotEmpty
                        ? accommodation.ownerName[0].toUpperCase()
                        : 'O',
                    style: GoogleFonts.inter(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Property Owner',
                  style: GoogleFonts.inter(
                    color: secondaryTextColor,
                    fontSize: 12.0,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  accommodation.ownerName,
                  style: GoogleFonts.inter(
                    color: primaryTextColor,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4.0),
                Row(
                  children: [
                    Icon(Icons.verified, color: Colors.blue, size: 14.0),
                    const SizedBox(width: 4.0),
                    Text(
                      'Verified',
                      style: GoogleFonts.inter(
                        color: secondaryTextColor,
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              final itemUrl =
                  'https://www.mwanachuoshop.com/accommodations/${accommodation.id}';
              WhatsAppContactHelper.contactSeller(
                context: context,
                phoneNumber: accommodation.contactPhone,
                message:
                    'Habari ${accommodation.ownerName}, nimevutiwa na ${accommodation.name} ulichoweka Mwanachuoshop kwa bei ya ${accommodation.price.toStringAsFixed(0)}/=.\n\nAngalia hapa: $itemUrl\n\nJe tunaweza kuongea zaidi?',
              );
            },
            icon: Icon(Icons.chat_bubble_outline, color: kPrimaryColor),
          ),
        ],
      ),
    );
  }
}
