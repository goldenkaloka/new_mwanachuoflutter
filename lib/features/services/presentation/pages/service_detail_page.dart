import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/core/widgets/network_image_with_fallback.dart';
import 'package:mwanachuo/core/widgets/comments_and_ratings_section.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_bloc.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_event.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_state.dart';
import 'package:mwanachuo/features/services/domain/entities/service_entity.dart';
import 'package:mwanachuo/features/shared/reviews/presentation/cubit/review_cubit.dart';
import 'package:mwanachuo/features/shared/reviews/domain/entities/review_entity.dart';
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
    final primaryTextColor = isDarkMode ? Colors.white : kTextPrimary;
    final secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final surfaceColor = isDarkMode ? Colors.grey[900]! : Colors.white;

    return BlocBuilder<ServiceBloc, ServiceState>(
      builder: (context, state) {
        if (state is ServiceLoading) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: kPrimaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'Loading service...',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is ServiceError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load service',
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
                        // Service Image
                        _buildServiceImage(context, service, screenSize),
                        
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
                                    '\$${service.price.toStringAsFixed(2)}',
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
                              
                              const SizedBox(height: 24.0),
                              
                              // Provider Info
                              _buildProviderInfo(
                                context,
                                service,
                                primaryTextColor,
                                secondaryTextColor,
                                surfaceColor,
                              ),
                              
                              const SizedBox(height: 24.0),
                              
                              // Description
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
                                'Get personalized mathematics tutoring from a certified tutor with 5+ years of experience. I specialize in calculus, algebra, statistics, and geometry. Whether you\'re struggling with homework or preparing for exams, I\'m here to help you succeed.\n\nSessions are conducted online or in-person, depending on your preference. I use interactive teaching methods and provide custom study materials tailored to your learning style.',
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
                              
                              // What's Included
                              Text(
                                'What\'s Included',
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
                              
                              ...[
                                'One-on-one tutoring sessions',
                                'Custom study materials',
                                'Homework help and exam preparation',
                                'Flexible scheduling',
                                'Progress tracking and reports',
                              ].map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 20.0,
                                    ),
                                    const SizedBox(width: 12.0),
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: GoogleFonts.inter(
                                          color: primaryTextColor,
                                          fontSize: 14.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                              
                              const SizedBox(height: 24.0),
                              
                              // Availability
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
                                    _buildAvailabilityRow('Monday - Friday', '3:00 PM - 9:00 PM', secondaryTextColor),
                                    const Divider(),
                                    _buildAvailabilityRow('Saturday', '10:00 AM - 6:00 PM', secondaryTextColor),
                                    const Divider(),
                                    _buildAvailabilityRow('Sunday', 'By Appointment', secondaryTextColor),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 32.0),
                              
                              // Comments and Ratings
                              CommentsAndRatingsSection(
                                itemId: service.id,
                                itemType: 'service',
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
              _buildBottomCTA(context, service, screenSize),
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
              'Service Details',
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

  Widget _buildServiceImage(BuildContext context, ServiceEntity service, ScreenSize screenSize) {
    final imageUrl = service.images.isNotEmpty ? service.images.first : '';
    
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: NetworkImageWithFallback(
        imageUrl: imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      ),
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
          BlocListener<MessageBloc, MessageState>(
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
            child: IconButton(
              onPressed: () {
                context.read<MessageBloc>().add(
                      GetOrCreateConversationEvent(
                        otherUserId: service.providerId,
                      ),
                    );
              },
              icon: Icon(Icons.chat_bubble_outline, color: kPrimaryColor),
            ),
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

  Widget _buildBottomCTA(BuildContext context, ServiceEntity service, ScreenSize screenSize) {
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
        child: SizedBox(
          width: double.infinity,
          height: 56.0,
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
                        otherUserId: service.providerId,
                      ),
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
              ),
              child: Text(
                'Contact Provider',
                style: GoogleFonts.inter(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

