import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/config/supabase_config.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/middleware/subscription_middleware.dart';
import 'package:mwanachuo/core/services/logger_service.dart';
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
        _canAccessMessages = true; // Allow access if not logged in (shouldn't happen)
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

      // For sellers, check subscription
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

          return Stack(
            children: [
              // Conversation List
              Padding(
                padding: EdgeInsets.only(
                  top: ResponsiveBreakpoints.responsiveValue(
                    context,
                    compact: 84.0,
                    medium: 80.0,
                    expanded: 0.0,
                  ),
                ),
                child: ResponsiveContainer(
                  child: _buildConversationsList(isDarkMode, screenSize),
                ),
              ),
              // Sticky Top App Bar
              _buildTopAppBar(isDarkMode, screenSize),
              // Floating Action Button (only for compact/medium)
              if (!isExpanded) _buildFloatingActionButton(context, screenSize),
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
                const CircularProgressIndicator(color: kPrimaryColor),
                const SizedBox(height: 16),
                Text(
                  'Loading conversations...',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        // Show error only if we don't have cached conversations
        if (state is MessageError && _cachedConversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<MessageBloc>().add(
                      const LoadConversationsEvent(),
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No conversations yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start browsing to connect with sellers',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
              ],
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
            itemCount: conversationsToShow.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 0,
              indent: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 88.0,
                medium: 96.0,
                expanded: 104.0,
              ),
            ),
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
              _buildTopAppBar(isDarkMode, ScreenSize.expanded),
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

  Widget _buildTopAppBar(bool isDarkMode, ScreenSize screenSize) {
    final horizontalPadding = screenSize == ScreenSize.expanded
        ? 16.0
        : ResponsiveBreakpoints.responsiveHorizontalPadding(context);
    final isExpanded = screenSize == ScreenSize.expanded;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          height: ResponsiveBreakpoints.responsiveValue(
            context,
            compact: 84.0,
            medium: 80.0,
            expanded: 64.0,
          ),
          color: isDarkMode
              ? kBackgroundColorDark.withValues(alpha: 0.8)
              : kBackgroundColorLight.withValues(alpha: 0.8),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            screenSize == ScreenSize.expanded ? 16.0 : 48.0,
            horizontalPadding,
            8.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back/Home Button
              SizedBox(
                width: 48,
                child: IconButton(
                  icon: Icon(
                    isExpanded ? Icons.home : Icons.arrow_back,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  onPressed: () {
                    if (isExpanded) {
                      Navigator.pushReplacementNamed(context, '/home');
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
              // Title
              Expanded(
                child: Text(
                  'Messages',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: ResponsiveBreakpoints.responsiveValue(
                      context,
                      compact: 20.0,
                      medium: 22.0,
                      expanded: 20.0,
                    ),
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              // Search Button
              SizedBox(
                width: 48,
                child: IconButton(
                  icon: Icon(Icons.search),
                  color: isDarkMode ? Colors.white : Colors.black87,
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

  Widget _buildFloatingActionButton(
    BuildContext context,
    ScreenSize screenSize,
  ) {
    final fabPosition = ResponsiveBreakpoints.responsiveValue(
      context,
      compact: 24.0,
      medium: 32.0,
      expanded: 40.0,
    );

    return Positioned(
      bottom: fabPosition,
      right: fabPosition,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9999),
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withValues(alpha: 0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            // Handle new chat action
          },
          backgroundColor: kPrimaryColor,
          foregroundColor: kBackgroundColorDark,
          label: Text(
            'New Chat',
            style: GoogleFonts.plusJakartaSans(
              fontSize: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 16.0,
                medium: 17.0,
                expanded: 18.0,
              ),
              fontWeight: FontWeight.bold,
              color: kBackgroundColorDark,
            ),
          ),
          icon: Icon(Icons.edit, color: kBackgroundColorDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
          elevation: 0,
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
    // Use the isDarkMode parameter passed to the widget
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black87;
    // Use effectiveUnreadCount which returns 0 for self-conversations
    final hasUnread = conversation.effectiveUnreadCount > 0;
    final lastMessageColor = hasUnread 
        ? (isDarkMode ? Colors.white : Colors.black87)
        : (isDarkMode ? Colors.grey[400]! : Colors.grey[600]!);
    final lastMessageWeight = hasUnread ? FontWeight.bold : FontWeight.normal;
    final horizontalPadding = screenSize == ScreenSize.expanded
        ? 16.0
        : ResponsiveBreakpoints.responsiveHorizontalPadding(context);
    final avatarSize = ResponsiveBreakpoints.responsiveValue(
      context,
      compact: 56.0,
      medium: 64.0,
      expanded: 56.0,
    );

    return InkWell(
      onTap: onTap,
      onLongPress: () => _showDeleteDialog(context),
      child: Container(
        color: isSelected ? Colors.grey[100] : Colors.transparent,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 8.0,
              medium: 12.0,
              expanded: 12.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture with Online Indicator
              Stack(
                children: [
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kPrimaryColor.withValues(alpha: 0.3),
                    ),
                    child: ClipOval(
                      child: NetworkImageWithFallback(
                        imageUrl: conversation.otherUserAvatar ?? '',
                        width: avatarSize,
                        height: avatarSize,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (conversation.isOnline)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(
                width: ResponsiveBreakpoints.responsiveValue(
                  context,
                  compact: 16.0,
                  medium: 20.0,
                  expanded: 24.0,
                ),
              ),
              // Message Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text(
                      conversation.otherUserName,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: ResponsiveBreakpoints.responsiveValue(
                          context,
                          compact: 16.0,
                          medium: 17.0,
                          expanded: 18.0,
                        ),
                        fontWeight: hasUnread
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: primaryTextColor,
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveBreakpoints.responsiveValue(
                        context,
                        compact: 4.0,
                        medium: 6.0,
                        expanded: 8.0,
                      ),
                    ),
                    Text(
                      conversation.lastMessage ?? 'No messages yet',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: ResponsiveBreakpoints.responsiveValue(
                          context,
                          compact: 14.0,
                          medium: 15.0,
                          expanded: 16.0,
                        ),
                        fontWeight: lastMessageWeight,
                        color: lastMessageColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Timestamp and Unread Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text(
                    _formatTime(conversation.lastMessageTime),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: ResponsiveBreakpoints.responsiveValue(
                        context,
                        compact: 12.0,
                        medium: 13.0,
                        expanded: 14.0,
                      ),
                      fontWeight: FontWeight.normal,
                      color: isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
                    ),
                  ),
                  // Only show badge for actual unread messages (not self-conversations)
                  if (conversation.effectiveUnreadCount > 0) ...[
                    SizedBox(
                      height: ResponsiveBreakpoints.responsiveValue(
                        context,
                        compact: 6.0,
                        medium: 8.0,
                        expanded: 10.0,
                      ),
                    ),
                    Container(
                      width: ResponsiveBreakpoints.responsiveValue(
                        context,
                        compact: 24.0,
                        medium: 28.0,
                        expanded: 32.0,
                      ),
                      height: ResponsiveBreakpoints.responsiveValue(
                        context,
                        compact: 24.0,
                        medium: 28.0,
                        expanded: 32.0,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: kPrimaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        conversation.effectiveUnreadCount.toString(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: ResponsiveBreakpoints.responsiveValue(
                            context,
                            compact: 12.0,
                            medium: 13.0,
                            expanded: 14.0,
                          ),
                          fontWeight: FontWeight.bold,
                          color: kBackgroundColorDark,
                        ),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      height: ResponsiveBreakpoints.responsiveValue(
                        context,
                        compact: 30.0,
                        medium: 36.0,
                        expanded: 42.0,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
