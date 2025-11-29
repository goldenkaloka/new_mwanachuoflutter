import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/features/dashboard/presentation/bloc/dashboard_cubit.dart';
import 'package:mwanachuo/features/dashboard/presentation/bloc/dashboard_state.dart';

class SellerDashboardScreen extends StatelessWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<DashboardCubit>()..loadStats(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDarkMode ? kBackgroundColorDark : Colors.white,
      ),
      backgroundColor: isDarkMode
          ? kBackgroundColorDark
          : kBackgroundColorLight,
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: kPrimaryColor),
                  SizedBox(height: 16),
                  Text('Loading dashboard...'),
                ],
              ),
            );
          }

          if (state is DashboardError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<DashboardCubit>().loadStats(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: kBackgroundColorDark,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is DashboardLoaded) {
            final stats = state.stats;
            return ResponsiveBuilder(
              builder: (context, screenSize) {
                return SingleChildScrollView(
                  padding: EdgeInsets.all(
                    ResponsiveBreakpoints.responsiveHorizontalPadding(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Statistics',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: ResponsiveBreakpoints.responsiveValue(
                            context,
                            compact: 24.0,
                            medium: 28.0,
                            expanded: 32.0,
                          ),
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveBreakpoints.responsiveValue(
                          context,
                          compact: 24.0,
                          medium: 28.0,
                          expanded: 32.0,
                        ),
                      ),
                      // Responsive Stats Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: ResponsiveBreakpoints.responsiveValue(
                          context,
                          compact: 2,
                          medium: 3,
                          expanded: 4,
                        ),
                        crossAxisSpacing: ResponsiveBreakpoints.responsiveValue(
                          context,
                          compact: 12.0,
                          medium: 16.0,
                          expanded: 20.0,
                        ),
                        mainAxisSpacing: ResponsiveBreakpoints.responsiveValue(
                          context,
                          compact: 12.0,
                          medium: 16.0,
                          expanded: 20.0,
                        ),
                        childAspectRatio: ResponsiveBreakpoints.responsiveValue(
                          context,
                          compact: 1.4,
                          medium: 1.5,
                          expanded: 1.6,
                        ),
                        children: [
                          _buildStatCard(
                            context,
                            'Products',
                            '${stats.totalProducts}',
                            Icons.shopping_bag,
                            Colors.blue,
                            isDarkMode,
                          ),
                          _buildStatCard(
                            context,
                            'Services',
                            '${stats.totalServices}',
                            Icons.build,
                            kPrimaryColor,
                            isDarkMode,
                          ),
                          _buildStatCard(
                            context,
                            'Accommodations',
                            '${stats.totalAccommodations}',
                            Icons.home,
                            Colors.orange,
                            isDarkMode,
                          ),
                          _buildStatCard(
                            context,
                            'Active Listings',
                            '${stats.activeListings}',
                            Icons.check_circle,
                            kPrimaryColor,
                            isDarkMode,
                          ),
                          _buildStatCard(
                            context,
                            'Total Views',
                            '${stats.totalViews}',
                            Icons.visibility,
                            Colors.purple,
                            isDarkMode,
                          ),
                          _buildStatCard(
                            context,
                            'Average Rating',
                            stats.averageRating > 0
                                ? stats.averageRating.toStringAsFixed(1)
                                : 'N/A',
                            Icons.star,
                            Colors.amber,
                            isDarkMode,
                          ),
                          _buildStatCard(
                            context,
                            'Reviews',
                            '${stats.totalReviews}',
                            Icons.rate_review,
                            Colors.pink,
                            isDarkMode,
                          ),
                          _buildStatCard(
                            context,
                            'Unread Messages',
                            '${stats.unreadMessages}',
                            Icons.message,
                            Colors.red,
                            isDarkMode,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDarkMode,
  ) {
    return Container(
      padding: EdgeInsets.all(
        ResponsiveBreakpoints.responsiveValue(
          context,
          compact: 12.0,
          medium: 16.0,
          expanded: 20.0,
        ),
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 28.0,
              medium: 32.0,
              expanded: 36.0,
            ),
            color: color,
          ),
          SizedBox(
            height: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 6.0,
              medium: 8.0,
              expanded: 10.0,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 22.0,
                medium: 26.0,
                expanded: 30.0,
              ),
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 11.0,
                medium: 12.0,
                expanded: 13.0,
              ),
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
