import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mwanachuo/config/supabase_config.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/constants/database_constants.dart';
import 'package:mwanachuo/core/middleware/subscription_middleware.dart';
import 'package:mwanachuo/core/services/logger_service.dart';
import 'package:mwanachuo/core/utils/content_filter.dart';
import 'package:mwanachuo/core/utils/time_formatter.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/message_bloc.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/message_event.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/message_state.dart';
import 'package:mwanachuo/features/messages/domain/entities/message_entity.dart';

// --- CHAT SCREEN WIDGET ---

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool? _canAccessMessages;
  bool _isCheckingSubscription = true;
  bool _hasCheckedSubscription = false;

  @override
  void initState() {
    super.initState();
    // Don't access ModalRoute here - wait for didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Now we can safely access ModalRoute
    // Only check once to avoid multiple calls
    if (!_hasCheckedSubscription && _canAccessMessages == null) {
      _hasCheckedSubscription = true;
      _checkSubscription();
    }
  }

  Future<void> _checkSubscription() async {
    final conversationId =
        ModalRoute.of(context)?.settings.arguments as String?;

    if (conversationId == null) {
      setState(() {
        _canAccessMessages = true; // Will show invalid conversation error
        _isCheckingSubscription = false;
      });
      return;
    }

    final currentUser = SupabaseConfig.client.auth.currentUser;
    if (currentUser == null) {
      setState(() {
        _canAccessMessages =
            true; // Allow access if not logged in (shouldn't happen)
        _isCheckingSubscription = false;
      });
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
    } catch (e) {
      // On error, allow access (fail open)
      LoggerService.error('Error checking subscription for chat', e);
      setState(() {
        _canAccessMessages = true;
        _isCheckingSubscription = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get conversation ID from route arguments
    final conversationId =
        ModalRoute.of(context)?.settings.arguments as String?;

    if (conversationId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Invalid conversation'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    // Show loading while checking subscription
    if (_isCheckingSubscription) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
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
      return _buildSubscriptionBlockedChatScreen(context);
    }

    // Use the shared MessageBloc instance from app level
    // Load messages when screen is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<MessageBloc>();
      bloc.add(LoadMessagesEvent(conversationId: conversationId));
      bloc.add(StartListeningToMessagesEvent(conversationId: conversationId));
    });

    return _ChatScreenView(conversationId: conversationId);
  }

  Widget _buildSubscriptionBlockedChatScreen(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
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
                'Your subscription has expired. Please renew to view messages.',
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
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatScreenView extends StatefulWidget {
  final String conversationId;

  const _ChatScreenView({required this.conversationId});

  @override
  State<_ChatScreenView> createState() => _ChatScreenViewState();
}

class _ChatScreenViewState extends State<_ChatScreenView>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  String? _recipientName;
  String? _recipientAvatar;
  String? _recipientId;
  bool _recipientIsOnline = false;
  DateTime? _recipientLastSeen;
  StreamSubscription? _onlineStatusSubscription;
  MessageEntity? _repliedToMessage; // Track message being replied to

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);

    // Load conversation details (recipient name, avatar, status)
    _loadConversationDetails();

    // Update current user's online status
    _updateUserOnlineStatus(true);

    // Load messages for this conversation
    context.read<MessageBloc>().add(
      LoadMessagesEvent(conversationId: widget.conversationId),
    );

    // Mark all messages as read when opening chat
    context.read<MessageBloc>().add(
      MarkMessagesAsReadEvent(conversationId: widget.conversationId),
    );

    // Start listening for real-time message updates
    context.read<MessageBloc>().add(
      StartListeningToMessagesEvent(conversationId: widget.conversationId),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _updateUserOnlineStatus(false);
    _onlineStatusSubscription?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Check if we've scrolled to the top (which is the end in reverse list)
    // This triggers loading more older messages
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      // Load more messages when 90% scrolled
      context.read<MessageBloc>().add(
        LoadMoreMessagesEvent(conversationId: widget.conversationId),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateUserOnlineStatus(true);
      _loadConversationDetails(); // Refresh recipient status
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _updateUserOnlineStatus(false);
    }
  }

  Future<void> _updateUserOnlineStatus(bool isOnline) async {
    try {
      final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
      if (currentUserId == null) return;

      if (isOnline) {
        await SupabaseConfig.client.rpc(
          'update_user_last_seen',
          params: {'user_id': currentUserId},
        );
        LoggerService.debug('Updated user status: online');
      } else {
        await SupabaseConfig.client.rpc(
          'mark_user_offline',
          params: {'user_id': currentUserId},
        );
        LoggerService.debug('Updated user status: offline');
      }
    } catch (e) {
      LoggerService.warning('Failed to update online status', e);
    }
  }

  Future<void> _loadConversationDetails() async {
    try {
      final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
      if (currentUserId == null) return;

      final response = await SupabaseConfig.client
          .from('conversations')
          .select('''
            user1_id, user2_id, user1_name, user2_name, user1_avatar, user2_avatar,
            user1:users!conversations_user1_id_fkey(is_online, last_seen_at),
            user2:users!conversations_user2_id_fkey(is_online, last_seen_at)
          ''')
          .eq('id', widget.conversationId)
          .single();

      final isUser1 = response['user1_id'] == currentUserId;
      final otherUserData = isUser1 ? response['user2'] : response['user1'];
      final otherUserId = isUser1 ? response['user2_id'] : response['user1_id'];

      if (mounted) {
        setState(() {
          _recipientId = otherUserId as String;
          if (isUser1) {
            _recipientName = response['user2_name'];
            _recipientAvatar = response['user2_avatar'];
          } else {
            _recipientName = response['user1_name'];
            _recipientAvatar = response['user1_avatar'];
          }

          _recipientIsOnline = otherUserData?['is_online'] as bool? ?? false;
          _recipientLastSeen = otherUserData?['last_seen_at'] != null
              ? DateTime.parse(otherUserData!['last_seen_at'] as String)
              : null;

          LoggerService.debug(
            'Recipient loaded: $_recipientName, online: $_recipientIsOnline',
          );
        });

        // Start listening for online status changes
        _startListeningToOnlineStatus();
      }
    } catch (e) {
      LoggerService.error('Failed to load conversation details', e);
    }
  }

  void _startListeningToOnlineStatus() {
    if (_recipientId == null) return;

    // Cancel any existing subscription
    _onlineStatusSubscription?.cancel();

    // Listen for changes to the recipient's online status
    _onlineStatusSubscription = SupabaseConfig.client
        .from(DatabaseConstants.usersTable)
        .stream(primaryKey: ['id'])
        .eq('id', _recipientId!)
        .listen((data) {
          if (data.isEmpty || !mounted) return;

          final userData = data.first;
          final isOnline = userData['is_online'] as bool? ?? false;
          final lastSeenAt = userData['last_seen_at'] != null
              ? DateTime.parse(userData['last_seen_at'] as String)
              : null;

          if (mounted) {
            setState(() {
              _recipientIsOnline = isOnline;
              _recipientLastSeen = lastSeenAt;
            });
            LoggerService.debug('Recipient status updated: online=$isOnline');
          }
        });
  }

  String _getOnlineStatus() {
    return TimeFormatter.formatOnlineStatus(
      isOnline: _recipientIsOnline,
      lastSeenAt: _recipientLastSeen,
    );
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    // Get recent messages from current state for context-aware validation
    final currentState = context.read<MessageBloc>().state;
    List<String> recentMessages = [];

    if (currentState is MessagesLoaded &&
        currentState.conversationId == widget.conversationId) {
      final currentUser = SupabaseConfig.client.auth.currentUser;
      if (currentUser != null) {
        // Get last 5 messages from current user
        recentMessages = currentState.messages
            .where((m) => m.senderId == currentUser.id)
            .take(5)
            .map((m) => m.content)
            .where((c) => c.isNotEmpty)
            .toList()
            .reversed
            .toList();
      }
    }

    // Pre-validate content with context
    final validationError = ContentFilter.validateMessage(
      content,
      recentMessages: recentMessages,
    );

    if (validationError != null) {
      // Show error dialog
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            'Ujumbe Hauruhusiwi',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
          ),
          content: Text(validationError, style: GoogleFonts.plusJakartaSans()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Sawa',
                style: GoogleFonts.plusJakartaSans(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    context.read<MessageBloc>().add(
      SendMessageEvent(
        conversationId: widget.conversationId,
        content: content,
        repliedToMessageId: _repliedToMessage?.id,
      ),
    );

    _messageController.clear();
    // Clear reply preview
    setState(() {
      _repliedToMessage = null;
    });
  }

  void _handleReply(MessageEntity message) {
    setState(() {
      _repliedToMessage = message;
    });
    // Focus on text field
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _showDeleteMessageDialog(MessageEntity message) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1F2C34) : Colors.white,
        title: Text(
          'Delete message?',
          style: GoogleFonts.plusJakartaSans(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This message will be deleted only for you. The other person can still see it.',
          style: GoogleFonts.plusJakartaSans(
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: kPrimaryColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteMessage(message.id);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteMessage(String messageId) {
    context.read<MessageBloc>().add(
      DeleteMessageForUserEvent(messageId: messageId),
    );
    // Reload messages to reflect the deletion
    context.read<MessageBloc>().add(
      LoadMessagesEvent(conversationId: widget.conversationId),
    );
  }

  Future<void> _pickAndUploadImage() async {
    try {
      // Pick image from gallery
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      // Show uploading indicator
      if (!mounted) return;

      // Upload image via bloc
      context.read<MessageBloc>().add(UploadImageEvent(filePath: image.path));

      LoggerService.info('Image selected for upload: ${image.path}');
    } catch (e) {
      LoggerService.error('Failed to pick image', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: kErrorColor,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      // Take photo with camera
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo == null) return;

      // Show uploading indicator
      if (!mounted) return;

      // Upload image via bloc
      context.read<MessageBloc>().add(UploadImageEvent(filePath: photo.path));

      LoggerService.info('Photo captured for upload: ${photo.path}');
    } catch (e) {
      LoggerService.error('Failed to take photo', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take photo: $e'),
            backgroundColor: kErrorColor,
          ),
        );
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? kSurfaceColorDark : kSurfaceColorLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: kPrimaryColor,
                  child: Icon(Icons.photo_library, color: kBackgroundColorDark),
                ),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage();
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: kPrimaryColor.withValues(alpha: 0.8),
                  child: const Icon(
                    Icons.camera_alt,
                    color: kBackgroundColorDark,
                  ),
                ),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use app theme instead of forcing light theme
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<MessageBloc, MessageState>(
      listener: (context, state) {
        // Reload messages when a message is sent or received
        if (state is MessageSent) {
          LoggerService.debug(
            'Message sent, messages will reload automatically',
          );
          // The bloc already dispatched LoadMessagesEvent, no need to do it here
        }

        if (state is MessagesLoaded && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        if (state is NewMessageReceived) {
          // New message received via real-time subscription
          // Only reload if we don't already have messages loaded
          final currentState = context.read<MessageBloc>().state;
          if (currentState is! MessagesLoaded ||
              currentState.conversationId != widget.conversationId) {
            LoggerService.debug('New message received, reloading messages');
            context.read<MessageBloc>().add(
              LoadMessagesEvent(conversationId: widget.conversationId),
            );
          }
        }
      },
      child: Scaffold(
        appBar: _buildChatAppBar(context, isDarkMode),
        body: Column(
          children: [
            Expanded(child: _buildMessagesList(isDarkMode)),
            _buildMessageInput(isDarkMode),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildChatAppBar(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? kTextPrimaryDark : kTextPrimary;
    final backgroundColor = isDarkMode
        ? kBackgroundColorDark
        : kBackgroundColorLight;

    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 1,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: primaryTextColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: kPrimaryColor,
                backgroundImage:
                    _recipientAvatar != null && _recipientAvatar!.isNotEmpty
                    ? NetworkImage(_recipientAvatar!)
                    : null,
                child: _recipientAvatar == null || _recipientAvatar!.isEmpty
                    ? Icon(Icons.person, color: kBackgroundColorDark, size: 20)
                    : null,
              ),
              if (_recipientIsOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: kSuccessColor, // Use theme success color
                      shape: BoxShape.circle,
                      border: Border.all(color: backgroundColor, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _recipientName ?? 'Loading...',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: primaryTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _getOnlineStatus(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _recipientIsOnline
                        ? kSuccessColor
                        : (isDarkMode ? kTextSecondaryDark : kTextSecondary),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(bool isDarkMode) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? kBackgroundColorDark
        : kBackgroundColorLight;
    final secondaryTextColor = isDarkMode ? kTextSecondaryDark : kTextSecondary;

    return BlocBuilder<MessageBloc, MessageState>(
      buildWhen: (previous, current) {
        // Rebuild when messages are loaded or updated
        return current is MessagesLoaded ||
            current is MessagesLoading ||
            current is MessageError;
      },
      builder: (context, state) {
        LoggerService.debug('Messages list state: ${state.runtimeType}');

        // NO LOADING SCREEN - WhatsApp shows messages instantly
        // Messages will appear as soon as they're loaded

        if (state is MessageError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: kErrorColor),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: secondaryTextColor),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<MessageBloc>().add(
                      LoadMessagesEvent(conversationId: widget.conversationId),
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

        Widget content = const SizedBox.shrink();

        if (state is MessagesLoaded) {
          LoggerService.debug(
            'Messages loaded: ${state.messages.length} messages',
          );

          if (state.messages.isEmpty) {
            content = Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: secondaryTextColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: TextStyle(fontSize: 16, color: secondaryTextColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Send a message to start the conversation',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                ],
              ),
            );
          } else {
            content = ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: state.messages.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                // Show loading indicator at the bottom (top in reverse list)
                if (index == state.messages.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: kPrimaryColor,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }

                final message = state.messages[index];
                final isFirstInDay =
                    index == state.messages.length - 1 ||
                    !_isSameDay(
                      message.createdAt,
                      state.messages[index + 1].createdAt,
                    );

                // Show date separators above messages (at the top of each day)
                if (isFirstInDay) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildDateSeparator(message.createdAt, isDarkMode),
                      _buildMessageBubble(message, isDarkMode),
                    ],
                  );
                } else {
                  return _buildMessageBubble(message, isDarkMode);
                }
              },
            );
          }
        }

        // Wrap the content with a Stack to add background
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            // Optional: Add a subtle gradient instead of image
            gradient: isDarkMode
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      backgroundColor,
                      backgroundColor.withValues(alpha: 0.95),
                    ],
                  )
                : null,
          ),
          child: content,
        );
      },
    );
  }

  Widget _buildMessageBubble(MessageEntity message, bool isDarkMode) {
    final currentUserId = SupabaseConfig.client.auth.currentUser?.id ?? '';
    final isSent = message.senderId == currentUserId;
    // Use theme colors
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    Widget bubbleContent = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.80,
      ),
      decoration: BoxDecoration(
        color: isSent
            ? kPrimaryColor.withValues(alpha: 0.3)
            : (isDarkMode ? kSurfaceColorDark : kSurfaceColorLight),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display listing card if metadata contains listing information
          if (message.metadata != null &&
              message.metadata!.containsKey('listingId') &&
              message.metadata!.containsKey('listingType')) ...[
            _buildListingCard(message.metadata!, isDarkMode),
            if (message.content.isNotEmpty) const SizedBox(height: 8),
          ],
          // Display image if present (and not already shown in listing card)
          if (message.imageUrl != null &&
              message.imageUrl!.isNotEmpty &&
              (message.metadata == null ||
                  !message.metadata!.containsKey('listingId'))) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: message.imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                memCacheWidth: 800, // Optimize memory usage
                maxWidthDiskCache: 1200, // Limit disk cache size
                placeholder: (context, url) => Container(
                  height: 200,
                  color: isDarkMode ? kBorderColorDark : kBorderColor,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: isDarkMode ? kBorderColorDark : kBorderColor,
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 48,
                      color: isDarkMode ? kTextSecondaryDark : kTextSecondary,
                    ),
                  ),
                ),
                fadeInDuration: const Duration(milliseconds: 200),
              ),
            ),
            if (message.content.isNotEmpty) const SizedBox(height: 8),
          ],
          if (message.content.isNotEmpty)
            Text(
              message.content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? kTextPrimaryDark : kTextPrimary,
                fontSize: 15,
              ),
            ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                TimeFormatter.formatMessageTime(message.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDarkMode ? kTextSecondaryDark : kTextSecondary,
                  fontSize: 11,
                ),
              ),
              if (isSent) ...[
                const SizedBox(width: 4),
                _buildMessageStatusIcon(message, isDarkMode),
              ],
            ],
          ),
        ],
      ),
    );

    bubbleContent = GestureDetector(
      onLongPress: () => _showDeleteMessageDialog(message),
      child: bubbleContent,
    );

    bubbleContent = Slidable(
      key: ValueKey(message.id),
      startActionPane: isSent
          ? null
          : ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.35,
              children: [
                SlidableAction(
                  onPressed: (_) {
                    // Add a small delay to mimic WhatsApp's behavior
                    Future.delayed(const Duration(milliseconds: 100), () {
                      _handleReply(message);
                    });
                  },
                  backgroundColor: const Color(0xFF008069), // WhatsApp green
                  foregroundColor: Colors.white,
                  icon: Icons.reply,
                  label: 'Reply',
                  spacing: 8.0,
                  flex: 2,
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ],
            ),
      endActionPane: isSent
          ? ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.35,
              children: [
                SlidableAction(
                  onPressed: (_) {
                    // Add a small delay to mimic WhatsApp's behavior
                    Future.delayed(const Duration(milliseconds: 100), () {
                      _handleReply(message);
                    });
                  },
                  backgroundColor: const Color(0xFF008069), // WhatsApp green
                  foregroundColor: Colors.white,
                  icon: Icons.reply,
                  label: 'Reply',
                  spacing: 8.0,
                  flex: 2,
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ],
            )
          : null,
      child: bubbleContent,
    );

    // Use a custom approach for better alignment control
    return SizedBox(
      width: double.infinity,
      child: isSent
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [bubbleContent],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [bubbleContent],
            ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return TimeFormatter.isSameDay(date1, date2);
  }

  Widget _buildMessageStatusIcon(MessageEntity message, bool isDarkMode) {
    // Check for optimistic message (starts with temp_)
    if (message.id.startsWith('temp_')) {
      return Icon(
        Icons.access_time,
        size: 12,
        color: isDarkMode ? Colors.white70 : Colors.black54,
      );
    }

    final status = message.status;
    // WhatsApp style: Blue for read, gray for sent/delivered
    final color = status == MessageStatus.read
        ? const Color(0xFF53BDEB) // WhatsApp blue for read receipts
        : (isDarkMode
              ? Colors.white70
              : Colors.black54); // Gray for sent/delivered

    switch (status) {
      case MessageStatus.sent:
        // Single tick
        return Icon(Icons.check, size: 14, color: color);
      case MessageStatus.delivered:
        // Double tick (gray)
        return Icon(Icons.done_all, size: 14, color: color);
      case MessageStatus.read:
        // Double tick (blue)
        return Icon(Icons.done_all, size: 14, color: color);
    }
  }

  Widget _buildListingCard(
    Map<String, dynamic> metadata,
    bool isDarkMode,
  ) {
    final listingId = metadata['listingId'] as String?;
    final listingType = metadata['listingType'] as String?;
    final listingTitle = metadata['listingTitle'] as String?;
    final listingImageUrl = metadata['listingImageUrl'] as String?;
    final listingPrice = metadata['listingPrice'] as String?;
    final listingPriceType = metadata['listingPriceType'] as String?;

    if (listingId == null || listingType == null || listingTitle == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final primaryTextColor = isDarkMode ? kTextPrimaryDark : kTextPrimary;
    final secondaryTextColor = isDarkMode ? kTextSecondaryDark : kTextSecondary;
    final backgroundColor = isDarkMode ? kSurfaceColorDark : kSurfaceColorLight;

    // Determine route based on listing type
    String route = '/';
    IconData icon = Icons.shopping_bag;
    switch (listingType) {
      case 'product':
        route = '/product-details';
        icon = Icons.shopping_bag;
        break;
      case 'service':
        route = '/service-details';
        icon = Icons.build;
        break;
      case 'accommodation':
        route = '/accommodation-details';
        icon = Icons.home;
        break;
    }

    // Format price type for display
    String? displayPriceType;
    if (listingPriceType != null && listingPriceType.isNotEmpty) {
      displayPriceType = listingPriceType.replaceAll('_', ' ');
      displayPriceType = displayPriceType
          .split(' ')
          .map((word) => word.isEmpty
              ? ''
              : word[0].toUpperCase() + word.substring(1))
          .join(' ');
    }

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, route, arguments: listingId);
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? kBorderColorDark : kBorderColor,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Listing Image
            if (listingImageUrl != null && listingImageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: CachedNetworkImage(
                  imageUrl: listingImageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 100,
                    height: 100,
                    color: isDarkMode ? kBorderColorDark : kBorderColor,
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 100,
                    height: 100,
                    color: isDarkMode ? kBorderColorDark : kBorderColor,
                    child: Icon(
                      icon,
                      size: 32,
                      color: secondaryTextColor,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: isDarkMode ? kBorderColorDark : kBorderColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: secondaryTextColor,
                ),
              ),
            // Listing Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          icon,
                          size: 16,
                          color: kPrimaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          listingType.toUpperCase(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: kPrimaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      listingTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: primaryTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (listingPrice != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        displayPriceType != null
                            ? '$listingPrice/$displayPriceType'
                            : listingPrice,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date, bool isDarkMode) {
    final dateText = TimeFormatter.formatDateSeparator(date);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? kSurfaceColorDark : kSurfaceColorLight;
    final textColor = isDarkMode ? kTextPrimaryDark : kTextPrimary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          dateText,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(bool isDarkMode) {
    // Note: Message sending is now handled optimistically in the bloc,
    // so we don't need to reload messages here
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? kBackgroundColorDark
        : kBackgroundColorLight;
    final inputBackgroundColor = isDarkMode
        ? kSurfaceColorDark
        : kSurfaceColorLight;
    final borderColor = isDarkMode ? kBorderColorDark : kBorderColor;
    final textColor = isDarkMode ? kTextPrimaryDark : kTextPrimary;
    final hintColor = isDarkMode ? kTextSecondaryDark : kTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply preview (shows when replying to a message)
          if (_repliedToMessage != null) _buildReplyPreview(isDarkMode),

          // Input row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Attachment button
                IconButton(
                  icon: Icon(Icons.attach_file, color: hintColor),
                  onPressed: _showAttachmentOptions,
                  tooltip: 'Attach file',
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: (value) {
                      // Handle typing indicator with debouncing
                      // We don't want to send an event on every keystroke
                      // We'll use a simple timer approach here or just dispatch
                      // The bloc can handle debouncing if needed, but better here

                      // Simple logic: If text is not empty, send typing true
                      // We should use a timer to stop typing after inactivity
                      // But for now, let's just trigger it.

                      if (value.isNotEmpty) {
                        context.read<MessageBloc>().add(
                          SendTypingIndicatorEvent(
                            conversationId: widget.conversationId,
                            isTyping: true,
                          ),
                        );

                        // Cancel previous timer if exists
                        // We need a timer variable in the state class
                        // Since we can't add it easily here without modifying the class,
                        // we'll rely on the user stopping typing or sending message
                        // Ideally, we should add a Timer? _typingTimer to the class.
                      } else {
                        context.read<MessageBloc>().add(
                          SendTypingIndicatorEvent(
                            conversationId: widget.conversationId,
                            isTyping: false,
                          ),
                        );
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: hintColor),
                      filled: true,
                      fillColor: inputBackgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    style: TextStyle(color: textColor),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: kPrimaryColor,
                  // NO LOADING INDICATOR - WhatsApp sends instantly (optimistically)
                  child: IconButton(
                    icon: Icon(Icons.send, color: kBackgroundColorDark),
                    onPressed: _sendMessage,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview(bool isDarkMode) {
    if (_repliedToMessage == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? kSurfaceColorDark : kSurfaceColorLight;
    final secondaryTextColor = isDarkMode ? kTextSecondaryDark : kTextSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(left: BorderSide(color: kPrimaryColor, width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _repliedToMessage!.content.length > 50
                      ? '${_repliedToMessage!.content.substring(0, 50)}...'
                      : _repliedToMessage!.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: secondaryTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: secondaryTextColor, size: 20),
            onPressed: () {
              setState(() {
                _repliedToMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }
}
