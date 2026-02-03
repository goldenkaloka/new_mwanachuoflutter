import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/services/push_notification_service.dart';
import 'package:mwanachuo/core/widgets/network_image_with_fallback.dart';
import 'package:mwanachuo/core/widgets/shimmer_loading.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_event.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';
import 'package:mwanachuo/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:mwanachuo/features/profile/presentation/bloc/profile_event.dart'
    as profile_event;
import 'package:mwanachuo/features/profile/presentation/bloc/profile_state.dart'
    as profile_state;
import 'package:mwanachuo/features/profile/domain/entities/user_profile_entity.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _hasLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload profile when returning to this page (e.g., from edit screen)
    // This ensures the profile image updates after editing
    if (!_hasLoaded) {
      _hasLoaded = true;
      return; // Initial load is handled by BlocProvider
    }

    // Only reload when returning from another route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final route = ModalRoute.of(context);
        if (route != null && route.isCurrent) {
          final bloc = context.read<ProfileBloc>();
          // Only reload if not already loading and we have a loaded state
          if (bloc.state is! profile_state.ProfileLoading &&
              bloc.state is profile_state.ProfileLoaded) {
            bloc.add(profile_event.LoadMyProfileEvent());
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? Colors.white : kTextPrimary;
    final secondaryTextColor = isDarkMode ? Colors.grey[400]! : kTextSecondary;

    return BlocProvider(
      create: (context) =>
          sl<ProfileBloc>()..add(profile_event.LoadMyProfileEvent()),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Unauthenticated) {
            // User logged out successfully, navigate to login
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          } else if (state is Authenticated) {
            // User authenticated - always reload profile to ensure we have the correct user's data
            // This handles both new logins and user switches
            debugPrint(
              '🔄 User authenticated, reloading profile for user: ${state.user.id}',
            );
            context.read<ProfileBloc>().add(profile_event.LoadMyProfileEvent());
          } else if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: BlocListener<ProfileBloc, profile_state.ProfileState>(
          listener: (context, state) {
            // Reload profile when it's updated (e.g., after editing)
            if (state is profile_state.ProfileUpdated) {
              debugPrint(
                '🔄 Profile updated, reloading profile and refreshing auth state',
              );
              // Refresh AuthBloc to update user data (including avatar) in homepage
              context.read<AuthBloc>().add(const CheckAuthStatusEvent());
              context.read<ProfileBloc>().add(
                profile_event.LoadMyProfileEvent(),
              );
            }
          },
          child: BlocBuilder<ProfileBloc, profile_state.ProfileState>(
            builder: (context, state) {
              if (state is profile_state.ProfileLoading) {
                return Scaffold(
                  backgroundColor: isDarkMode
                      ? kBackgroundColorDark
                      : kBackgroundColorLight,
                  body: const ProfilePageSkeleton(),
                );
              }

              if (state is profile_state.ProfileError) {
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
                          state.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: secondaryTextColor),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<ProfileBloc>().add(
                              profile_event.LoadMyProfileEvent(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: kBackgroundColorDark,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is profile_state.ProfileLoaded) {
                return _buildProfileUI(
                  context,
                  isDarkMode,
                  primaryTextColor,
                  secondaryTextColor,
                  state.profile,
                );
              }

              return Scaffold(
                backgroundColor: isDarkMode
                    ? kBackgroundColorDark
                    : kBackgroundColorLight,
                body: const Center(child: Text('Unexpected state')),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileUI(
    BuildContext context,
    bool isDarkMode,
    Color primaryTextColor,
    Color secondaryTextColor,
    UserProfileEntity profile,
  ) {
    return Scaffold(
      backgroundColor: isDarkMode
          ? kBackgroundColorDark
          : kBackgroundColorLight,
      body: ResponsiveBuilder(
        builder: (context, screenSize) {
          return Column(
            children: [
              // Top App Bar (Sticky)
              _buildTopAppBar(
                context,
                primaryTextColor,
                isDarkMode,
                screenSize,
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom:
                        ResponsiveBreakpoints.isCompact(context) ||
                            ResponsiveBreakpoints.isMedium(context)
                        ? 80.0 // Space for bottom navbar
                        : 0.0,
                  ),
                  child: ResponsiveContainer(
                    child: Column(
                      children: [
                        // Profile Header
                        _buildProfileHeader(
                          context,
                          primaryTextColor,
                          secondaryTextColor,
                          screenSize,
                          profile,
                        ),

                        // Content Section
                        Column(
                          children: [
                            // Navigation List Group
                            _buildNavigationList(
                              context,
                              primaryTextColor,
                              secondaryTextColor,
                              isDarkMode,
                              screenSize,
                              profile,
                            ),

                            SizedBox(
                              height: ResponsiveBreakpoints.responsiveValue(
                                context,
                                compact: 16.0,
                                medium: 20.0,
                                expanded: 24.0,
                              ),
                            ),

                            // Logout Button
                            _buildLogoutButton(context, isDarkMode, screenSize),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopAppBar(
    BuildContext context,
    Color primaryTextColor,
    bool isDarkMode,
    ScreenSize screenSize,
  ) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(
      context,
    );
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            screenSize == ScreenSize.expanded ? 24.0 : 48.0,
            horizontalPadding,
            8.0,
          ),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).scaffoldBackgroundColor.withValues(alpha: 0.8),
            border: Border(
              bottom: BorderSide(
                color: kPrimaryColor.withValues(alpha: 0.2),
                width: 1.0,
              ),
            ),
          ),
          child: Row(
            children: [
              // Back Button
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: primaryTextColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              // Title
              Expanded(
                child: Text(
                  'Profile',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: primaryTextColor,
                    fontSize: ResponsiveBreakpoints.responsiveValue(
                      context,
                      compact: 18.0,
                      medium: 20.0,
                      expanded: 22.0,
                    ),
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.015,
                  ),
                ),
              ),
              // More Options Button
              SizedBox(
                width: 48,
                child: IconButton(
                  icon: Icon(Icons.more_vert, color: primaryTextColor),
                  onPressed: () {
                    // Handle more options
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    Color primaryTextColor,
    Color secondaryTextColor,
    ScreenSize screenSize,
    UserProfileEntity profile,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final profileSize = ResponsiveBreakpoints.responsiveValue(
      context,
      compact: 128.0,
      medium: 136.0,
      expanded: 160.0,
    );

    return Padding(
      padding: EdgeInsets.all(
        ResponsiveBreakpoints.responsiveValue(
          context,
          compact: 16.0,
          medium: 20.0,
          expanded: 32.0,
        ),
      ),
      child: Column(
        children: [
          // Profile Picture Container
          Container(
            width: profileSize,
            height: profileSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDarkMode ? Colors.grey[800]! : Colors.white,
                width: ResponsiveBreakpoints.responsiveValue(
                  context,
                  compact: 4.0,
                  medium: 5.0,
                  expanded: 6.0,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: ResponsiveBreakpoints.responsiveValue(
                    context,
                    compact: 8.0,
                    medium: 12.0,
                    expanded: 16.0,
                  ),
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                  ? NetworkImageWithFallback(
                      imageUrl: profile.avatarUrl!,
                      width: profileSize,
                      height: profileSize,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: profileSize,
                      height: profileSize,
                      color: kPrimaryColor.withValues(alpha: 0.2),
                      child: Icon(
                        Icons.person,
                        size: profileSize * 0.5,
                        color: kPrimaryColor,
                      ),
                    ),
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
          // Name
          Text(
            profile.fullName,
            style: GoogleFonts.plusJakartaSans(
              color: primaryTextColor,
              fontSize: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 22.0,
                medium: 26.0,
                expanded: 30.0,
              ),
              fontWeight: FontWeight.bold,
              letterSpacing: -0.015,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 4.0,
              medium: 6.0,
              expanded: 8.0,
            ),
          ),
          // Email
          Text(
            profile.email,
            style: GoogleFonts.plusJakartaSans(
              color: secondaryTextColor,
              fontSize: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 16.0,
                medium: 18.0,
                expanded: 20.0,
              ),
              fontWeight: FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationList(
    BuildContext context,
    Color primaryTextColor,
    Color secondaryTextColor,
    bool isDarkMode,
    ScreenSize screenSize,
    dynamic profile,
  ) {
    final menuItems = <_MenuItem>[];

    // Show "Become a Seller" for buyers only
    if (profile.role.toString().contains('buyer')) {
      menuItems.add(
        _MenuItem(
          icon: Icons.storefront,
          title: 'Become a Seller',
          onTap: () {
            Navigator.pushNamed(context, '/become-seller');
          },
        ),
      );
    }

    // Show "My Listings", "Dashboard", and "Subscription" for sellers only
    if (profile.role.toString().contains('seller') ||
        profile.role.toString().contains('admin')) {
      menuItems.addAll([
        _MenuItem(
          icon: Icons.dashboard_outlined,
          title: 'Seller Dashboard',
          onTap: () {
            Navigator.pushNamed(context, '/dashboard');
          },
        ),
        _MenuItem(
          icon: Icons.sell,
          title: 'My Listings',
          onTap: () {
            Navigator.pushNamed(context, '/my-listings');
          },
        ),
        _MenuItem(
          icon: Icons.payment,
          title: 'Subscription',
          onTap: () {
            Navigator.pushNamed(context, '/subscription-plans');
          },
        ),
      ]);
    }

    // Common menu items for all users
    menuItems.addAll([
      _MenuItem(
        icon: Icons.school_outlined,
        title: 'Update Academic Info',
        onTap: () {
          _showUpdateAcademicInfoDialog(context, profile);
        },
      ),
      _MenuItem(
        icon: Icons.settings,
        title: 'Account Settings',
        onTap: () {
          Navigator.pushNamed(context, '/account-settings');
        },
      ),
      _MenuItem(
        icon: Icons.help_outline,
        title: 'Help & Support',
        onTap: () {
          debugPrint('Navigate to Help & Support');
        },
      ),
    ]);

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey[800]!.withValues(alpha: 0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        children: List.generate(menuItems.length, (index) {
          final item = menuItems[index];
          final isLast = index == menuItems.length - 1;

          return Column(
            children: [
              InkWell(
                onTap: item.onTap,
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: ResponsiveBreakpoints.responsiveValue(
                      context,
                      compact: 56.0,
                      medium: 60.0,
                      expanded: 72.0,
                    ),
                  ),
                  padding: EdgeInsets.all(
                    ResponsiveBreakpoints.responsiveValue(
                      context,
                      compact: 16.0,
                      medium: 18.0,
                      expanded: 24.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Icon Container
                      Container(
                        width: ResponsiveBreakpoints.responsiveValue(
                          context,
                          compact: 40.0,
                          medium: 44.0,
                          expanded: 56.0,
                        ),
                        height: ResponsiveBreakpoints.responsiveValue(
                          context,
                          compact: 40.0,
                          medium: 44.0,
                          expanded: 56.0,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? kBackgroundColorDark
                              : kBackgroundColorLight,
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Icon(
                          item.icon,
                          color: primaryTextColor,
                          size: ResponsiveBreakpoints.responsiveValue(
                            context,
                            compact: 24.0,
                            medium: 26.0,
                            expanded: 28.0,
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
                      // Title
                      Expanded(
                        child: Text(
                          item.title,
                          style: GoogleFonts.plusJakartaSans(
                            color: primaryTextColor,
                            fontSize: ResponsiveBreakpoints.responsiveValue(
                              context,
                              compact: 16.0,
                              medium: 17.0,
                              expanded: 18.0,
                            ),
                            fontWeight: FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Chevron Icon
                      SizedBox(
                        width: ResponsiveBreakpoints.responsiveValue(
                          context,
                          compact: 28.0,
                          medium: 32.0,
                          expanded: 36.0,
                        ),
                        height: ResponsiveBreakpoints.responsiveValue(
                          context,
                          compact: 28.0,
                          medium: 32.0,
                          expanded: 36.0,
                        ),
                        child: Icon(
                          Icons.chevron_right,
                          color: secondaryTextColor,
                          size: ResponsiveBreakpoints.responsiveValue(
                            context,
                            compact: 28.0,
                            medium: 32.0,
                            expanded: 36.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                  indent: ResponsiveBreakpoints.responsiveValue(
                    context,
                    compact: 72.0,
                    medium: 88.0,
                    expanded: 104.0,
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLogoutButton(
    BuildContext context,
    bool isDarkMode,
    ScreenSize screenSize,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveBreakpoints.responsiveValue(
          context,
          compact: 16.0, // M3 standard margin for mobile
          medium: 0.0,
          expanded: 0.0,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 600.0,
              medium: 400.0,
              expanded: 450.0,
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 48.0, // M3 standard button height
            child: ElevatedButton.icon(
              onPressed: () {
                _showLogoutDialog(context);
              },
              icon: const Icon(
                Icons.logout,
                color: kBackgroundColorDark,
                size: 20.0,
              ),
              label: Text(
                'Logout',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.0, // M3 standard button text size
                  fontWeight: FontWeight.w600, // M3 medium weight
                  color: kBackgroundColorDark,
                  letterSpacing: 0.1, // M3 standard tracking
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: kBackgroundColorDark,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                ), // M3 standard
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.0), // M3 standard
                ),
                elevation: 2.0, // M3 standard elevation
                minimumSize: const Size(64, 40), // M3 minimum touch target
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final primaryTextColor = isDarkMode ? Colors.white : kTextPrimary;

        return AlertDialog(
          backgroundColor: isDarkMode ? kBackgroundColorDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Text(
            'Logout',
            style: GoogleFonts.plusJakartaSans(
              color: primaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.plusJakartaSans(color: primaryTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(color: primaryTextColor),
              ),
            ),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return ElevatedButton(
                  onPressed: state is AuthLoading
                      ? null
                      : () async {
                          // Capture AuthBloc reference before async gap
                          final authBloc = context.read<AuthBloc>();
                          Navigator.pop(context);
                          // Unregister device token before logout (await to ensure it completes)
                          await PushNotificationService()
                              .unregisterDeviceToken();
                          // Dispatch sign out event to BLoC
                          authBloc.add(const SignOutEvent());
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: kBackgroundColorDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        20.0,
                      ), // M3 dialog button
                    ),
                    elevation: 2.0, // M3 standard elevation
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 12.0,
                    ), // M3 standard
                    minimumSize: const Size(64, 40), // M3 minimum touch target
                  ),
                  child: state is AuthLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Logout',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600, // M3 medium weight
                            letterSpacing: 0.1, // M3 standard tracking
                          ),
                        ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showUpdateAcademicInfoDialog(BuildContext context, dynamic profile) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final primaryTextColor = isDarkMode ? Colors.white : kTextPrimary;

        int selectedYear = profile.yearOfStudy ?? 1;
        int selectedSemester = profile.currentSemester ?? 1;

        return BlocConsumer<ProfileBloc, profile_state.ProfileState>(
          listener: (context, state) {
            if (state is profile_state.ProfileLoaded) {
              // Success - close dialog and show success message
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Academic info updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is profile_state.ProfileError) {
              // Error - show error message but keep dialog open
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to update: ${state.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is profile_state.ProfileLoading;

            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  backgroundColor: isDarkMode
                      ? kBackgroundColorDark
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  title: Text(
                    'Academic Info',
                    style: GoogleFonts.plusJakartaSans(
                      color: primaryTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Year of Study',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: selectedYear,
                        dropdownColor: isDarkMode
                            ? kBackgroundColorDark
                            : Colors.white,
                        style: GoogleFonts.plusJakartaSans(
                          color: primaryTextColor,
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                        ),
                        items: List.generate(7, (index) => index + 1)
                            .map(
                              (year) => DropdownMenuItem(
                                value: year,
                                child: Text('Year $year'),
                              ),
                            )
                            .toList(),
                        onChanged: isLoading
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => selectedYear = value);
                                }
                              },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Semester',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: selectedSemester,
                        dropdownColor: isDarkMode
                            ? kBackgroundColorDark
                            : Colors.white,
                        style: GoogleFonts.plusJakartaSans(
                          color: primaryTextColor,
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                        ),
                        items: [1, 2]
                            .map(
                              (sem) => DropdownMenuItem(
                                value: sem,
                                child: Text('Semester $sem'),
                              ),
                            )
                            .toList(),
                        onChanged: isLoading
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => selectedSemester = value);
                                }
                              },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.pop(dialogContext),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.plusJakartaSans(
                          color: primaryTextColor,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              context.read<ProfileBloc>().add(
                                profile_event.UpdateProfileEvent(
                                  yearOfStudy: selectedYear,
                                  currentSemester: selectedSemester,
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: kBackgroundColorDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Save'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _MenuItem({required this.icon, required this.title, required this.onTap});
}
