import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';
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

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  @override
  void initState() {
    super.initState();
    _checkSellerAccess();
  }

  void _checkSellerAccess() {
    // Verify user is seller or admin
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        final userRole = authState.user.role.value;
        
        if (userRole == 'buyer') {
          debugPrint('❌ Buyer attempting to access dashboard - redirecting');
          Navigator.of(context).pushReplacementNamed('/home');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You need to become a seller to access the dashboard',
                style: GoogleFonts.plusJakartaSans(),
              ),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Request Access',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.pushNamed(context, '/become-seller');
                },
              ),
            ),
          );
        }
      }
    });
  }

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
                final primaryTextColor = isDarkMode
                    ? Colors.white
                    : const Color(0xFF111814);
                final secondaryTextColor = isDarkMode
                    ? Colors.grey[400]!
                    : Colors.grey[600]!;
                final cardBgColor = isDarkMode
                    ? kBackgroundColorDark
                    : Colors.white;
                final borderColor = isDarkMode
                    ? Colors.grey[700]!
                    : Colors.grey[200]!;

                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: ResponsiveBreakpoints.responsiveHorizontalPadding(
                      context,
                    ),
                    right: ResponsiveBreakpoints.responsiveHorizontalPadding(
                      context,
                    ),
                    bottom: 100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      // Sales Analytics Header
                      Text(
                        'Sales Analytics',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                          letterSpacing: -0.015,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Quick Stats Cards
                      ResponsiveBreakpoints.isCompact(context)
                          ? Column(
                              children: [
                                _buildQuickStatCard(
                                  'Total Earnings',
                                  '\$${(stats.totalViews * 0.5).toStringAsFixed(2)}',
                                  '+15.2%',
                                  cardBgColor,
                                  borderColor,
                                  primaryTextColor,
                                  secondaryTextColor,
                                ),
                                const SizedBox(height: 16),
                                _buildQuickStatCard(
                                  'Items Sold',
                                  '${stats.totalProducts + stats.totalServices}',
                                  '+8.1%',
                                  cardBgColor,
                                  borderColor,
                                  primaryTextColor,
                                  secondaryTextColor,
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _buildQuickStatCard(
                                    'Total Earnings',
                                    '\$${(stats.totalViews * 0.5).toStringAsFixed(2)}',
                                    '+15.2%',
                                    cardBgColor,
                                    borderColor,
                                    primaryTextColor,
                                    secondaryTextColor,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildQuickStatCard(
                                    'Items Sold',
                                    '${stats.totalProducts + stats.totalServices}',
                                    '+8.1%',
                                    cardBgColor,
                                    borderColor,
                                    primaryTextColor,
                                    secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),

                      const SizedBox(height: 24),

                      // Recent Activity
                      Text(
                        'Recent Activity',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                          letterSpacing: -0.015,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildRecentActivity(
                        context,
                        stats,
                        cardBgColor,
                        borderColor,
                        primaryTextColor,
                        secondaryTextColor,
                        isDarkMode,
                      ),

                      const SizedBox(height: 24),

                      // Listings Summary
                      _buildListingsSummary(
                        context,
                        stats,
                        cardBgColor,
                        borderColor,
                        primaryTextColor,
                        secondaryTextColor,
                      ),

                      const SizedBox(height: 24),

                      // Quick Actions
                      Text(
                        'Quick Actions',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                          letterSpacing: -0.015,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildQuickActions(
                        context,
                        cardBgColor,
                        borderColor,
                        primaryTextColor,
                        secondaryTextColor,
                        isDarkMode,
                      ),

                      const SizedBox(height: 24),
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

  Widget _buildQuickStatCard(
    String label,
    String value,
    String change,
    Color cardBgColor,
    Color borderColor,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            change,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF078829),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(
    BuildContext context,
    dynamic stats,
    Color cardBgColor,
    Color borderColor,
    Color primaryTextColor,
    Color secondaryTextColor,
    bool isDarkMode,
  ) {
    final activities = [
      {
        'icon': Icons.mail,
        'title': 'New messages',
        'subtitle': 'You have ${stats.unreadMessages} unread messages',
        'time': '5m ago',
        'route': '/messages',
      },
      {
        'icon': Icons.inventory_2,
        'title': 'Active Listings',
        'subtitle': '${stats.activeListings} items currently listed',
        'time': '1h ago',
        'route': '/my-listings',
      },
      {
        'icon': Icons.star,
        'title': 'Average Rating',
        'subtitle': stats.averageRating > 0
            ? '${stats.averageRating.toStringAsFixed(1)} stars'
            : 'No reviews yet',
        'time': '3h ago',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: activities.asMap().entries.map((entry) {
          final index = entry.key;
          final activity = entry.value;
          return InkWell(
            onTap: activity['route'] != null
                ? () =>
                      Navigator.pushNamed(context, activity['route'] as String)
                : null,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: index < activities.length - 1
                    ? Border(bottom: BorderSide(color: borderColor))
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      activity['icon'] as IconData,
                      color: isDarkMode
                          ? kPrimaryColor
                          : const Color(0xFF078829),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity['title'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activity['subtitle'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    activity['time'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[500]! : Colors.grey[400]!,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListingsSummary(
    BuildContext context,
    dynamic stats,
    Color cardBgColor,
    Color borderColor,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Listings',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                '${stats.activeListings}',
                'Active',
                primaryTextColor,
                secondaryTextColor,
              ),
              _buildSummaryItem(
                '${stats.totalProducts + stats.totalServices - stats.activeListings}',
                'Sold Out',
                primaryTextColor,
                secondaryTextColor,
              ),
              _buildSummaryItem(
                '0',
                'Drafts',
                primaryTextColor,
                secondaryTextColor,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/my-listings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Manage Listings',
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

  Widget _buildSummaryItem(
    String value,
    String label,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: secondaryTextColor),
        ),
      ],
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    Color cardBgColor,
    Color borderColor,
    Color primaryTextColor,
    Color secondaryTextColor,
    bool isDarkMode,
  ) {
    final actions = [
      {
        'icon': Icons.add_circle_outline,
        'label': 'Post Product',
        'route': '/post-product',
      },
      {
        'icon': Icons.build_circle_outlined,
        'label': 'Add Service',
        'route': '/create-service',
      },
      {
        'icon': Icons.home_outlined,
        'label': 'List Housing',
        'route': '/create-accommodation',
      },
      {
        'icon': Icons.campaign_outlined,
        'label': 'Create Promo',
        'route': '/create-promotion',
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: actions.map((action) {
        return InkWell(
          onTap: () => Navigator.pushNamed(context, action['route'] as String),
          child: Container(
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  action['icon'] as IconData,
                  color: kPrimaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  action['label'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
