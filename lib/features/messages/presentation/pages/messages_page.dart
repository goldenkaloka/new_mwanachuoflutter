import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/config/supabase_config.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/middleware/subscription_middleware.dart';
import 'package:mwanachuo/core/services/logger_service.dart';
import 'package:mwanachuo/core/services/subscription_cache_service.dart';
import 'package:mwanachuo/core/utils/time_formatter.dart';
import 'package:mwanachuo/core/widgets/network_image_with_fallback.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/message_bloc.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/message_event.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/message_state.dart';
import 'package:mwanachuo/features/messages/domain/entities/conversation_entity.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MessagesView();
  }
}

class _MessagesView extends StatefulWidget {
  const _MessagesView();

  @override
  State<_MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<_MessagesView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Store conversations in widget state to persist across navigation
  List<ConversationEntity> _cachedConversations = [];
  bool _isInitialLoad = true;
  bool? _canAccessMessages;
  bool _isCheckingSubscription = true;

  @override
  void initState() {
    super.initState();
    // Check subscription first, then load conversations
    _checkSubscriptionAndLoad();
  }

  Future<void> _checkSubscriptionAndLoad() async {
    final currentUser = SupabaseConfig.client.auth.currentUser;
    if (currentUser == null) {
      setState(() {
        _canAccessMessages =
            true; // Allow access if not logged in (shouldn't happen)
        _isCheckingSubscription = false;
      });
      _loadConversations();
      return;
    }

    // Check if user is seller/admin
    try {
      final userData = await SupabaseConfig.client
          .from('users')
          .select('role')
          .eq('id', currentUser.id)
          .single();

      final role = userData['role'] as String?;
      final isSeller = role == 'seller' || role == 'admin';

      if (!isSeller) {
        // Buyers can always access messages
        setState(() {
          _canAccessMessages = true;
          _isCheckingSubscription = false;
        });
        _loadConversations();
        return;
      }

      // For sellers, check subscription (with cache - won't show loader if cached)
      // First check cache synchronously to avoid showing loader
      final cachedAccess = SubscriptionCacheService().getCachedAccess(
        currentUser.id,
      );
      if (cachedAccess != null) {
        // Cache hit - no loader needed
        setState(() {
          _canAccessMessages = cachedAccess;
          _isCheckingSubscription = false;
        });
        if (cachedAccess) {
          _loadConversations();
        }
        // Still refresh in background
        SubscriptionMiddleware.canAccessMessages(sellerId: currentUser.id);
        return;
      }

      // Check persisted cache
      final persistedAccess = await SubscriptionCacheService()
          .getPersistedAccess(currentUser.id);
      if (persistedAccess != null) {
        setState(() {
          _canAccessMessages = persistedAccess;
          _isCheckingSubscription = false;
        });
        if (persistedAccess) {
          _loadConversations();
        }
        // Still refresh in background
        SubscriptionMiddleware.canAccessMessages(sellerId: currentUser.id);
        return;
      }

      // Cache miss - show loader and check subscription
      final canAccess = await SubscriptionMiddleware.canAccessMessages(
        sellerId: currentUser.id,
      );

      setState(() {
        _canAccessMessages = canAccess;
        _isCheckingSubscription = false;
      });

      if (canAccess) {
        _loadConversations();
      }
    } catch (e) {
      // On error, allow access (fail open)
      LoggerService.error('Error checking subscription for messages', e);
      setState(() {
        _canAccessMessages = true;
        _isCheckingSubscription = false;
      });
      _loadConversations();
    }
  }

  void _loadConversations() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final bloc = context.read<MessageBloc>();
        final currentState = bloc.state;

        // If we already have conversations loaded, cache them
        if (currentState is ConversationsLoaded) {
          LoggerService.debug(
            'Conversations already loaded, count: ${currentState.conversations.length}',
          );
          _cachedConversations = currentState.conversations;
          _isInitialLoad = false;
        } else {
          // Load conversations for the first time
          LoggerService.info('Loading conversations for the first time');
          bloc.add(const LoadConversationsEvent());
        }

