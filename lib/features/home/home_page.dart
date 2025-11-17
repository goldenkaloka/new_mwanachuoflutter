import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/widgets/network_image_with_fallback.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/core/services/university_service.dart';
import 'package:mwanachuo/core/widgets/app_card.dart';
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
import 'package:mwanachuo/features/auth/presentation/bloc/auth_event.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';

// --- HOME PAGE WIDGET ---

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedChipIndex = 0;
  int _selectedIndex = 0; // For Bottom Nav Bar
  String? _selectedUniversity;
  String? _selectedUniversityLogo;
  bool _isLoadingUniversity = true;
  String _userName = 'User';
  bool _isLoadingUser = true;
  String _userRole = 'buyer';
  bool _dataLoaded = false; // Flag to prevent double loading
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Verify user has completed registration (should never fail due to guards)
    _verifyUserHasUniversities();
    
    // Load university and user data
    // Note: _loadSelectedUniversity() will call _loadDataForUniversity() when complete
    _loadSelectedUniversity();
    _loadUserDataFromAuth();
    
    // Load promotions immediately (universal, no university required)
    context.read<PromotionCubit>().loadActivePromotions();
  }
  
  void _verifyUserHasUniversities() {
    // Final safety check - users should have universities to be here
    // Registration transaction enforces this, but check anyway
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      if (authState.user.universityId == null) {
        debugPrint('❌ CRITICAL: User on homepage without universities!');
        debugPrint('🔄 Redirecting to university selection...');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/signup-university-selection');
          }
        });
      } else {
        debugPrint('✅ User has university: ${authState.user.universityId}');
      }
    }
  }

  void _loadUserDataFromAuth() {
    // Get user data from AuthBloc by dispatching CheckAuthStatus event
    context.read<AuthBloc>().add(const CheckAuthStatusEvent());
  }

  void _loadDataForUniversity() {
    // Prevent double loading
    if (_dataLoaded) {
      debugPrint('⏭️  Data already loaded, skipping...');
      return;
    }
    
    debugPrint('📊 Loading university data (products, services, accommodations)...');
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSelectedUniversity() async {
    final university = await UniversityService.getSelectedUniversity();
    final logo = await UniversityService.getSelectedUniversityLogo();
    setState(() {
      _selectedUniversity = university;
      _selectedUniversityLogo = logo;
      _isLoadingUniversity = false;
    });

    // Load data after university is loaded
    _loadDataForUniversity();
  }

  // Simulated Chip Data
  final List<String> _chips = [
    'All',
    'Products',
    'Accommodations',
    'Services',
    'Promotions',
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? Colors.white : kBackgroundColorDark;
    final secondaryTextColor = isDarkMode ? Colors.white70 : kTextSecondary;
    final searchBgColor = isDarkMode ? kBackgroundColorDark : Colors.white;
    final searchBorderColor = isDarkMode ? Colors.white10 : Colors.transparent;
    final isExpanded = ResponsiveBreakpoints.isExpanded(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // Only update if data actually changed to prevent rebuilds
          if (_userName != state.user.name || 
              _userRole != state.user.role.value || 
              _isLoadingUser) {
            setState(() {
              _userName = state.user.name;
              _userRole = state.user.role.value;
              _isLoadingUser = false;
            });
          }
        }
      },
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

            return Stack(
        children: [
          // Main Scrollable Content
          SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: ResponsiveBreakpoints.isCompact(context)
                        ? 120
                        : (isMedium ? 80 : 0),
                  ),
                  child: ResponsiveContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                        // 1. Top App Bar
                        _buildTopAppBar(context, primaryTextColor, screenSize),

                // 2. Search Bar
                _buildSearchBar(
                  searchBgColor,
                  searchBorderColor,
                  primaryTextColor,
                  secondaryTextColor,
                          screenSize,
                        ),

                        // 2.5. University Branding Header
                        if (_selectedUniversity != null &&
                            !_isLoadingUniversity)
                          _buildUniversityHeader(
                            context,
                            primaryTextColor,
                            screenSize,
                ),

                // 3. Chips (Categories)
                        _buildChipsRow(screenSize),

                        // 4. Promotions Section
                        _buildSectionHeader(
                          'Promotions',
                          Icons.local_offer,
                          primaryTextColor,
                          screenSize,
                        ),
                        _buildPromotionsSection(screenSize),

                        // 5. Products Section
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

                // Bottom Navigation Bar (for compact and medium screens)
                if (ResponsiveBreakpoints.isCompact(context) || isMedium)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
                    child: _buildBottomNavBar(isDarkMode, isMedium),
                  ),
              ],
            );
          },
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
          child: Stack(
            children: [
              SingleChildScrollView(
                child: ResponsiveContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopAppBar(
                        context,
                        primaryTextColor,
                        ScreenSize.expanded,
                      ),
                      _buildSearchBar(
                        searchBgColor,
                        searchBorderColor,
                        primaryTextColor,
                        secondaryTextColor,
                        ScreenSize.expanded,
                      ),
                      // University Branding Header
                      if (_selectedUniversity != null && !_isLoadingUniversity)
                        _buildUniversityHeader(
                          context,
                          primaryTextColor,
                          ScreenSize.expanded,
                        ),
                      _buildChipsRow(ScreenSize.expanded),
                      // Promotions Section
                      _buildSectionHeader(
                        'Promotions',
                        Icons.local_offer,
                        primaryTextColor,
                        ScreenSize.expanded,
                      ),
                      _buildPromotionsSection(ScreenSize.expanded),
                      // Products Section
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
                  : color
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
                  color: kPrimaryColor.withValues(alpha: 0.3),
                ),
                child: NetworkImageWithFallback(
                  imageUrl: '', // User avatar will be loaded from profile
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
          // Notifications Button
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
            icon: Icon(Icons.notifications_none, color: primaryTextColor),
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

  Widget _buildUniversityHeader(
    BuildContext context,
    Color primaryTextColor,
    ScreenSize screenSize,
  ) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(
      context,
    );
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: ResponsiveBreakpoints.responsiveValue(
          context,
          compact: 12.0,
          medium: 16.0,
          expanded: 20.0,
        ),
      ),
      padding: EdgeInsets.all(
        ResponsiveBreakpoints.responsiveValue(
          context,
          compact: 12.0,
          medium: 16.0,
          expanded: 20.0,
        ),
      ),
        decoration: BoxDecoration(
        color: kPrimaryColor.withValues(alpha: isDarkMode ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: kPrimaryColor.withValues(alpha: 0.3),
          width: 1.0,
        ),
        ),
        child: Row(
          children: [
          // University Logo
          if (_selectedUniversityLogo != null)
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
                color: Colors.white.withValues(alpha: 0.2),
              ),
              child: ClipOval(
                child: NetworkImageWithFallback(
                  imageUrl: _selectedUniversityLogo!,
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
            ),
          SizedBox(
            width: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 12.0,
              medium: 16.0,
              expanded: 20.0,
            ),
          ),
          // University Name
            Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedUniversity ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    color: primaryTextColor,
                    fontSize: ResponsiveBreakpoints.responsiveValue(
                      context,
                      compact: 16.0,
                      medium: 17.0,
                      expanded: 18.0,
                    ),
                    fontWeight: FontWeight.bold,
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
                  'Campus Marketplace',
                  style: GoogleFonts.plusJakartaSans(
                    color: primaryTextColor.withValues(alpha: 0.7),
                    fontSize: ResponsiveBreakpoints.responsiveValue(
                      context,
                      compact: 12.0,
                      medium: 13.0,
                      expanded: 14.0,
                    ),
                    fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipsRow(ScreenSize screenSize) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(
      context,
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 4.0,
      ),
      child: Row(
        children: List.generate(_chips.length, (index) {
          final isSelected = index == _selectedChipIndex;
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                child: Center(
                  child: Text(
                    _chips[index],
                    style: GoogleFonts.plusJakartaSans(
                      color: isSelected
                          ? (isDarkMode ? kBackgroundColorDark : Colors.white)
                          : (isDarkMode ? Colors.white70 : kTextSecondary),
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
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

  Widget _buildBottomNavBar(bool isDarkMode, [bool isMedium = false]) {
    return Container(
      height: isMedium ? 70 : 80,
      decoration: BoxDecoration(
        color: isDarkMode ? kBackgroundColorDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black26
                : Colors.grey.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: isDarkMode ? kPrimaryColor : const Color(0xFF078829),
        unselectedItemColor: isDarkMode ? Colors.white70 : kTextSecondary,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          fontSize: isMedium ? 13.0 : 12.0,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.normal,
          fontSize: isMedium ? 13.0 : 12.0,
        ),
        iconSize: isMedium ? 26.0 : 24.0,
        onTap: (index) {
          final isSeller = _userRole == 'seller' || _userRole == 'admin';

          if (index == 0) {
            // Home tab - stay here
            setState(() {
              _selectedIndex = index;
            });
          } else if (index == 1) {
            // Search tab (same for all roles)
            Navigator.pushNamed(context, '/search', arguments: null);
          } else if (isSeller && index == 2) {
            // Dashboard tab (only for sellers/admin)
            Navigator.pushNamed(context, '/dashboard');
          } else if (isSeller && index == 3) {
            // Messages tab (sellers/admin)
            Navigator.pushNamed(context, '/messages');
          } else if (isSeller && index == 4) {
            // Profile tab (sellers/admin)
            Navigator.pushNamed(context, '/profile').then((_) {
              _loadSelectedUniversity();
            });
          } else if (!isSeller && index == 2) {
            // Messages tab (buyers)
            Navigator.pushNamed(context, '/messages');
          } else if (!isSeller && index == 3) {
            // Profile tab (buyers)
            Navigator.pushNamed(context, '/profile').then((_) {
              _loadSelectedUniversity();
            });
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        items: _userRole == 'seller' || _userRole == 'admin'
            ? const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline),
                  activeIcon: Icon(Icons.chat_bubble),
                  label: 'Messages',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ]
            : const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline),
                  activeIcon: Icon(Icons.chat_bubble),
                  label: 'Messages',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
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
      builder: (context, state) {
        if (state is ProductsLoading) {
          return _buildLoadingGrid(screenSize);
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
      builder: (context, state) {
        if (state is ServicesLoading) {
          return _buildLoadingGrid(screenSize);
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
      builder: (context, state) {
        if (state is AccommodationsLoading) {
          return _buildLoadingGrid(screenSize);
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
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(
      context,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.all(horizontalPadding),
      child: Row(
        children: promotions.take(5).map((promotion) {
          return Row(
            children: [
              _buildPromotionCard(promotion, screenSize),
              SizedBox(
                width: ResponsiveBreakpoints.responsiveValue(
                  context,
                  compact: 16.0,
                  medium: 18.0,
                  expanded: 24.0,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPromotionCard(PromotionEntity promotion, ScreenSize screenSize) {
    final cardWidth = ResponsiveBreakpoints.responsiveValue(
      context,
      compact: 300.0,
      medium: 320.0,
      expanded: 400.0,
    );
    final cardHeight = ResponsiveBreakpoints.responsiveValue(
      context,
      compact: 180.0,
      medium: 200.0,
      expanded: 280.0,
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
        borderRadius: BorderRadius.circular(16.0),
        color: kPrimaryColor.withValues(alpha: 0.3),
      ),
      child: Stack(
        children: [
            if (promotion.imageUrl != null)
          NetworkImageWithFallback(
                imageUrl: promotion.imageUrl!,
                width: cardWidth,
                height: cardHeight,
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
                color: Colors.black.withValues(alpha: 0.4),
            ),
            alignment: Alignment.bottomLeft,
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
                Text(
                    promotion.title,
                    style: TextStyle(
                    color: Colors.white,
                      fontSize: ResponsiveBreakpoints.responsiveValue(
                        context,
                        compact: 18.0,
                        medium: 20.0,
                        expanded: 24.0,
                      ),
                    fontWeight: FontWeight.bold,
                  ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                ),
                  if (promotion.subtitle.isNotEmpty)
                Text(
                      promotion.subtitle,
                      style: TextStyle(
                    color: Colors.white,
                        fontSize: ResponsiveBreakpoints.responsiveValue(
                          context,
                          compact: 14.0,
                          medium: 16.0,
                          expanded: 18.0,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                ),
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
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: 0.75,
        ),
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            imageUrl: product.images.isNotEmpty ? product.images.first : '',
            title: product.title,
            price: 'Ksh ${product.price.toStringAsFixed(2)}',
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
        itemCount: services.take(6).length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: 0.75,
        ),
        itemBuilder: (context, index) {
          final service = services[index];
          return ServiceCard(
            imageUrl: service.images.isNotEmpty ? service.images.first : '',
            title: service.title,
            price: 'Ksh ${service.price.toStringAsFixed(2)}',
            priceType: service.priceType,
            category: service.category,
            providerName: service.providerName,
            location: service.location,
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
      compact: 16.0,
      medium: 20.0,
      expanded: 24.0,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: accommodations.take(6).length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: 0.75,
        ),
        itemBuilder: (context, index) {
          final accommodation = accommodations[index];
          return AccommodationCard(
            imageUrl: accommodation.images.isNotEmpty ? accommodation.images.first : '',
            title: accommodation.name,
            price: 'Ksh ${accommodation.price.toStringAsFixed(2)}',
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
  Widget _buildLoadingCarousel(ScreenSize screenSize) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(
      context,
    );
    return Padding(
      padding: EdgeInsets.all(horizontalPadding),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(color: kPrimaryColor),
            const SizedBox(height: 16),
            Text(
              'Loading promotions...',
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

  Widget _buildLoadingGrid(ScreenSize screenSize) {
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
