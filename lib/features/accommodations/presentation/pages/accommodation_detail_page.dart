import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/core/widgets/network_image_with_fallback.dart';
import 'package:mwanachuo/core/widgets/comments_and_ratings_section.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_bloc.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_event.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_state.dart';
import 'package:mwanachuo/features/accommodations/domain/entities/accommodation_entity.dart';
import 'package:mwanachuo/features/shared/reviews/presentation/cubit/review_cubit.dart';
import 'package:mwanachuo/features/shared/reviews/domain/entities/review_entity.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/message_bloc.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/message_event.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/message_state.dart';

class AccommodationDetailPage extends StatelessWidget {
  const AccommodationDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get accommodation ID from route arguments
    final accommodationId = ModalRoute.of(context)?.settings.arguments as String?;

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
        BlocProvider(
          create: (context) => sl<MessageBloc>(),
        ),
      ],
      child: const _AccommodationDetailView(),
    );
  }
}

class _AccommodationDetailView extends StatefulWidget {
  const _AccommodationDetailView();

  @override
  State<_AccommodationDetailView> createState() => _AccommodationDetailViewState();
}

class _AccommodationDetailViewState extends State<_AccommodationDetailView> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? Colors.white : kTextPrimary;
    final secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
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
      backgroundColor: isDarkMode ? kBackgroundColorDark : kBackgroundColorLight,
      body: ResponsiveBuilder(
        builder: (context, screenSize) {
          return Column(
            children: [
              // Top App Bar
              _buildTopAppBar(context, primaryTextColor, screenSize),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: ResponsiveContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image Gallery
                        _buildImageGallery(context, accommodation, screenSize),
                        
                        Padding(
                          padding: EdgeInsets.all(
                            ResponsiveBreakpoints.responsiveHorizontalPadding(context),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: ResponsiveBreakpoints.responsiveValue(
                                  context,
                                  compact: 20.0,
                                  medium: 24.0,
                                  expanded: 28.0,
                                ),
                              ),
                              
                              // Room Type Badge
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
                                  accommodation.roomType,
                                  style: GoogleFonts.inter(
                                    color: kPrimaryColor,
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 16.0),
                              
                              // Property Title
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
                              
                              // Location and Rating
                              Row(
                                children: [
                                  Icon(Icons.location_on, color: secondaryTextColor, size: 18.0),
                                  const SizedBox(width: 4.0),
                                  Expanded(
                                    child: Text(
                                      '2km from Main Gate',
                                      style: GoogleFonts.inter(
                                        color: secondaryTextColor,
                                        fontSize: 14.0,
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.star, color: Colors.amber[600], size: 18.0),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    '4.7',
                                    style: GoogleFonts.inter(
                                      color: primaryTextColor,
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    ' (18)',
                                    style: GoogleFonts.inter(
                                      color: secondaryTextColor,
                                      fontSize: 13.0,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 20.0),
                              
                              // Price
                              Row(
                                children: [
                                  Text(
                                    '\$350',
                                    style: GoogleFonts.inter(
                                      color: kPrimaryColor,
                                      fontSize: 32.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '/month',
                                    style: GoogleFonts.inter(
                                      color: secondaryTextColor,
                                      fontSize: 16.0,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 24.0),
                              
                              // Quick Stats
                              _buildQuickStats(
                                context,
                                primaryTextColor,
                                secondaryTextColor,
                                surfaceColor,
                              ),
                              
                              const SizedBox(height: 24.0),
                              
                              // Description
                              Text(
                                'About This Property',
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
                                'This modern studio apartment is perfect for students looking for comfort and convenience. Located just 2km from the main campus gate, you\'ll have easy access to classes while enjoying a peaceful living environment.\n\nThe fully furnished space includes a comfortable bed, study desk, wardrobe, and a private bathroom. High-speed WiFi is included in the rent. The building features 24/7 security and ample parking space.',
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
                              
                              const SizedBox(height: 24.0),
                              
                              // Amenities
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
                              
                              const SizedBox(height: 16.0),
                              
                              _buildAmenitiesGrid(
                                context,
                                primaryTextColor,
                                surfaceColor,
                              ),
                              
                              const SizedBox(height: 24.0),
                              
                              // Landlord Info
                              _buildLandlordInfo(
                                context,
                                primaryTextColor,
                                secondaryTextColor,
                                surfaceColor,
                              ),
                              
                              const SizedBox(height: 32.0),
                              
                              // Comments and Ratings
                              CommentsAndRatingsSection(
                                itemId: accommodation.id,
                                itemType: 'accommodation',
                              ),
                              
                              SizedBox(
                                height: ResponsiveBreakpoints.responsiveValue(
                                  context,
                                  compact: 100.0,
                                  medium: 80.0,
                                  expanded: 60.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Bottom CTA
              _buildBottomCTA(context, accommodation, screenSize),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context, Color primaryTextColor, ScreenSize screenSize) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        screenSize == ScreenSize.expanded ? 24.0 : 48.0,
        horizontalPadding,
        16.0,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]!
                : Colors.grey[200]!,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            iconSize: 24.0,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              'Accommodation Details',
              style: GoogleFonts.inter(
                color: primaryTextColor,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.favorite_border),
            iconSize: 24.0,
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share),
            iconSize: 24.0,
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery(BuildContext context, AccommodationEntity accommodation, ScreenSize screenSize) {
    final images = accommodation.images.isNotEmpty ? accommodation.images : [''];
    
    return Stack(
      children: [
        SizedBox(
          height: ResponsiveBreakpoints.responsiveValue(
            context,
            compact: 300.0,
            medium: 400.0,
            expanded: 500.0,
          ),
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return NetworkImageWithFallback(
                imageUrl: images[index],
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              );
            },
          ),
        ),
        
        // Image Counter
        Positioned(
          bottom: 16.0,
          right: 16.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20.0),
            ),
              child: Text(
                '${_currentImageIndex + 1}/${images.length}',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(
    BuildContext context,
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.bed, '1 Bed', primaryTextColor, secondaryTextColor),
          _buildStatItem(Icons.bathtub, '1 Bath', primaryTextColor, secondaryTextColor),
          _buildStatItem(Icons.square_foot, '400 sqft', primaryTextColor, secondaryTextColor),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, Color primaryTextColor, Color secondaryTextColor) {
    return Column(
      children: [
        Icon(icon, color: kPrimaryColor, size: 28.0),
        const SizedBox(height: 8.0),
        Text(
          label,
          style: GoogleFonts.inter(
            color: secondaryTextColor,
            fontSize: 13.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAmenitiesGrid(
    BuildContext context,
    Color primaryTextColor,
    Color surfaceColor,
  ) {
    final amenities = [
      {'icon': Icons.wifi, 'name': 'WiFi'},
      {'icon': Icons.local_parking, 'name': 'Parking'},
      {'icon': Icons.security, 'name': 'Security'},
      {'icon': Icons.kitchen, 'name': 'Kitchen'},
      {'icon': Icons.ac_unit, 'name': 'AC'},
      {'icon': Icons.water_drop, 'name': 'Water'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveBreakpoints.responsiveValue(
          context,
          compact: 3,
          medium: 4,
          expanded: 6,
        ),
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 1.2,
      ),
      itemCount: amenities.length,
      itemBuilder: (context, index) {
        final amenity = amenities[index];
        return Container(
          padding: const EdgeInsets.all(12.0),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                amenity['icon'] as IconData,
                color: kPrimaryColor,
                size: 28.0,
              ),
              const SizedBox(height: 6.0),
              Text(
                amenity['name'] as String,
                style: GoogleFonts.inter(
                  color: primaryTextColor,
                  fontSize: 12.0,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLandlordInfo(
    BuildContext context,
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
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=7'),
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
                  'Sarah Johnson',
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
              Navigator.pushNamed(context, '/messages');
            },
            icon: Icon(Icons.chat_bubble_outline, color: kPrimaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCTA(BuildContext context, AccommodationEntity accommodation, ScreenSize screenSize) {
    return Container(
      padding: EdgeInsets.all(
        ResponsiveBreakpoints.responsiveHorizontalPadding(context),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]!
                : Colors.grey[200]!,
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            OutlinedButton(
              onPressed: () {
                // Phone call functionality (optional)
                // You can implement tel: URL launcher here
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: kPrimaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              ),
              child: Icon(Icons.phone, color: kPrimaryColor),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: BlocListener<MessageBloc, MessageState>(
                listener: (context, state) {
                  if (state is ConversationLoaded) {
                    Navigator.pushNamed(
                      context,
                      '/chat',
                      arguments: state.conversation.id,
                    );
                  } else if (state is MessageError) {
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
                child: ElevatedButton(
                  onPressed: () {
                    context.read<MessageBloc>().add(
                          GetOrCreateConversationEvent(
                            otherUserId: accommodation.ownerId,
                          ),
                        );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: Text(
                    'Contact Owner',
                    style: GoogleFonts.inter(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

