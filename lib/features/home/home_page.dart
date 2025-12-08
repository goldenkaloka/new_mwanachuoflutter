import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/widgets/network_image_with_fallback.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/core/services/university_service.dart';
import 'package:mwanachuo/core/widgets/app_card.dart';
import 'package:mwanachuo/core/widgets/shimmer_loading.dart';
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
        cubit.stream.listen((state) {
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSelectedUniversity() async {
    await UniversityService.getSelectedUniversity();
    await UniversityService.getSelectedUniversityLogo();
    setState(() {
      // University selection stored in shared preferences
    });

    // Load data after university is loaded
    _loadDataForUniversity();
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
          backgroundColor: isDarkMode
              ? kBackgroundColorDark
              : kBackgroundColorLight,
          body: ResponsiveBuilder(
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

              return SafeArea(
                bottom: false, // Bottom safe area handled by bottom nav
                child: CustomScrollView(
                  slivers: [
                    // 1. Top App Bar (collapsible)
                    SliverSafeArea(
                      bottom: false,
                      sliver: SliverToBoxAdapter(
                        child: _buildTopAppBar(
                          context,
                          primaryTextColor,
                          screenSize,
                        ),
                      ),
                    ),

                    // 2. Search Bar (collapsible)
                    SliverToBoxAdapter(
                      child: _buildSearchBar(
                        searchBgColor,
                        searchBorderColor,
                        primaryTextColor,
                        secondaryTextColor,
                        screenSize,
                      ),
                    ),

                    // 3. Promotions Section (collapsible)
                    SliverToBoxAdapter(
                      child: _buildPromotionsSection(screenSize),
                    ),

                    // 4. Sticky Chips (Categories) - Pinned at top when scrolling
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _StickyChipsDelegate(
                        child: _buildChipsRow(screenSize),
                        minHeight: 56.0,
                        maxHeight: 56.0,
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
                              primaryTextColor,
                              screenSize,
                              route: '/all-products',
                            ),
                            _buildProductsSection(
                              primaryTextColor,
                              secondaryTextColor,
                              screenSize,
                            ),

                            // 6. Accommodations Section
                            _buildSectionHeader(
                              'Accommodations',
                              Icons.home,
                              primaryTextColor,
                              screenSize,
                              route: '/student-housing',
                            ),
                            _buildAccommodationsSection(
                              primaryTextColor,
                              secondaryTextColor,
                              screenSize,
                            ),

                            // 7. Services Section
                            _buildSectionHeader(
                              'Services',
                              Icons.build,
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
                ),
              );
            },
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
                          primaryTextColor,
                          ScreenSize.expanded,
                          route: '/all-products',
                        ),
                        _buildProductsSection(
                          primaryTextColor,
                          secondaryTextColor,
                          ScreenSize.expanded,
                        ),
                        // Accommodations Section
                        _buildSectionHeader(
                          'Accommodations',
                          Icons.home,
                          primaryTextColor,
                          ScreenSize.expanded,
                          route: '/student-housing',
                        ),
                        _buildAccommodationsSection(
                          primaryTextColor,
                          secondaryTextColor,
                          ScreenSize.expanded,
                        ),
                        // Services Section
                        _buildSectionHeader(
                          'Services',
                          Icons.build,
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

  Widget _buildTopAppBar(
    BuildContext context,
    Color primaryTextColor,
    ScreenSize screenSize,
  ) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(
      context,
    );
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        screenSize == ScreenSize.expanded ? 24.0 : 48.0,
        horizontalPadding,
        8.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Profile Picture
              Container(
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
                  color: const Color(
                    0xFF078829,
                  ), // Use the same active color as bottom nav
                ),
                child: NetworkImageWithFallback(
                  imageUrl: _userAvatarUrl ?? '',
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
                  fit: BoxFit.cover,
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
              // User Greeting
              Text(
                _isLoadingUser
                    ? 'Hello!'
                    : 'Hello, ${_userName.split(' ').first}!',
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
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/notifications');
                },
                icon: Icon(Icons.notifications_none, color: primaryTextColor),
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
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
    Color primaryTextColor,
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF078829).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).brightness == Brightness.dark
                  ? kPrimaryColor
                  : const Color(0xFF078829),
              size: 20,
            ),
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
                color: primaryTextColor,
                fontSize: ResponsiveBreakpoints.responsiveValue(
                  context,
                  compact: 22.0,
                  medium: 24.0,
                  expanded: 28.0,
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
                  color: Theme.of(context).brightness == Brightness.dark
                      ? kPrimaryColor
                      : const Color(0xFF078829),
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
                      ? kPrimaryColor
                      : kPrimaryColor.withValues(alpha: 0.3),
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
          color: kPrimaryColor.withValues(alpha: 0.3),
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
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.black.withValues(alpha: 0.4),
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
    final columns = ResponsiveBreakpoints.responsiveGridColumns(context);
    final spacing = ResponsiveBreakpoints.responsiveValue(
      context,
      compact: 16.0,
      medium: 20.0,
      expanded: 24.0,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.take(6).length,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: 0.75,
        ),
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            key: ValueKey('product_${product.id}'),
            imageUrl: product.images.isNotEmpty ? product.images.first : '',
            title: product.title,
            price: 'TZS ${product.price.toStringAsFixed(2)}',
            category: product.category,
            rating: product.rating,
            reviewCount: product.reviewCount,
            onTap: () => Navigator.pushNamed(
              context,
              '/product-details',
              arguments: product.id,
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
              child: NetworkImageWithFallback(
                imageUrl: service.images.isNotEmpty ? service.images.first : '',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
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
                  'TZS ${service.price.toStringAsFixed(2)}${service.priceType == 'per_hour'
                      ? '/hour'
                      : service.priceType == 'per_day'
                      ? '/day'
                      : ''}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF078829),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service.category,
                  style: Theme.of(context).textTheme.bodySmall,
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
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: kTextSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        service.location,
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
    final columns = ResponsiveBreakpoints.responsiveGridColumns(context);
    final spacing = ResponsiveBreakpoints.responsiveValue(
      context,
      compact: 8.0,
      medium: 12.0,
      expanded: 16.0,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: accommodations.take(6).length,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: ResponsiveBreakpoints.responsiveValue(
            context,
            compact: 0.65,
            medium: 0.7,
            expanded: 0.75,
          ),
        ),
        itemBuilder: (context, index) {
          final accommodation = accommodations[index];
          return AccommodationCard(
            key: ValueKey('accommodation_${accommodation.id}'),
            imageUrl: accommodation.images.isNotEmpty
                ? accommodation.images.first
                : '',
            title: accommodation.name,
            price: 'TZS ${accommodation.price.toStringAsFixed(2)}',
            priceType: accommodation.priceType,
            location: accommodation.location,
            bedrooms: accommodation.bedrooms,
            bathrooms: accommodation.bathrooms,
            onTap: () => Navigator.pushNamed(
              context,
              '/accommodation-details',
              arguments: accommodation.id,
            ),
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
                      ? kPrimaryColor
                      : kPrimaryColor.withValues(alpha: 0.3),
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

  const _AnimatedPromotionText({
    super.key,
    required this.text,
    required this.fontSize,
    required this.fontWeight,
    required this.maxLines,
    this.delay = Duration.zero,
    this.shouldAnimate = true,
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
                  child: ShaderMask(
                    shaderCallback: (bounds) {
                      // Create vibrant gradient for title, bright accent for subtitle
                      final isTitle = widget.fontWeight == FontWeight.bold;
                      if (isTitle) {
                        // Vibrant yellow to orange gradient for title
                        return LinearGradient(
                          colors: [
                            const Color(0xFFFFD700), // Gold
                            const Color(0xFFFFA500), // Orange
                            const Color(0xFFFF6B35), // Bright orange-red
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds);
                      } else {
                        // Bright cyan/light blue for subtitle
                        return LinearGradient(
                          colors: [
                            const Color(0xFF00E5FF), // Bright cyan
                            const Color(0xFF40E0D0), // Turquoise
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds);
                      }
                    },
                    child: Text(
                      letter,
                      style: TextStyle(
                        color: Colors.white, // Required for ShaderMask
                        fontSize: widget.fontSize,
                        fontWeight: widget.fontWeight,
                        height: 1.2,
                        shadows: [
                          // Enhanced shadow for better contrast
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            blurRadius: 8 * _scaleAnimations[index].value,
                            offset: Offset(
                              2,
                              3 * _scaleAnimations[index].value,
                            ),
                          ),
                          // Additional glow effect
                          Shadow(
                            color: widget.fontWeight == FontWeight.bold
                                ? const Color(0xFFFFD700).withValues(alpha: 0.5)
                                : const Color(
                                    0xFF00E5FF,
                                  ).withValues(alpha: 0.5),
                            blurRadius: 12 * _scaleAnimations[index].value,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
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
