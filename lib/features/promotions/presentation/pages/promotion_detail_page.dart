import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/core/widgets/network_image_with_fallback.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/features/promotions/presentation/bloc/promotion_cubit.dart';
import 'package:mwanachuo/features/promotions/presentation/bloc/promotion_state.dart';
import 'package:mwanachuo/features/promotions/domain/entities/promotion_entity.dart';

class PromotionDetailPage extends StatelessWidget {
  const PromotionDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get promotion ID from route arguments
    final promotionId = ModalRoute.of(context)?.settings.arguments as String?;

    if (promotionId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Invalid promotion ID'),
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

    return BlocProvider(
      create: (context) => sl<PromotionCubit>()..loadActivePromotions(),
      child: _PromotionDetailView(promotionId: promotionId),
    );
  }
}

class _PromotionDetailView extends StatelessWidget {
  final String promotionId;

  const _PromotionDetailView({required this.promotionId});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? Colors.white : kTextPrimary;
    final secondaryTextColor = isDarkMode
        ? Colors.grey[400]!
        : Colors.grey[600]!;

    return BlocBuilder<PromotionCubit, PromotionState>(
      builder: (context, state) {
        if (state is PromotionsLoading) {
          return Scaffold(
            backgroundColor: isDarkMode
                ? kBackgroundColorDark
                : kBackgroundColorLight,
            body: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
              ),
            ),
          );
        }

        if (state is PromotionError) {
          return Scaffold(
            backgroundColor: isDarkMode
                ? kBackgroundColorDark
                : kBackgroundColorLight,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: secondaryTextColor),
                  ),
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

        if (state is PromotionsLoaded) {
          // Find the promotion by ID
          PromotionEntity? promotion;
          try {
            promotion = state.promotions.firstWhere((p) => p.id == promotionId);
          } catch (e) {
            // Promotion not found
            return Scaffold(
              backgroundColor: isDarkMode
                  ? kBackgroundColorDark
                  : kBackgroundColorLight,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Promotion not found',
                      style: GoogleFonts.plusJakartaSans(
                        color: primaryTextColor,
                      ),
                    ),
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

          return _buildPromotionContent(
            context,
            promotion,
            isDarkMode,
            primaryTextColor,
            secondaryTextColor,
          );
        }

        return Scaffold(
          backgroundColor: isDarkMode
              ? kBackgroundColorDark
              : kBackgroundColorLight,
          body: const Center(child: Text('Something went wrong')),
        );
      },
    );
  }

  Widget _buildPromotionContent(
    BuildContext context,
    PromotionEntity promotion,
    bool isDarkMode,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return Scaffold(
      backgroundColor: isDarkMode
          ? kBackgroundColorDark
          : kBackgroundColorLight,
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
                        // Promotion Banner
                        _buildPromotionBanner(context, promotion, screenSize),

                        Padding(
                          padding: EdgeInsets.all(
                            ResponsiveBreakpoints.responsiveHorizontalPadding(
                              context,
                            ),
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

                              // Promotion Title
                              Text(
                                promotion.title,
                                style: GoogleFonts.inter(
                                  color: primaryTextColor,
                                  fontSize:
                                      ResponsiveBreakpoints.responsiveValue(
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

                              // Subtitle
                              Text(
                                promotion.subtitle,
                                style: GoogleFonts.inter(
                                  color: kPrimaryColor,
                                  fontSize:
                                      ResponsiveBreakpoints.responsiveValue(
                                        context,
                                        compact: 16.0,
                                        medium: 18.0,
                                        expanded: 20.0,
                                      ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 20.0),

                              // Validity Period
                              _buildInfoCard(
                                context,
                                'Valid Period',
                                '${DateFormat('MMM d, yyyy').format(promotion.startDate)} - ${DateFormat('MMM d, yyyy').format(promotion.endDate)}',
                                Icons.calendar_today,
                                secondaryTextColor,
                              ),

                              const SizedBox(height: 24.0),

                              // Description
                              if (promotion.description.isNotEmpty)
                                Text(
                                  'About This Promotion',
                                  style: GoogleFonts.inter(
                                    color: primaryTextColor,
                                    fontSize:
                                        ResponsiveBreakpoints.responsiveValue(
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
                                'Kick off the new academic year with amazing deals! Save big on textbooks, electronics, stationery, and more. Whether you need a new laptop, study materials, or dorm essentials, we\'ve got you covered with unbeatable prices.\n\nDon\'t miss out on this limited-time offer. Shop now and make this semester your best one yet!',
                                style: GoogleFonts.inter(
                                  color: secondaryTextColor,
                                  fontSize:
                                      ResponsiveBreakpoints.responsiveValue(
                                        context,
                                        compact: 14.0,
                                        medium: 15.0,
                                        expanded: 16.0,
                                      ),
                                  height: 1.6,
                                ),
                              ),

                              const SizedBox(height: 32.0),

                              // Terms & Conditions
                              Text(
                                'Terms & Conditions',
                                style: GoogleFonts.inter(
                                  color: primaryTextColor,
                                  fontSize:
                                      ResponsiveBreakpoints.responsiveValue(
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
                                'Valid for selected items only',
                                'Cannot be combined with other offers',
                                'While stocks last',
                                'University ID required for verification',
                              ].map(
                                (term) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '• ',
                                        style: GoogleFonts.inter(
                                          color: secondaryTextColor,
                                          fontSize: 14.0,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          term,
                                          style: GoogleFonts.inter(
                                            color: secondaryTextColor,
                                            fontSize: 14.0,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
              _buildBottomCTA(context, screenSize),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopAppBar(
    BuildContext context,
    Color primaryTextColor,
    ScreenSize screenSize,
  ) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(
      context,
    );
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
              'Promotion Details',
              style: GoogleFonts.inter(
                color: primaryTextColor,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
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

  Widget _buildPromotionBanner(
    BuildContext context,
    PromotionEntity promotion,
    ScreenSize screenSize,
  ) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: NetworkImageWithFallback(
        imageUrl: promotion.imageUrl ?? '',
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color secondaryTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: kPrimaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryColor, size: 24.0),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: secondaryTextColor,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    color: kPrimaryColor,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCTA(BuildContext context, ScreenSize screenSize) {
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
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/all-products');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
            ),
            child: Text(
              'Shop Now',
              style: GoogleFonts.inter(
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
