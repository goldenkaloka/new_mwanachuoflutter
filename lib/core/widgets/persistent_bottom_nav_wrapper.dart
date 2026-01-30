import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    } else if (routeName == '/listings' || routeName == '/browse-listings') {
      newIndex = 1;
    } else if (routeName == '/copilot') {
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
      Navigator.pushNamed(context, '/listings', arguments: null);
    } else if (index == 2) {
      Navigator.pushNamed(context, '/copilot');
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

    const activeColor = Color(0xFF078829);

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
              children: _buildNavItems(isDarkMode, activeColor),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNavItems(bool isDarkMode, Color activeColor) {
    Widget buildNavItem({
      required int index,
      required IconData icon,
      required IconData activeIcon,
      required String label,
      bool showBadge = false,
    }) {
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
                    isSpecial: index == 2,
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

    return [
      buildNavItem(
        index: 0,
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Home',
      ),
      buildNavItem(
        index: 1,
        icon: Icons.view_list_rounded,
        activeIcon: Icons.view_list_rounded,
        label: 'Listings',
      ),
      buildNavItem(
        index: 2,
        icon: Icons.auto_awesome_outlined,
        activeIcon: Icons.auto_awesome,
        label: 'Copilot',
      ),
      buildNavItem(
        index: 3,
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: 'Dashboard',
      ),
      buildNavItem(
        index: 4,
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Profile',
      ),
    ];
  }

  Widget _buildIcon({
    required IconData icon,
    required IconData activeIcon,
    required bool isActive,
    required Color activeColor,
    required bool isDarkMode,
    bool showBadge = false,
    bool isSpecial = false,
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
