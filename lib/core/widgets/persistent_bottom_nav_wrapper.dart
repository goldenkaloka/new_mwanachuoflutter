import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/utils/responsive.dart';

/// Wrapper widget that provides persistent bottom navigation bar across main pages
class PersistentBottomNavWrapper extends StatefulWidget {
  final Widget child;
  final int initialIndex;

  const PersistentBottomNavWrapper({
    super.key,
    required this.child,
    this.initialIndex = 0,
  });

  @override
  State<PersistentBottomNavWrapper> createState() =>
      _PersistentBottomNavWrapperState();
}

class _PersistentBottomNavWrapperState
    extends State<PersistentBottomNavWrapper> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateSelectedIndexFromRoute();
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateSelectedIndexFromRoute();
      }
    });
  }



  void _updateSelectedIndexFromRoute() {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route == null) return;
    final routeName = route.settings.name;

    int? newIndex;
    if (routeName == '/home') {
      newIndex = 0;
    } else if (routeName == '/food-delivery') {
      newIndex = 1;
    } else if (routeName == '/listings' || routeName == '/browse-listings') {
      newIndex = 2;
    } else if (routeName == '/dashboard') {
      newIndex = 3;
    } else if (routeName == '/profile') {
      newIndex = 4;
    }

    if (newIndex != null && newIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = newIndex!;
      });
    }
  }

  void _onItemTapped(int index) {
    HapticFeedback.lightImpact();

    setState(() {
      _selectedIndex = index;
    });


    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else if (index == 1) {
      Navigator.pushNamed(context, '/food-delivery');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/listings', arguments: null);
    } else if (index == 3) {
      Navigator.pushNamed(context, '/dashboard');
    } else if (index == 4) {
      Navigator.pushNamed(context, '/profile');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateSelectedIndexFromRoute();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isMedium = ResponsiveBreakpoints.isMedium(context);
    final isCompact = ResponsiveBreakpoints.isCompact(context);

    if (!isCompact && !isMedium) {
      return widget.child;
    }

    final activeColor = kPrimaryColor;

    // Watch AuthBloc to rebuild nav items when user role changes
    final authState = context.watch<AuthBloc>().state;
    final isBusiness =
        authState is Authenticated && authState.user.userType == 'business';

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          bottom: true,
          child: BottomAppBar(
            color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
            elevation: 0,
            notchMargin: 8,
            shape: const CircularNotchedRectangle(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _buildNavItems(isDarkMode, activeColor, isBusiness),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNavItems(
    bool isDarkMode,
    Color activeColor,
    bool isBusiness,
  ) {
    Widget buildNavItem({
      required int index,
      required IconData icon,
      required IconData activeIcon,
      required String label,
      bool showBadge = false,
    }) {
      // Current index logic:
      // Index in loop vs _selectedIndex
      //
      // If isBusiness:
      // Loop indices: 0 (Home), 1 (Listings), 2 (Dashboard), 3 (Profile)
      // _selectedIndex should match one of these.

      final isActive = _selectedIndex == index;

      return Expanded(
        child: InkWell(
          onTap: () => _onItemTapped(index),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildIcon(
                    icon: icon,
                    activeIcon: activeIcon,
                    isActive: isActive,
                    activeColor: activeColor,
                    isDarkMode: isDarkMode,
                    showBadge: showBadge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? activeColor
                          : (isDarkMode ? Colors.grey[500] : Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final items = [
      buildNavItem(
        index: 0,
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Home',
      ),
      buildNavItem(
        index: 1,
        icon: Icons.restaurant_outlined,
        activeIcon: Icons.restaurant_rounded,
        label: 'Food',
      ),
      buildNavItem(
        index: 2,
        icon: Icons.view_list_rounded,
        activeIcon: Icons.view_list_rounded,
        label: 'Listings',
      ),
    ];

    // Dashboard
    items.add(
      buildNavItem(
        index: 3,
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: 'Dashboard',
      ),
    );

    items.add(
      buildNavItem(
        index: 4,
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Profile',
      ),
    );

    return items;
  }

  Widget _buildIcon({
    required IconData icon,
    required IconData activeIcon,
    required bool isActive,
    required Color activeColor,
    required bool isDarkMode,
    bool showBadge = false,
  }) {
    final iconWidget = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isActive
            ? activeColor.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        isActive ? activeIcon : icon,
        size: isActive ? 22 : 20,
        color: isActive
            ? activeColor
            : (isDarkMode ? Colors.grey[500] : Colors.grey[600]),
      ),
    );

    if (!showBadge) {
      return iconWidget;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        iconWidget,
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFF3B30),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                width: 1.5,
              ),
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text(
              '0',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
