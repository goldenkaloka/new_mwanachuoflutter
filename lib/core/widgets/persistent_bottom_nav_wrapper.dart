import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/config/supabase_config.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/message_bloc.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/message_event.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/message_state.dart';

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
  String _userRole = 'buyer';
  bool _roleLoaded = false;
  int _unreadMessageCount = 0;
  bool _messageListenerSetup = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _loadUserRole().then((_) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _updateSelectedIndexFromRoute();
          }
        });
      }
    });
    _loadUnreadCount();
  }

  void _loadUnreadCount() {
    // This will be called from didChangeDependencies to access context
  }

  void _setupMessageListener(BuildContext context) {
    if (_messageListenerSetup) return; // Prevent multiple setups
    _messageListenerSetup = true;

    try {
      // Try to get MessageBloc from context first (provided at app level)
      MessageBloc messageBloc;
      try {
        messageBloc = context.read<MessageBloc>();
      } catch (e) {
        // If not available in context, create a new instance
        messageBloc = sl<MessageBloc>();
      }

      // Load conversations to get unread count
      messageBloc.add(const LoadConversationsEvent());

      // Listen to stream to update unread count
      messageBloc.stream.listen((state) {
        if (mounted) {
          int totalUnread = 0;
          if (state is ConversationsLoaded) {
            // Sum up all unread counts from conversations
            totalUnread = state.conversations.fold<int>(
              0,
              (sum, conv) => sum + conv.effectiveUnreadCount,
            );
          } else if (state is NewConversationUpdate) {
            // When a conversation is updated (e.g., messages marked as read),
            // reload conversations to get updated counts
            messageBloc.add(const LoadConversationsEvent());
          }
          setState(() {
            _unreadMessageCount = totalUnread;
          });
        }
      });
    } catch (e) {
      debugPrint('Failed to load message unread count: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _roleLoaded) {
        _updateSelectedIndexFromRoute();
        // Setup message listener once we have context
        _setupMessageListener(context);
      }
    });
  }

  Future<void> _loadUserRole() async {
    _selectedIndex = widget.initialIndex;
    final currentUser = SupabaseConfig.client.auth.currentUser;
    if (currentUser != null) {
      try {
        final userData = await SupabaseConfig.client
            .from('users')
            .select('role')
            .eq('id', currentUser.id)
            .single();
        if (mounted) {
          setState(() {
            _userRole = userData['role'] as String? ?? 'buyer';
            _roleLoaded = true;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _roleLoaded = true;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _roleLoaded = true;
        });
      }
    }
  }

  void _updateSelectedIndexFromRoute() {
    if (!mounted || !_roleLoaded) return;
    final route = ModalRoute.of(context);
    if (route == null) return;

    final routeName = route.settings.name;
    final isSeller = _userRole == 'seller' || _userRole == 'admin';

    int? newIndex;
    if (routeName == '/home') {
      newIndex = 0;
    } else if (routeName == '/search') {
      newIndex = 1;
    } else if (routeName == '/dashboard') {
      newIndex = isSeller ? 2 : null;
    } else if (routeName == '/mwanachuomind') {
      newIndex = isSeller ? 5 : 2;
    } else if (routeName == '/messages') {
      newIndex = isSeller ? 3 : 3;
    } else if (routeName == '/profile') {
      newIndex = isSeller ? 4 : 4;
    }

    if (newIndex != null && newIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = newIndex!;
      });
    }
  }

  void _onItemTapped(int index) {
    // Haptic feedback
    HapticFeedback.lightImpact();

    final isSeller = _userRole == 'seller' || _userRole == 'admin';

    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else if (index == 1) {
      Navigator.pushNamed(context, '/search', arguments: null);
    } else if (isSeller && index == 2) {
      Navigator.pushNamed(context, '/dashboard');
    } else if (isSeller && index == 3) {
      Navigator.pushNamed(context, '/messages');
    } else if (isSeller && index == 4) {
      Navigator.pushNamed(context, '/profile');
    } else if (isSeller && index == 5) {
      Navigator.pushNamed(context, '/mwanachuomind');
    } else if (!isSeller && index == 2) {
      Navigator.pushNamed(context, '/mwanachuomind');
    } else if (!isSeller && index == 3) {
      Navigator.pushNamed(context, '/messages');
    } else if (!isSeller && index == 4) {
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

    // Active green color from accommodation card
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
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            backgroundColor: isDarkMode
                ? const Color(0xFF1A1A1A)
                : Colors.white,
            elevation: 0,
            selectedItemColor: activeColor,
            unselectedItemColor: isDarkMode
                ? Colors.grey[500]
                : Colors.grey[600],
            showSelectedLabels: false,
            showUnselectedLabels: false,
            iconSize: 20,
            onTap: _onItemTapped,
            items: _buildNavItems(isDarkMode, activeColor),
          ),
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> _buildNavItems(
    bool isDarkMode,
    Color activeColor,
  ) {
    final isSeller = _userRole == 'seller' || _userRole == 'admin';

    // Helper to build icon with badge and enhanced styling
    Widget buildBadgedIcon(
      IconData icon,
      IconData activeIcon,
      bool isActive, {
      bool showBadge = false,
    }) {
      final iconWidget = AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(2), // Minimized padding
        constraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
          maxWidth: 40,
          maxHeight: 40,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isActive ? activeIcon : icon,
          size: isActive ? 22 : 20, // Smaller icons to prevent overflow
          color: isActive ? activeColor : null,
        ),
      );

      if (!showBadge || _unreadMessageCount == 0) {
        return iconWidget;
      }

      return Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                  width: 2,
                ),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                _unreadMessageCount > 99 ? '99+' : '$_unreadMessageCount',
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

    if (!_roleLoaded) {
      return [
        BottomNavigationBarItem(
          icon: buildBadgedIcon(
            Icons.home_outlined,
            Icons.home_rounded,
            _selectedIndex == 0,
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: buildBadgedIcon(
            Icons.search_rounded,
            Icons.search_rounded,
            _selectedIndex == 1,
          ),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: buildBadgedIcon(
            Icons.school_outlined,
            Icons.school_rounded,
            _selectedIndex == 2,
          ),
          label: 'Mwanachuomind',
        ),
        BottomNavigationBarItem(
          icon: buildBadgedIcon(
            Icons.chat_bubble_outline_rounded,
            Icons.chat_bubble_rounded,
            _selectedIndex == 3,
            showBadge: true,
          ),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: buildBadgedIcon(
            Icons.person_outline_rounded,
            Icons.person_rounded,
            _selectedIndex == 4,
          ),
          label: 'Profile',
        ),
      ];
    }

    if (isSeller) {
      return [
        BottomNavigationBarItem(
          icon: buildBadgedIcon(
            Icons.home_outlined,
            Icons.home_rounded,
            _selectedIndex == 0,
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: buildBadgedIcon(
            Icons.search_rounded,
            Icons.search_rounded,
            _selectedIndex == 1,
          ),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: buildBadgedIcon(
            Icons.dashboard_outlined,
            Icons.dashboard_rounded,
            _selectedIndex == 2,
          ),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: buildBadgedIcon(
            Icons.chat_bubble_outline_rounded,
            Icons.chat_bubble_rounded,
            _selectedIndex == 3,
            showBadge: true,
          ),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: buildBadgedIcon(
            Icons.person_outline_rounded,
            Icons.person_rounded,
            _selectedIndex == 4,
          ),
          label: 'Profile',
        ),
        BottomNavigationBarItem(
          icon: buildBadgedIcon(
            Icons.school_outlined,
            Icons.school_rounded,
            _selectedIndex == 5,
          ),
          label: 'Mwanachuomind',
        ),
      ];
    } else {
      return [
        BottomNavigationBarItem(
          icon: buildBadgedIcon(
            Icons.home_outlined,
            Icons.home_rounded,
            _selectedIndex == 0,
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: buildBadgedIcon(
            Icons.search_rounded,
            Icons.search_rounded,
            _selectedIndex == 1,
          ),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: buildBadgedIcon(
            Icons.school_outlined,
            Icons.school_rounded,
            _selectedIndex == 2,
          ),
          label: 'Mwanachuomind',
        ),
        BottomNavigationBarItem(
          icon: buildBadgedIcon(
            Icons.chat_bubble_outline_rounded,
            Icons.chat_bubble_rounded,
            _selectedIndex == 3,
            showBadge: true,
          ),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: buildBadgedIcon(
            Icons.person_outline_rounded,
            Icons.person_rounded,
            _selectedIndex == 4,
          ),
          label: 'Profile',
        ),
      ];
    }
  }
}
