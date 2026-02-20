import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/core/utils/time_formatter.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';
import 'package:mwanachuo/features/dashboard/presentation/bloc/dashboard_cubit.dart';
import 'package:mwanachuo/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:mwanachuo/features/subscriptions/presentation/cubit/subscription_cubit.dart';
import 'package:mwanachuo/features/subscriptions/presentation/cubit/subscription_state.dart';
import 'package:mwanachuo/core/widgets/app_background.dart';
import 'package:mwanachuo/core/widgets/shimmer_loading.dart';
import 'package:mwanachuo/features/wallet/presentation/bloc/wallet_bloc.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get current user from AuthBloc
    final authState = context.read<AuthBloc>().state;
    final userId = authState is Authenticated ? authState.user.id : null;
    final userType = authState is Authenticated
        ? authState.user.userType
        : null;

    // Only load subscription for business users
    final isBusinessUser = userType == 'business';

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<DashboardCubit>()..loadStats()),
        // Only create SubscriptionCubit for business users
        if (isBusinessUser)
          BlocProvider(
            create: (context) =>
                sl<SubscriptionCubit>()..loadSellerSubscription(userId ?? ''),
          ),
        BlocProvider(
          create: (context) => sl<WalletBloc>()..add(LoadWalletData()),
        ),
      ],
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
    // Seller check removed
  }

  // Seller check method removed

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Get user type to conditionally show subscription banner
    final authState = context.watch<AuthBloc>().state;
    final isBusinessUser =
        authState is Authenticated && authState.user.userType == 'business';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: AppBackground(
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const DashboardSkeleton();
            }

            if (state is DashboardError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<DashboardCubit>().loadStats(),
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

                        // Subscription Status Banner - Only for business users
                        if (isBusinessUser)
                          BlocBuilder<SubscriptionCubit, SubscriptionState>(
                            builder: (context, subscriptionState) {
                              if (subscriptionState is SubscriptionTrial) {
                                final subscription =
                                    subscriptionState.subscription;
                                final daysLeft = subscription.currentPeriodEnd
                                    .difference(DateTime.now())
                                    .inDays;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        kPrimaryColor.withValues(alpha: 0.15),
                                        kPrimaryColor.withValues(alpha: 0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: kPrimaryColor.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.celebration,
                                        color: kPrimaryColor,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '🎉 Free Trial Active',
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: primaryTextColor,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '$daysLeft days left • Expires ${DateFormat('MMM d, yyyy').format(subscription.currentPeriodEnd)}',
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: secondaryTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/subscription-plans',
                                          );
                                        },
                                        child: Text(
                                          'Upgrade',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            color: kPrimaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              } else if (subscriptionState
                                  is SubscriptionExpired) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.orange.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.orange,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Subscription Expired',
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: primaryTextColor,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Renew to continue posting listings',
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: secondaryTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/subscription-plans',
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: Text(
                                          'Renew',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),

                        // Use BlocListener for side effects like snackbars
                        BlocListener<WalletBloc, WalletState>(
                          listener: (context, state) {
                            if (state is WalletTopUpFailure) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Top Up Failed: ${state.message}',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } else if (state is WalletTopUpInitiated) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Payment initiated! Check your phone for the prompt.',
                                  ),
                                  backgroundColor: kPrimaryColor,
                                ),
                              );
                            }
                          },
                          child: BlocBuilder<WalletBloc, WalletState>(
                            builder: (context, walletState) {
                              // Debug: Print current state
                              debugPrint(
                                'Dashboard - WalletState: $walletState',
                              );

                              if (walletState is WalletLoading) {
                                // Show skeleton loader while loading
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        kPrimaryColor,
                                        kPrimaryColorDark,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }

                              if (walletState is WalletError) {
                                // Show error state
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.red.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.red,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Failed to load wallet',
                                        style: GoogleFonts.inter(
                                          color: primaryTextColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        walletState.message,
                                        style: GoogleFonts.inter(
                                          color: secondaryTextColor,
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      TextButton(
                                        onPressed: () {
                                          context.read<WalletBloc>().add(
                                            LoadWalletData(),
                                          );
                                        },
                                        child: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              // Check for any state that contains a wallet
                              final wallet = walletState is WalletLoaded
                                  ? walletState.wallet
                                  : walletState is WalletTopUpInitiated
                                  ? walletState.wallet
                                  : walletState is WalletTopUpFailure
                                  ? walletState.wallet
                                  : null;

                              if (wallet != null) {
                                final currencyFormat = NumberFormat.currency(
                                  symbol: 'TZS ',
                                  decimalDigits: 0,
                                );
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        kPrimaryColor,
                                        kPrimaryColorDark,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: kPrimaryColor.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Wallet Balance',
                                                style: GoogleFonts.inter(
                                                  color: Colors.white70,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                currencyFormat.format(
                                                  wallet.balance,
                                                ),
                                                style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: () =>
                                                _showTopUpDialog(context),
                                            icon: const Icon(
                                              Icons.add,
                                              size: 18,
                                            ),
                                            label: const Text('Top Up'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: kPrimaryColor,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 10,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      TextButton.icon(
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/wallet',
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.history,
                                          color: Colors.white70,
                                          size: 16,
                                        ),
                                        label: Text(
                                          'View Transactions',
                                          style: GoogleFonts.inter(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ), // Quick Stats
                        Text(
                          'Quick Stats',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                            letterSpacing: -0.015,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildQuickStats(
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
      ),
    );
  }

  Widget _buildQuickStats(
    BuildContext context,
    dynamic stats,
    Color cardBgColor,
    Color borderColor,
    Color primaryTextColor,
    Color secondaryTextColor,
    bool isDarkMode,
  ) {
    // Format times using TimeFormatter
    final lastMessageTimeStr = stats.lastMessageTime != null
        ? TimeFormatter.formatConversationTime(stats.lastMessageTime)
        : 'No messages';

    final lastListingTimeStr = stats.lastListingUpdateTime != null
        ? TimeFormatter.formatConversationTime(stats.lastListingUpdateTime)
        : 'No listings';

    final lastReviewTimeStr = stats.lastReviewTime != null
        ? TimeFormatter.formatConversationTime(stats.lastReviewTime)
        : 'No reviews';

    final activities = [
      {
        'icon': Icons.mail,
        'title': 'New messages',
        'subtitle': 'You have ${stats.unreadMessages} unread messages',
        'time': lastMessageTimeStr,
        'route': '/messages',
      },
      {
        'icon': Icons.inventory_2,
        'title': 'Active Listings',
        'subtitle': '${stats.activeListings} items currently listed',
        'time': lastListingTimeStr,
        'route': '/my-listings',
      },
      {
        'icon': Icons.star,
        'title': 'Average Rating',
        'subtitle': stats.averageRating > 0
            ? '${stats.averageRating.toStringAsFixed(1)} stars'
            : 'No reviews yet',
        'time': lastReviewTimeStr,
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
            onTap: () {
              if (activity['route'] == '/messages') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Messages feature is coming soon!',
                      style: GoogleFonts.plusJakartaSans(),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else if (activity['route'] != null) {
                Navigator.pushNamed(context, activity['route'] as String);
              }
            },
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
                      color: isDarkMode ? kPrimaryColor : kPrimaryColor,
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
                '${stats.totalProducts}',
                'Products',
                primaryTextColor,
                secondaryTextColor,
              ),
              _buildSummaryItem(
                '${stats.totalServices}',
                'Services',
                primaryTextColor,
                secondaryTextColor,
              ),
              _buildSummaryItem(
                '${stats.activeListings}',
                'Active',
                primaryTextColor,
                secondaryTextColor,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/my-listings'),
              icon: const Icon(Icons.inventory_2, size: 20),
              label: Text(
                'Manage Listings',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30), // Fully rounded
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
    // Listen to AuthBloc state changes to ensure role updates trigger rebuilds
    final authState = context.watch<AuthBloc>().state;

    // Debug print to verify role
    if (authState is Authenticated) {
      debugPrint(
        'Admin Check - Role: ${authState.user.role.value}, Is Admin: ${authState.user.role.value == 'admin'}',
      );
    }

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
      if (authState is Authenticated && authState.user.role.value == 'admin')
        {
          'icon': Icons.campaign_outlined,
          'label': 'Create Promo',
          'route': '/create-promotion',
        },
      // DEBUG: Temporarily allowing access to everyone to verify UI exists
      // if (authState is Authenticated &&
      //     (authState).user.role.value == 'admin')
      {
        'icon': Icons.auto_awesome,
        'label': 'Manage AI',
        'route': '/admin-courses',
      },
      // Upload Note - only show if user has enrolled in a course
      if (authState is Authenticated && authState.user.enrolledCourseId != null)
        {
          'icon': Icons.upload_file,
          'label': 'Upload Note',
          'route': '/copilot-upload',
          'requiresCourseId': true,
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
          onTap: () {
            final route = action['route'] as String;
            final requiresCourseId =
                action['requiresCourseId'] as bool? ?? false;

            if (requiresCourseId && authState is Authenticated) {
              Navigator.pushNamed(
                context,
                route,
                arguments: {'courseId': authState.user.enrolledCourseId},
              );
            } else {
              Navigator.pushNamed(context, route);
            }
          },
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

  void _showTopUpDialog(BuildContext context) {
    final walletBloc = context.read<WalletBloc>();
    final phoneController = TextEditingController();
    final amountController = TextEditingController();
    String? selectedProvider;

    final providers = [
      {'label': 'mixx by yass', 'value': 'TIGOPESA'},
      {'label': 'Vodacom', 'value': 'M-PESA'},
      {'label': 'Airtel', 'value': 'AIRTEL MONEY'},
      {'label': 'Halopesa', 'value': 'HALOPESA'},
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (stateContext, setState) => AlertDialog(
          title: const Text('Top Up Wallet'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedProvider,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Provider',
                    border: OutlineInputBorder(),
                  ),
                  items: providers.map((provider) {
                    return DropdownMenuItem(
                      value: provider['value'],
                      child: Text(provider['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedProvider = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '0712345678',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount (TZS)',
                    hintText: 'Min: 1,000',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final phone = phoneController.text.trim();
                final amountText = amountController.text.trim();
                final amount = double.tryParse(amountText);

                if (selectedProvider == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a mobile provider'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                if (phone.isEmpty || !RegExp(r'^0[67]\d{8}$').hasMatch(phone)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Invalid phone number (use format: 07XXXXXXXX)',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                if (amount == null || amount < 1000) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Minimum top-up amount is 1,000 TZS'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext);
                walletBloc.add(
                  InitiateWalletTopUp(
                    amount: amount,
                    phone: phoneController.text.replaceAll(RegExp(r'\s+'), ''),
                    provider: selectedProvider!,
                  ),
                );
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}