        // Start real-time listening
        bloc.add(StartListeningToConversationsEvent());
      }
    });
  }

  @override
  void dispose() {
    // Don't stop listening when just navigating away temporarily
    // The subscription will stay active for real-time updates
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Show loading while checking subscription
    if (_isCheckingSubscription) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: kPrimaryColor),
              const SizedBox(height: 16),
              Text(
                'Checking subscription...',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show blocking screen if subscription expired
    if (_canAccessMessages == false) {
      return _buildSubscriptionBlockedScreen(context);
    }

    // Show normal messages page
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isExpanded = ResponsiveBreakpoints.isExpanded(context);

    return Scaffold(
      body: ResponsiveBuilder(
        builder: (context, screenSize) {
          if (isExpanded) {
            return _buildExpandedLayout(context, isDarkMode);
          }

          // Get safe area padding
          final safeAreaTop = MediaQuery.of(context).padding.top;
          final appBarHeight = ResponsiveBreakpoints.responsiveValue(
            context,
            compact: 70.0,
            medium: 68.0,
            expanded: 64.0,
          );
          final totalTopPadding = appBarHeight + safeAreaTop;

          return Stack(
            children: [
              // Conversation List
              Padding(
                padding: EdgeInsets.only(
                  top: totalTopPadding,
                ),
                child: ResponsiveContainer(
                  child: _buildConversationsList(isDarkMode, screenSize),
                ),
              ),
              // Sticky Top App Bar
              _buildTopAppBar(context, isDarkMode, screenSize),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSubscriptionBlockedScreen(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(height: 24),
              Text(
                'Subscription Required',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your subscription has expired. Please renew your subscription to access messages.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/subscription-plans');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: Text(
                  'Renew Subscription',
                  style: GoogleFonts.plusJakartaSans(
                    color: kBackgroundColorDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Note: You will still receive notifications for new messages.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversationsList(bool isDarkMode, ScreenSize screenSize) {
    return BlocConsumer<MessageBloc, MessageState>(
      listener: (context, state) {
        // Update cached conversations whenever we get new data
        if (state is ConversationsLoaded) {
          setState(() {
            _cachedConversations = state.conversations;
            _isInitialLoad = false;
          });
          LoggerService.debug(
            'Updated cached conversations: ${state.conversations.length}',
          );
        }
      },
      builder: (context, state) {
        // Show loading ONLY on very first load with no cached data (WhatsApp-style)
        if (_cachedConversations.isEmpty &&
            state is ConversationsLoading &&
            _isInitialLoad) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.grey[800]!.withValues(alpha: 0.3)
                        : kPrimaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const CircularProgressIndicator(
                    color: kPrimaryColor,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Loading conversations...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        // Show error only if we don't have cached conversations
        if (state is MessageError && _cachedConversations.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Oops! Something went wrong',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<MessageBloc>().add(
                        const LoadConversationsEvent(),
                      );
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Use cached conversations or newly loaded ones
        final conversationsToShow = state is ConversationsLoaded
            ? state.conversations
            : _cachedConversations;

        LoggerService.debug(
          'Showing conversations: ${conversationsToShow.length} (from ${state is ConversationsLoaded ? "state" : "cache"})',
        );

        // Show empty state only if we truly have no conversations
        if (conversationsToShow.isEmpty && !_isInitialLoad) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.grey[800]!.withValues(alpha: 0.3)
                          : kPrimaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 64,
                      color: isDarkMode
                          ? Colors.grey[500]
                          : kPrimaryColor.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No conversations yet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start browsing to connect with sellers',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<MessageBloc>().add(
              const LoadConversationsEvent(forceRefresh: true),
            );
            // Wait a bit for the refresh to complete
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: kPrimaryColor,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              vertical: 8,
              horizontal: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 0,
                medium: 8,
                expanded: 16,
              ),
            ),
            itemCount: conversationsToShow.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final conversation = conversationsToShow[index];
              return ConversationListItem(
                conversation: conversation,
                isDarkMode: isDarkMode,
                screenSize: screenSize,
                onTap: () async {
                  final conversationId = conversation.id;

                  // Navigate to chat and wait for return
                  await Navigator.pushNamed(
                    context,
                    '/chat',
                    arguments: conversationId,
                  );

                  // When user returns from chat, update the cached conversation to mark as read
                  // This provides instant visual feedback (optimistic UI update)
                  if (mounted) {
                    setState(() {
                      _cachedConversations = _cachedConversations.map((conv) {
                        // Update unread count to 0 for the viewed conversation
                        return conv.id == conversationId
                            ? conv.copyWith(unreadCount: 0)
                            : conv;
                      }).toList();
                    });

                    // Also reload from server to get accurate data
                    if (context.mounted) {
                      context.read<MessageBloc>().add(
                        const LoadConversationsEvent(forceRefresh: true),
                      );
                    }
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildExpandedLayout(BuildContext context, bool isDarkMode) {
    return Row(
      children: [
        // Left Sidebar - Conversations List
        Container(
          width: 400,
          decoration: BoxDecoration(
            color: isDarkMode ? kBackgroundColorDark : Colors.white,
            border: Border(
              right: BorderSide(
                color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              _buildTopAppBar(context, isDarkMode, ScreenSize.expanded),
              Expanded(
                child: _buildConversationsList(isDarkMode, ScreenSize.expanded),
              ),
            ],
          ),
        ),
        // Right Side - Chat View or Empty State
        Expanded(
          child: Container(
            color: isDarkMode ? kBackgroundColorDark : kBackgroundColorLight,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.desktop_windows,
                    size: 64,
                    color: kPrimaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Desktop Chat View',
                    style: GoogleFonts.plusJakartaSans(
                      color: isDarkMode ? Colors.white70 : Colors.grey[600],
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click conversation to open in full screen',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopAppBar(
    BuildContext context,
    bool isDarkMode,
    ScreenSize screenSize,
  ) {
    final horizontalPadding = screenSize == ScreenSize.expanded
        ? 16.0
        : ResponsiveBreakpoints.responsiveHorizontalPadding(context);
    final isExpanded = screenSize == ScreenSize.expanded;
    final surfaceColor = isDarkMode
        ? Colors.grey[900]!.withValues(alpha: 0.95)
        : Colors.white.withValues(alpha: 0.95);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: ResponsiveBreakpoints.responsiveValue(
            context,
            compact: 70.0,
            medium: 68.0,
            expanded: 64.0,
          ),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            screenSize == ScreenSize.expanded ? 12.0 : 8.0,
            horizontalPadding,
            12.0,
          ),
          child: Row(
            children: [
              // Back/Home Button with better styling
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.grey[800]!.withValues(alpha: 0.5)
                      : Colors.grey[100]!.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    isExpanded ? Icons.home_rounded : Icons.arrow_back_rounded,
                    size: 20,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    if (isExpanded) {
                      Navigator.pushReplacementNamed(context, '/home');
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Title
              Expanded(
                child: Text(
                  'Messages',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: ResponsiveBreakpoints.responsiveValue(
                      context,
                      compact: 22.0,
                      medium: 24.0,
                      expanded: 22.0,
                    ),
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              // Search Button with better styling
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.grey[800]!.withValues(alpha: 0.5)
                      : Colors.grey[100]!.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.search_rounded, size: 20),
                  color: isDarkMode ? Colors.white : Colors.black87,
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    // Handle search action
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConversationListItem extends StatelessWidget {
  final ConversationEntity conversation;
  final bool isDarkMode;
  final ScreenSize screenSize;
  final bool isSelected;
  final VoidCallback onTap;

  const ConversationListItem({
    super.key,
    required this.conversation,
    required this.isDarkMode,
    required this.screenSize,
    this.isSelected = false,
    required this.onTap,
  });

  String _formatTime(DateTime? time) {
    return TimeFormatter.formatConversationTime(time);
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text(
          'Delete this conversation with ${conversation.otherUserName}?\n\nThis will only remove it for you. ${conversation.otherUserName} will still have access to the messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Dispatch delete event
              context.read<MessageBloc>().add(
                DeleteConversationEvent(conversationId: conversation.id),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final hasUnread = conversation.effectiveUnreadCount > 0;
    final horizontalPadding = screenSize == ScreenSize.expanded
        ? 16.0
        : ResponsiveBreakpoints.responsiveHorizontalPadding(context);

    return Dismissible(
      key: Key(conversation.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        context.read<MessageBloc>().add(
          DeleteConversationEvent(conversationId: conversation.id),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenSize == ScreenSize.expanded ? 0 : horizontalPadding,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
          leading: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: NetworkImageWithFallback(
                  imageUrl: conversation.otherUserAvatar ?? '',
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              if (conversation.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDarkMode ? kBackgroundColorDark : Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  conversation.otherUserName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                    color: primaryTextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasUnread)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                conversation.lastMessage ?? 'No messages yet',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                  color: hasUnread ? primaryTextColor : secondaryTextColor,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
          trailing: SizedBox(
            width: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(conversation.lastMessageTime),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: secondaryTextColor,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
                if (conversation.effectiveUnreadCount > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    child: Center(
                      child: Text(
                        conversation.effectiveUnreadCount > 99
                            ? '99+'
                            : conversation.effectiveUnreadCount.toString(),
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
              ],
            ),
          ),
          onTap: onTap,
          onLongPress: () => _showDeleteDialog(context),
        ),
      ),
    );
  }
}


