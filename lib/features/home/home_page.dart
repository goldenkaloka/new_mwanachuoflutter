import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/widgets/network_image_with_fallback.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/core/services/university_service.dart';
import 'package:mwanachuo/core/widgets/shimmer_loading.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_bloc.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_event.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_state.dart';
import 'package:mwanachuo/features/products/domain/entities/product_entity.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_bloc.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_event.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_state.dart';
import 'package:mwanachuo/features/services/domain/entities/service_entity.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_bloc.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_event.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_state.dart';
import 'package:mwanachuo/features/accommodations/domain/entities/accommodation_entity.dart';
import 'package:mwanachuo/features/promotions/presentation/bloc/promotion_cubit.dart';
import 'package:mwanachuo/features/promotions/presentation/bloc/promotion_state.dart';
import 'package:mwanachuo/features/promotions/domain/entities/promotion_entity.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/features/shared/notifications/presentation/cubit/notification_cubit.dart';
import 'package:mwanachuo/features/shared/notifications/presentation/cubit/notification_state.dart';

// --- HOME PAGE WIDGET ---

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedChipIndex = 0;
  int _selectedIndex = 0; // For Bottom Nav Bar
  int _currentPromotionPage = 0;
  String _userName = 'User';
  bool _isLoadingUser = true;
  String _userRole = 'buyer';
  String? _userAvatarUrl; // Store user avatar URL
  bool _dataLoaded = false; // Flag to prevent double loading
  final TextEditingController _searchController = TextEditingController();
  int _unreadNotificationCount = 0;
  bool _hasRedirected = false; // Flag to prevent multiple redirects
  bool _hasReloadedInDidChangeDependencies =
      false; // Flag to prevent multiple reloads in didChangeDependencies

  @override
  void initState() {
    super.initState();

    // Load university and user data
    // Note: _loadSelectedUniversity() will call _loadDataForUniversity() when complete
    _loadSelectedUniversity();
    // Don't call _loadUserDataFromAuth() here - AuthBloc is already initialized by InitialRouteHandler
    // We'll get user data from the AuthBloc listener when Authenticated state is emitted

    // Load promotions immediately (universal, no university required)
    context.read<PromotionCubit>().loadActivePromotions();

    // Load unread notification count
    _loadUnreadNotificationCount();
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final cubit = sl<NotificationCubit>();
      await cubit.loadUnreadCount();
      if (mounted) {
        _notificationSubscription = cubit.stream.listen((state) {
          if (state is UnreadCountLoaded && mounted) {
            setState(() {
              _unreadNotificationCount = state.count;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to load unread count: $e');
    }
  }

  void _loadDataForUniversity() {
    // Prevent double loading
    if (_dataLoaded) {
      debugPrint('⏭️  Data already loaded, skipping...');
      return;
    }

    debugPrint(
      '📊 Loading university data (products, services, accommodations)...',
    );
    _dataLoaded = true;

    // Load products, services, and accommodations
    // Note: University filtering is handled by RLS policies in Supabase
    // based on the user's primary_university_id in the users table
    context.read<ProductBloc>().add(const LoadProductsEvent(limit: 10));
    context.read<ServiceBloc>().add(const LoadServicesEvent(limit: 10));
    context.read<AccommodationBloc>().add(
      const LoadAccommodationsEvent(limit: 10),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload products when returning to homepage to show newly created products
    // This ensures products are refreshed after navigation (e.g., from post-product screen)
    // Only reload once per navigation cycle to prevent rebuild loops
    if (_dataLoaded && mounted && !_hasReloadedInDidChangeDependencies) {
      final route = ModalRoute.of(context);
      if (route != null && route.isCurrent && route.settings.name == '/home') {
        _hasReloadedInDidChangeDependencies = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            debugPrint('🔄 Homepage route active, reloading products...');
            context.read<ProductBloc>().add(const LoadProductsEvent(limit: 10));
            // Reset flag after a delay to allow future reloads when needed
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                _hasReloadedInDidChangeDependencies = false;
              }
            });
          }
        });
      }
    }
  }

  StreamSubscription? _notificationSubscription;

  @override
  void dispose() {
    _searchController.dispose();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSelectedUniversity() async {
    await UniversityService.getSelectedUniversity();
    await UniversityService.getSelectedUniversityLogo();
    if (mounted) {
      setState(() {
        // University selection stored in shared preferences
      });
    }

    // Load data after university is loaded
    if (mounted) {
      _loadDataForUniversity();
    }
  }

  // Simulated Chip Data
  final List<String> _chips = ['All', 'Products', 'Accommodations', 'Services'];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? Colors.white : kBackgroundColorDark;
    final secondaryTextColor = isDarkMode ? Colors.white70 : kTextSecondary;
    final searchBgColor = isDarkMode ? kBackgroundColorDark : Colors.white;
    final searchBorderColor = isDarkMode ? Colors.white10 : Colors.transparent;
    final isExpanded = ResponsiveBreakpoints.isExpanded(context);

    return RepaintBoundary(
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) {
              // Only listen when state actually changes to Authenticated or user data changes
              if (current is Authenticated && previous is Authenticated) {
                // Only rebuild if user data actually changed
                return previous.user.name != current.user.name ||
                    previous.user.role.value != current.user.role.value ||
                    previous.user.profilePicture !=
                        current.user.profilePicture ||
                    previous.user.universityId != current.user.universityId;
              }
              // Always listen to state type changes
              return previous.runtimeType != current.runtimeType;
            },
            listener: (context, state) {
              if (state is Authenticated) {
                // Safety check: if user doesn't have universities, redirect (only once)
                if (state.user.universityId == null && !_hasRedirected) {
                  _hasRedirected = true;
                  debugPrint(
                    '❌ CRITICAL: User on homepage without universities!',
                  );
                  debugPrint('🔄 Redirecting to university selection...');
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      Navigator.pushReplacementNamed(
                        context,
                        '/signup-university-selection',
                      );
                    }
                  });
                  return; // Don't update user data if redirecting
                }

                // Only update if data actually changed to prevent rebuilds
                if (_userName != state.user.name ||
                    _userRole != state.user.role.value ||
                    _userAvatarUrl != state.user.profilePicture ||
                    _isLoadingUser) {
                  setState(() {
                    _userName = state.user.name;
                    _userRole = state.user.role.value;
                    _userAvatarUrl = state.user.profilePicture;
                    _isLoadingUser = false;
                  });
                }
              }
            },
          ),
          BlocListener<ProductBloc, ProductState>(
            listener: (context, state) {
              // Reload products when a new product is created
              if (state is ProductCreated) {
                debugPrint(
                  '🔄 Product created, reloading products on homepage...',
                );
                context.read<ProductBloc>().add(
                  const LoadProductsEvent(limit: 10),
                );
              }
            },
          ),
        ],
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDarkMode
                    ? [
                        const Color(0xFF1A1A1A), // Dark top
                        const Color(0xFF0D0D0D), // Darker bottom
                      ]
                    : [
                        const Color(0xFFFAFAFA), // Very light gray top
                        const Color(0xFFF0F0F0), // Slightly darker gray bottom
                      ],
              ),
            ),
            child: ResponsiveBuilder(
              builder: (context, screenSize) {
                // For expanded screens, use a different layout structure
                if (isExpanded) {
                  return _buildExpandedLayout(
                    context,
                    primaryTextColor,
                    secondaryTextColor,
                    searchBgColor,
                    searchBorderColor,
                    isDarkMode,
                  );
                }

                // Compact and Medium layouts
                final isMedium = screenSize == ScreenSize.medium;

                return CustomScrollView(
                  slivers: [
                    // Consolidated Upper Section with Full-Bleed Animated Background
                    SliverToBoxAdapter(
                      child: _buildAnimatedUpperSection(
                        context,
                        primaryTextColor,
                        secondaryTextColor,
                        searchBgColor,
                        searchBorderColor,
                        screenSize,
                      ),
                    ),

                    // 5. Products Section
                    SliverToBoxAdapter(
                      child: ResponsiveContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              'Products',
                              Icons.shopping_bag,
                              const Color(0xFF00897B), // Deep Teal
                              primaryTextColor,
                              screenSize,
                              route: '/all-products',
                            ),
                            _buildProductsSection(
                              primaryTextColor,
                              secondaryTextColor,
                              screenSize,
                            ),
                            const SizedBox(height: 32), // Added Spacing
                            // 6. Accommodations Section
                            _buildSectionHeader(
                              'Accommodations',
                              Icons.home,
                              const Color(
                                0xFF00897B,
                              ), // Deep Teal (Standardized)
                              primaryTextColor,
                              screenSize,
                              route: '/student-housing',
                            ),
                            _buildAccommodationsSection(
                              primaryTextColor,
                              secondaryTextColor,
                              screenSize,
                            ),
                            const SizedBox(height: 32), // Added Spacing
                            // 7. Services Section
                            _buildSectionHeader(
                              'Services',
                              Icons.build,
                              const Color(0xFF3949AB), // Slate Indigo
                              primaryTextColor,
                              screenSize,
                              route: '/services',
                            ),
                            _buildServicesSection(
                              primaryTextColor,
                              secondaryTextColor,
                              screenSize,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom padding for bottom navigation
                    SliverPadding(
                      padding: EdgeInsets.only(
                        bottom: ResponsiveBreakpoints.isCompact(context)
                            ? 80
                            : (isMedium ? 60 : 0),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedLayout(
    BuildContext context,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color searchBgColor,
    Color searchBorderColor,
    bool isDarkMode,
  ) {
    return Row(
      children: [
        // Sidebar Navigation (for expanded screens)
        Container(
          width: 280,
          color: isDarkMode ? kBackgroundColorDark : Colors.white,
          child: Column(
            children: [
              const SizedBox(height: 48),
              _buildSidebarNav(context, primaryTextColor, isDarkMode),
            ],
          ),
        ),
        // Main Content Area
        Expanded(
          child: SafeArea(
            bottom: false, // Bottom safe area handled by bottom nav
            child: CustomScrollView(
              slivers: [
                // Top App Bar (collapsible)
                SliverSafeArea(
                  bottom: false,
                  sliver: SliverToBoxAdapter(
                    child: _buildTopAppBar(
                      context,
                      primaryTextColor,
                      ScreenSize.expanded,
                    ),
                  ),
                ),

                // Search Bar (collapsible)
                SliverToBoxAdapter(
                  child: _buildSearchBar(
                    searchBgColor,
                    searchBorderColor,
                    primaryTextColor,
                    secondaryTextColor,
                    ScreenSize.expanded,
                  ),
                ),

                // Promotions Section (collapsible)
                SliverToBoxAdapter(
                  child: _buildPromotionsSection(ScreenSize.expanded),
                ),

                // Sticky Chips (Categories) - Pinned at top when scrolling
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyChipsDelegate(
                    child: _buildChipsRow(ScreenSize.expanded),
                    minHeight: 56.0,
                    maxHeight: 56.0,
                  ),
                ),

                // Products Section
                SliverToBoxAdapter(
                  child: ResponsiveContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          'Products',
                          Icons.shopping_bag,
                          const Color(0xFF00897B), // Deep Teal
                          primaryTextColor,
                          ScreenSize.expanded,
                          route: '/all-products',
                        ),
                        _buildProductsSection(
                          primaryTextColor,
                          secondaryTextColor,
                          ScreenSize.expanded,
                        ),
                        const SizedBox(height: 32),
                        // Accommodations Section
                        _buildSectionHeader(
                          'Accommodations',
                          Icons.home,
                          const Color(0xFF00897B), // Deep Teal (Standardized)
                          primaryTextColor,
                          ScreenSize.expanded,
                          route: '/student-housing',
                        ),
                        _buildAccommodationsSection(
                          primaryTextColor,
                          secondaryTextColor,
                          ScreenSize.expanded,
                        ),
                        const SizedBox(height: 32),
                        // Services Section
                        _buildSectionHeader(
                          'Services',
                          Icons.build,
                          const Color(0xFF3949AB), // Slate Indigo
                          primaryTextColor,
                          ScreenSize.expanded,
                          route: '/services',
                        ),
                        _buildServicesSection(
                          primaryTextColor,
                          secondaryTextColor,
                          ScreenSize.expanded,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarNav(
    BuildContext context,
    Color primaryTextColor,
    bool isDarkMode,
  ) {
    return Column(
      children: [
        // Logo/App Name
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Mwanachuoshop',
            style: GoogleFonts.plusJakartaSans(
              color: primaryTextColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Divider(),
        // Navigation Items
        _buildNavItem(Icons.home, 'Home', 0, primaryTextColor, isDarkMode),
        _buildNavItem(Icons.search, 'Search', 1, primaryTextColor, isDarkMode),
        _buildNavItem(
          Icons.dashboard_outlined,
          'Dashboard',
          2,
          primaryTextColor,
          isDarkMode,
        ),
        _buildNavItem(
          Icons.chat_bubble_outline,
          'Messages',
          3,
          primaryTextColor,
          isDarkMode,
        ),
        _buildNavItem(
          Icons.person_outline,
          'Profile',
          4,
          primaryTextColor,
          isDarkMode,
        ),
        _buildNavItem(
          Icons.school_outlined,
          'Mwanachuomind',
          5,
          primaryTextColor,
          isDarkMode,
        ),
      ],
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    Color color,
    bool isDarkMode,
  ) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        // Handle navigation
        if (index == 1) {
          Navigator.pushNamed(context, '/search', arguments: null);
        } else if (index == 2) {
          Navigator.pushNamed(context, '/dashboard');
        } else if (index == 3) {
          Navigator.pushNamed(context, '/messages');
        } else if (index == 4) {
          Navigator.pushNamed(context, '/profile').then((_) {
            // Reload university when returning from profile
            _loadSelectedUniversity();
          });
        } else if (index == 5) {
          Navigator.pushNamed(context, '/mwanachuomind');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        color: isSelected
            ? (Theme.of(context).brightness == Brightness.dark
                  ? kPrimaryColor.withValues(alpha: 0.2)
                  : const Color(0xFF078829).withValues(alpha: 0.2))
            : Colors.transparent,
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? (Theme.of(context).brightness == Brightness.dark
                        ? kPrimaryColor
                        : const Color(0xFF078829))
                  : color,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: isSelected
                    ? (Theme.of(context).brightness == Brightness.dark
                          ? kPrimaryColor
                          : const Color(0xFF078829))
                    : color,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  // Get time-based greeting
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // --- REFINED UPPER SECTION WITH DYNAMIC BACKGROUND ---

  Widget _buildAnimatedUpperSection(
    BuildContext context,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color searchBgColor,
    Color searchBorderColor,
    ScreenSize screenSize,
  ) {
    // Get current promotion gradient
    final currentGradient =
        _promotionGradients[_currentPromotionPage % _promotionGradients.length];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            currentGradient.colors.first,
            currentGradient.colors.first.withValues(alpha: 0.0),
          ],
          stops: const [
            0.0,
            0.7,
          ], // Fade ends at the middle of the promotion cards
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Top Bar (Personalized Greeting + Notifications)
            _buildTopAppBarExtended(context, Colors.white, screenSize),

            // 2. Search Bar
            _buildSearchBarExtended(
              Colors.white.withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.3),
              Colors.white,
              Colors.white.withValues(alpha: 0.7),
              screenSize,
            ),

            // 3. Promotions Carousel
            _buildPromotionsSectionExtended(screenSize),
          ],
        ),
      ),
    );
  }

  // Specialized Top Bar for the animated section with white text for contrast
  Widget _buildTopAppBarExtended(
    BuildContext context,
    Color textColor,
    ScreenSize screenSize,
  ) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(
      context,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        16.0,
        horizontalPadding,
        8.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // User Avatar with white border for contrast
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white24,
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white10,
                  backgroundImage: _userAvatarUrl != null
                      ? NetworkImage(_userAvatarUrl!)
                      : null,
                  child: _userAvatarUrl == null
                      ? const Icon(Icons.person, color: Colors.white, size: 20)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // Personalized Greeting
              Text(
                _isLoadingUser
                    ? '${_getGreeting()}!'
                    : '${_getGreeting()}, ${_userName.split(' ').first}!',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // Notification Icon
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // Specialized Search Bar for the animated section with darker translucent fill
  Widget _buildSearchBarExtended(
    Color bgColor,
    Color borderColor,
    Color primaryTextColor,
    Color hintColor,
    ScreenSize screenSize,
  ) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(
      context,
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 8.0,
      ),
      child: TextField(
        readOnly: true,
        onTap: () => Navigator.pushNamed(context, '/search'),
        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Search products, rooms, services...',
          hintStyle: GoogleFonts.plusJakartaSans(
            color: Colors.white70,
            fontSize: 14,
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          filled: true,
          fillColor: Colors.black.withValues(alpha: 0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  // Specialized Promotions Section with optimized contrast
  Widget _buildPromotionsSectionExtended(ScreenSize screenSize) {
    return BlocBuilder<PromotionCubit, PromotionState>(
      builder: (context, state) {
        if (state is PromotionsLoaded && state.promotions.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: _buildPromotionsCarousel(state.promotions, screenSize),
          );
        }
        return const SizedBox(height: 16);
      },
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [kBackgroundColorDark, kBackgroundColorDark]
              : [Colors.white, const Color(0xFFF8FFF8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        screenSize == ScreenSize.expanded ? 24.0 : 48.0,
        horizontalPadding,
        16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Profile Picture with gradient border
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [kPrimaryColor, kPrimaryColorLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Container(
                      width: ResponsiveBreakpoints.responsiveValue(
                        context,
                        compact: 40.0,
                        medium: 44.0,
                        expanded: 48.0,
                      ),
                      height: ResponsiveBreakpoints.responsiveValue(
                        context,
                        compact: 40.0,
                        medium: 44.0,
                        expanded: 48.0,
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDarkMode ? kBackgroundColorDark : Colors.white,
                        border: Border.all(
                          color: isDarkMode
                              ? kBackgroundColorDark
                              : Colors.white,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: NetworkImageWithFallback(
                          imageUrl: _userAvatarUrl ?? '',
                          width: ResponsiveBreakpoints.responsiveValue(
                            context,
                            compact: 36.0,
                            medium: 40.0,
                            expanded: 44.0,
                          ),
                          height: ResponsiveBreakpoints.responsiveValue(
                            context,
                            compact: 36.0,
                            medium: 40.0,
                            expanded: 44.0,
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: ResponsiveBreakpoints.responsiveValue(
                      context,
                      compact: 12.0,
                      medium: 16.0,
                      expanded: 16.0,
                    ),
                  ),
                  // Enhanced User Greeting - personalized with username
                  Text(
                    _isLoadingUser
                        ? '${_getGreeting()}!'
                        : '${_getGreeting()}, ${_userName.split(' ').first}!',
                    style: GoogleFonts.plusJakartaSans(
                      color: primaryTextColor,
                      fontSize: ResponsiveBreakpoints.responsiveValue(
                        context,
                        compact: 18.0,
                        medium: 20.0,
                        expanded: 22.0,
                      ),
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              // Notifications Button with Badge
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/notifications');
                      },
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: primaryTextColor,
                      ),
                    ),
                    if (_unreadNotificationCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDarkMode
                                  ? kBackgroundColorDark
                                  : Colors.white,
                              width: 2,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            _unreadNotificationCount > 99
                                ? '99+'
                                : '$_unreadNotificationCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
    Color bgColor,
    Color borderColor,
    Color primaryTextColor,
    Color hintColor,
    ScreenSize screenSize,
  ) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(
      context,
    );
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 12.0,
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.plusJakartaSans(
          color: primaryTextColor,
          fontSize: ResponsiveBreakpoints.responsiveValue(
            context,
            compact: 16.0,
            medium: 17.0,
            expanded: 18.0,
          ),
        ),
        decoration: InputDecoration(
          hintText: 'Search products, rooms, services...',
          hintStyle: GoogleFonts.plusJakartaSans(
            color: hintColor,
            fontSize: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 16.0,
              medium: 17.0,
              expanded: 18.0,
            ),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: hintColor,
            size: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 24.0,
              medium: 26.0,
              expanded: 28.0,
            ),
          ),
          filled: true,
          fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide(color: kPrimaryColor, width: 2.0),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 20.0,
              medium: 24.0,
              expanded: 28.0,
            ),
            vertical: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 16.0,
              medium: 18.0,
              expanded: 20.0,
            ),
          ),
        ),
        onSubmitted: (value) {
          // Navigate to search results page with query
          if (value.isNotEmpty) {
            Navigator.pushNamed(context, '/search', arguments: value);
          }
        },
      ),
    );
  }

  Widget _buildChipsRow(ScreenSize screenSize) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(
      context,
    );
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Map chip labels to icons
    final Map<String, IconData> chipIcons = {
      'All': Icons.grid_view_rounded,
      'Products': Icons.shopping_bag_outlined,
      'Services': Icons.build_outlined,
      'Accommodations': Icons.home_work_outlined,
      'Events': Icons.event_outlined,
    };

    return Container(
      color: isDarkMode ? kBackgroundColorDark : kBackgroundColorLight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 8.0,
        ),
        child: Row(
          children: List.generate(_chips.length, (index) {
            final label = _chips[index];
            final isSelected = index == _selectedChipIndex;
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
            final icon = chipIcons[label] ?? Icons.category_outlined;

            return Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedChipIndex = index;
                  });
                },
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDarkMode ? kPrimaryColor : const Color(0xFF078829))
                        : (isDarkMode ? kBackgroundColorDark : Colors.white),
                    borderRadius: BorderRadius.circular(9999.0),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (isDarkMode ? Colors.white10 : Colors.transparent),
                      width: isDarkMode && !isSelected ? 1.0 : 0.0,
                    ),
                    boxShadow: isSelected
                        ? const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: isSelected
                            ? (isDarkMode ? kBackgroundColorDark : Colors.white)
                            : (isDarkMode ? Colors.white70 : kTextSecondary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          color: isSelected
                              ? (isDarkMode
                                    ? kBackgroundColorDark
                                    : Colors.white)
                              : (isDarkMode ? Colors.white70 : kTextSecondary),
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    Color sectionColor,
    Color titleColor,
    ScreenSize screenSize, {
    String? route,
  }) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(
      context,
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        ResponsiveBreakpoints.responsiveValue(
          context,
          compact: 24.0,
          medium: 28.0,
          expanded: 32.0,
        ),
        horizontalPadding,
        ResponsiveBreakpoints.responsiveValue(
          context,
          compact: 12.0,
          medium: 16.0,
          expanded: 20.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: sectionColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: sectionColor, size: 18),
          ),
          SizedBox(
            width: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 12.0,
              medium: 16.0,
              expanded: 20.0,
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                color: titleColor,
                fontSize: ResponsiveBreakpoints.responsiveValue(
                  context,
                  compact: 18.0,
                  medium: 20.0,
                  expanded: 22.0,
                ),
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (route != null && route.isNotEmpty)
            TextButton(
              onPressed: () {
                try {
                  Navigator.pushNamed(context, route);
                } catch (e) {
                  // Route doesn't exist, do nothing or show error
                  debugPrint('Navigation error: Route $route not found');
                }
              },
              child: Text(
                'View All',
                style: GoogleFonts.plusJakartaSans(
                  color: sectionColor,
                  fontSize: ResponsiveBreakpoints.responsiveValue(
                    context,
                    compact: 14.0,
                    medium: 15.0,
                    expanded: 16.0,
                  ),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===== NEW BLOC BUILDER METHODS =====

  Widget _buildPromotionsSection(ScreenSize screenSize) {
    return BlocBuilder<PromotionCubit, PromotionState>(
      builder: (context, state) {
        if (state is PromotionsLoading) {
          return _buildLoadingCarousel(screenSize);
        }

        if (state is PromotionError) {
          return _buildErrorWidget(
            message: state.message,
            onRetry: () =>
                context.read<PromotionCubit>().loadActivePromotions(),
          );
        }

        if (state is PromotionsLoaded) {
          if (state.promotions.isEmpty) {
            return _buildEmptyState('No promotions available');
          }

          return _buildPromotionsCarousel(state.promotions, screenSize);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildProductsSection(
    Color primaryTextColor,
    Color secondaryTextColor,
    ScreenSize screenSize,
  ) {
    return BlocBuilder<ProductBloc, ProductState>(
      buildWhen: (previous, current) {
        // Only rebuild when state type changes or products list changes
        return previous.runtimeType != current.runtimeType ||
            (current is ProductsLoaded &&
                previous is ProductsLoaded &&
                current.products.length != previous.products.length);
      },
      builder: (context, state) {
        if (state is ProductsLoading) {
          return ProductGridSkeleton(
            itemCount: 4,
            crossAxisCount: ResponsiveBreakpoints.responsiveGridColumns(
              context,
            ),
          );
        }

        if (state is ProductError) {
          return _buildErrorWidget(
            message: state.message,
            onRetry: () => context.read<ProductBloc>().add(
              const LoadProductsEvent(limit: 10),
            ),
          );
        }

        if (state is ProductsLoaded) {
          if (state.products.isEmpty) {
            return _buildEmptyState('No products available');
          }

          return _buildProductsGrid(
            state.products,
            primaryTextColor,
            secondaryTextColor,
            screenSize,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildServicesSection(
    Color primaryTextColor,
    Color secondaryTextColor,
    ScreenSize screenSize,
  ) {
    return BlocBuilder<ServiceBloc, ServiceState>(
      buildWhen: (previous, current) {
        // Only rebuild when state type changes or services list changes
        return previous.runtimeType != current.runtimeType ||
            (current is ServicesLoaded &&
                previous is ServicesLoaded &&
                current.services.length != previous.services.length);
      },
      builder: (context, state) {
        if (state is ServicesLoading) {
          return ListSkeleton(
            itemCount: 4,
            itemBuilder: (context, index) => const ServiceCardSkeleton(),
          );
        }

        if (state is ServiceError) {
          return _buildErrorWidget(
            message: state.message,
            onRetry: () => context.read<ServiceBloc>().add(
              const LoadServicesEvent(limit: 10),
            ),
          );
        }

        if (state is ServicesLoaded) {
          if (state.services.isEmpty) {
            return _buildEmptyState('No services available');
          }

          return _buildServicesGrid(
            state.services,
            primaryTextColor,
            secondaryTextColor,
            screenSize,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAccommodationsSection(
    Color primaryTextColor,
    Color secondaryTextColor,
    ScreenSize screenSize,
  ) {
    return BlocBuilder<AccommodationBloc, AccommodationState>(
      buildWhen: (previous, current) {
        // Only rebuild when state type changes or accommodations list changes
        return previous.runtimeType != current.runtimeType ||
            (current is AccommodationsLoaded &&
                previous is AccommodationsLoaded &&
                current.accommodations.length !=
                    previous.accommodations.length);
      },
      builder: (context, state) {
        if (state is AccommodationsLoading) {
          return ProductGridSkeleton(
            itemCount: 4,
            crossAxisCount: ResponsiveBreakpoints.responsiveGridColumns(
              context,
            ),
          );
        }

        if (state is AccommodationError) {
          return _buildErrorWidget(
            message: state.message,
            onRetry: () => context.read<AccommodationBloc>().add(
              const LoadAccommodationsEvent(limit: 10),
            ),
          );
        }

        if (state is AccommodationsLoaded) {
          if (state.accommodations.isEmpty) {
            return _buildEmptyState('No accommodations available');
          }

          return _buildAccommodationsGrid(
            state.accommodations,
            primaryTextColor,
            secondaryTextColor,
            screenSize,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  // Actual data rendering methods
  // Gradient definitions for promotion cards
  final List<LinearGradient> _promotionGradients = [
    // Light Blue
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.lightBlue.shade900, Colors.lightBlue.shade100],
    ),
    // Pink
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.pink.shade900, Colors.pink.shade100],
    ),
    // Purple
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.purple.shade900, Colors.purple.shade100],
    ),
    // Teal
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.teal.shade900, Colors.teal.shade100],
    ),
  ];

  Widget _buildPromotionsCarousel(
    List<PromotionEntity> promotions,
    ScreenSize screenSize,
  ) {
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: promotions.length,
          itemBuilder: (context, index, realIndex) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 2.0),
              child: _buildPromotionCard(
                promotions[index],
                screenSize,
                index: index, // Pass index for gradient selection
                isActive: index == _currentPromotionPage,
              ),
            );
          },
          options: CarouselOptions(
            height: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 160.0,
              medium: 180.0,
              expanded: 220.0,
            ),
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            enlargeCenterPage: true, // Enable to highlight the active card
            scrollDirection: Axis.horizontal,
            viewportFraction: 0.8, // Adjust to show upcoming card
            onPageChanged: (index, reason) {
              setState(() {
                _currentPromotionPage = index;
              });
            },
          ),
        ),
        SizedBox(
          height: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(promotions.length, (index) {
              return Container(
                width: 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPromotionPage == index
                      ? _promotionGradients[index % _promotionGradients.length]
                            .colors
                            .first
                      : Colors.grey[700]!, // Solid neutral "without color"
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildPromotionCard(
    PromotionEntity promotion,
    ScreenSize screenSize, {
    required int index, // Changed to required
    bool isActive = false,
  }) {
    final cardWidth = ResponsiveBreakpoints.responsiveValue(
      context,
      compact: 400.0,
      medium: 480.0,
      expanded: 580.0,
    );
    final cardHeight = ResponsiveBreakpoints.responsiveValue(
      context,
      compact: 140.0,
      medium: 160.0,
      expanded: 200.0,
    );

    // Select gradient based on index
    final colorIndex = index % _promotionGradients.length;
    final gradient = _promotionGradients[colorIndex];

    // Select high-contrast text color based on index
    Color textColor;
    switch (colorIndex) {
      case 0: // Blue
        textColor = Colors.amberAccent; // Bright Yellow on Blue
        break;
      case 1: // Pink
        textColor = Colors.white; // White on Pink
        break;
      case 2: // Purple
        textColor = Colors.lightGreenAccent; // Neon Green on Purple
        break;
      case 3: // Teal
        textColor = Colors.yellowAccent; // Yellow on Teal
        break;
      default:
        textColor = Colors.white;
    }

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/promotion-details',
        arguments: promotion.id,
      ),
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          gradient: gradient, // Apply gradient
        ),
        child: Stack(
          fit: StackFit.expand, // Make stack expand to fill container
          children: [
            if (promotion.imageUrl != null)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: NetworkImageWithFallback(
                    imageUrl: promotion.imageUrl!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // Deep Gradient Overlay (Hides top of image, reveals bottom)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      gradient.colors.first, // Solid deep color at top
                      gradient.colors.first.withValues(
                        alpha: 0.0,
                      ), // Transparent at bottom
                    ],
                    stops: const [0.4, 1.0], // Fade starting at 40% down
                  ),
                ),
              ),
            ),

            // Text Container
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                // Removed black gradient overlay for cleaner look
              ),
              padding: EdgeInsets.all(
                ResponsiveBreakpoints.responsiveValue(
                  context,
                  compact: 16.0,
                  medium: 20.0,
                  expanded: 24.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _AnimatedPromotionText(
                    key: ValueKey(
                      'promo_${promotion.id}_title_$_currentPromotionPage',
                    ),
                    text: promotion.title,
                    fontSize: ResponsiveBreakpoints.responsiveValue(
                      context,
                      compact: 18.0,
                      medium: 20.0,
                      expanded: 24.0,
                    ),
                    fontWeight: FontWeight.bold,
                    maxLines: 2,
                    shouldAnimate: isActive,
                    textColor: textColor,
                  ),
                  if (promotion.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _AnimatedPromotionText(
                      key: ValueKey(
                        'promo_${promotion.id}_subtitle_$_currentPromotionPage',
                      ),
                      text: promotion.subtitle,
                      fontSize: ResponsiveBreakpoints.responsiveValue(
                        context,
                        compact: 14.0,
                        medium: 16.0,
                        expanded: 18.0,
                      ),
                      fontWeight: FontWeight.normal,
                      maxLines: 1,
                      delay: const Duration(milliseconds: 300),
                      shouldAnimate: isActive,
                      textColor: textColor.withValues(
                        alpha: 0.8,
                      ), // Slightly lighter for subtitle
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsGrid(
    List<ProductEntity> products,
    Color primaryTextColor,
    Color secondaryTextColor,
    ScreenSize screenSize,
  ) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(
      context,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.take(6).length,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 0.75,
        ),
        itemBuilder: (context, index) {
          final product = products[index];
          return _AnimatedCardEntry(
            index: index,
            child: _HomeGridCard(
              imageUrl: product.images.isNotEmpty ? product.images.first : '',
              title: product.title,
              price: product.price,
              type: 'product',
              onTap: () => Navigator.pushNamed(
                context,
                '/product-details',
                arguments: product.id,
              ),
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
          );
        },
      ),
    );
  }

  Widget _buildServicesGrid(
    List<ServiceEntity> services,
    Color primaryTextColor,
    Color secondaryTextColor,
    ScreenSize screenSize,
  ) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(
      context,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: services.take(6).length,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        itemBuilder: (context, index) {
          final service = services[index];
          return ListTile(
            key: ValueKey('service_${service.id}'),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: service.images.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: service.images.first,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 60,
                        height: 60,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 60,
                        height: 60,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 24,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white24
                              : Colors.black12,
                        ),
                      ),
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[200],
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 24,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white24
                            : Colors.black12,
                      ),
                    ),
            ),
            title: Text(
              service.title,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'TZS ${service.price.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(
                      0xFF3949AB,
                    ), // Standardized Slate Indigo (was Purple)
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 14,
                      color: kTextSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        service.providerName,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(
              context,
              '/service-details',
              arguments: service.id,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAccommodationsGrid(
    List<AccommodationEntity> accommodations,
    Color primaryTextColor,
    Color secondaryTextColor,
    ScreenSize screenSize,
  ) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(
      context,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: accommodations.take(6).length,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 0.7, // Taller cards (increased length)
        ),
        itemBuilder: (context, index) {
          final accommodation = accommodations[index];
          return _HomeGridCard(
            imageUrl: accommodation.images.isNotEmpty
                ? accommodation.images.first
                : '',
            title: accommodation.name,
            price: accommodation.price,
            type: 'accommodation',
            onTap: () => Navigator.pushNamed(
              context,
              '/accommodation-details',
              arguments: accommodation.id,
            ),
            isDark: Theme.of(context).brightness == Brightness.dark,
          );
        },
      ),
    );
  }

  // State widgets
  Widget _buildLoadingPromotionCard(ScreenSize screenSize) {
    final cardWidth = ResponsiveBreakpoints.responsiveValue(
      context,
      compact: 320.0,
      medium: 360.0,
      expanded: 450.0,
    );
    final cardHeight = ResponsiveBreakpoints.responsiveValue(
      context,
      compact: 140.0,
      medium: 160.0,
      expanded: 200.0,
    );

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[300],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: kPrimaryColor),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCarousel(ScreenSize screenSize) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(
      context,
    );

    return Column(
      children: [
        SizedBox(
          height: ResponsiveBreakpoints.responsiveValue(
            context,
            compact: 160.0,
            medium: 180.0,
            expanded: 220.0,
          ),
          child: PageView.builder(
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: _buildLoadingPromotionCard(screenSize),
              );
            },
          ),
        ),
        SizedBox(
          height: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Container(
                width: 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPromotionPage == index
                      ? Colors.grey[400]
                      : Colors.grey[400]!.withValues(alpha: 0.3),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget({
    required String message,
    required VoidCallback onRetry,
  }) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(
      context,
    );
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 32,
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
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

  Widget _buildEmptyState(String message) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(
      context,
    );
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 32,
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[600]
                  : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeGridCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final double price;
  final String type; // 'product' or 'accommodation'
  final VoidCallback onTap;
  final bool isDark;

  const _HomeGridCard({
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.type,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Container(
                      color: isDark
                          ? const Color(0xFF1A1A1A)
                          : Colors.grey[200],
                      child: imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: isDark
                                    ? Colors.grey[900]
                                    : Colors.grey[300],
                              ),
                              errorWidget: (context, url, _) => Container(
                                color: isDark
                                    ? Colors.grey[900]
                                    : Colors.grey[300],
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black12,
                                  size: 32,
                                ),
                              ),
                            )
                          : Container(
                              color: isDark
                                  ? Colors.grey[900]
                                  : Colors.grey[300],
                              child: Icon(
                                Icons.image_outlined,
                                color: isDark ? Colors.white24 : Colors.black12,
                                size: 32,
                              ),
                            ),
                    ),
                  ),
                ),
                // Icon Badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getTypeIcon(),
                      color: _getTypeColor(),
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Text Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: _getTypeColor(), // Deep Teal
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'TZS ${price.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (type) {
      case 'product':
        return Icons.shopping_bag_rounded;
      case 'accommodation':
        return Icons.home_work_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _getTypeColor() {
    switch (type) {
      case 'product':
        return const Color(0xFF00897B); // Deep Teal (Standardized)
      case 'accommodation':
        return const Color(0xFF00897B); // Deep Teal (Standardized)
      default:
        return Colors.white;
    }
  }
}

/// Delegate for sticky chips header
class _StickyChipsDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight;
  final double maxHeight;

  _StickyChipsDelegate({
    required this.child,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? kBackgroundColorDark : kBackgroundColorLight,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(_StickyChipsDelegate oldDelegate) {
    return child != oldDelegate.child ||
        minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight;
  }
}

// Animated text widget for promotion banners (Nickelodeon-style letter by letter)
class _AnimatedPromotionText extends StatefulWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final int maxLines;
  final Duration delay;
  final bool shouldAnimate;
  final Color? textColor; // Added custom text color

  const _AnimatedPromotionText({
    super.key,
    required this.text,
    required this.fontSize,
    required this.fontWeight,
    required this.maxLines,
    this.delay = Duration.zero,
    this.shouldAnimate = true,
    this.textColor,
  });

  @override
  State<_AnimatedPromotionText> createState() => _AnimatedPromotionTextState();
}

class _AnimatedPromotionTextState extends State<_AnimatedPromotionText>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _rotationAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    if (widget.shouldAnimate) {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(_AnimatedPromotionText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If text changed or shouldAnimate changed from false to true, restart animations
    if (oldWidget.text != widget.text) {
      // Dispose old controllers
      for (var controller in _controllers) {
        controller.dispose();
      }
      _initializeAnimations();
      if (widget.shouldAnimate) {
        _startAnimations();
      }
    } else if (!oldWidget.shouldAnimate && widget.shouldAnimate) {
      // Reset and restart animations when card becomes active
      for (var controller in _controllers) {
        controller.reset();
      }
      _startAnimations();
    }
  }

  void _initializeAnimations() {
    final letters = widget.text.split('');

    _controllers = List.generate(
      letters.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _scaleAnimations = _controllers.map((controller) {
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.0,
            end: 1.3,
          ).chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 40,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1.3,
            end: 0.95,
          ).chain(CurveTween(curve: Curves.easeInOut)),
          weight: 30,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.95,
            end: 1.0,
          ).chain(CurveTween(curve: Curves.easeOut)),
          weight: 30,
        ),
      ]).animate(controller);
    }).toList();

    _rotationAnimations = _controllers.asMap().entries.map((entry) {
      final controller = entry.value;
      final index = entry.key;
      // Alternate rotation direction for playfulness
      final rotationDirection = index % 2 == 0 ? 1.0 : -1.0;
      return Tween<double>(
        begin: 0.25 * rotationDirection,
        end: 0.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.elasticOut));
    }).toList();

    _slideAnimations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0, -1.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));
    }).toList();
  }

  void _startAnimations() {
    // Start animations with staggered delay (letter by letter)
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(
        widget.delay + Duration(milliseconds: i * 40), // 40ms per letter
        () {
          if (mounted && widget.shouldAnimate) {
            _controllers[i].forward();
          }
        },
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final letters = widget.text.split('');

    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: List.generate(letters.length, (index) {
        final letter = letters[index];
        final isSpace = letter == ' ';

        if (isSpace) {
          return SizedBox(width: widget.fontSize * 0.25);
        }

        return AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                _slideAnimations[index].value.dx,
                _slideAnimations[index].value.dy * widget.fontSize * 0.5,
              ),
              child: Transform.scale(
                scale: _scaleAnimations[index].value,
                child: Transform.rotate(
                  angle: _rotationAnimations[index].value,
                  child: Text(
                    letter,
                    style: TextStyle(
                      color:
                          widget.textColor ??
                          (widget.fontWeight == FontWeight.bold
                              ? const Color(
                                  0xFF1565C0,
                                ) // Default Blue 800 for Title
                              : Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[700]), // Default Grey for Subtitle
                      fontSize: widget.fontSize,
                      fontWeight: widget.fontWeight,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

// Animated card entry widget for staggered animations
class _AnimatedCardEntry extends StatefulWidget {
  const _AnimatedCardEntry({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_AnimatedCardEntry> createState() => _AnimatedCardEntryState();
}

class _AnimatedCardEntryState extends State<_AnimatedCardEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Staggered delay based on index
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}
