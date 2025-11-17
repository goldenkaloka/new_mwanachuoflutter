import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/config/supabase_config.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/services/logger_service.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/message_bloc.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/message_event.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/message_state.dart';
import 'package:mwanachuo/features/messages/domain/entities/message_entity.dart';
import 'package:intl/intl.dart';

// --- CHAT SCREEN WIDGET ---

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

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

    // Use the shared MessageBloc instance from app level
    // Load messages when screen is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<MessageBloc>();
      bloc.add(LoadMessagesEvent(conversationId: conversationId));
      bloc.add(StartListeningToMessagesEvent(conversationId: conversationId));
    });

    return _ChatScreenView(conversationId: conversationId);
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
  String? _recipientName;
  String? _recipientAvatar;
  bool _recipientIsOnline = false;
  DateTime? _recipientLastSeen;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadConversationDetails();
    _updateUserOnlineStatus(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateUserOnlineStatus(false);
    _messageController.dispose();
    super.dispose();
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

      if (mounted) {
        setState(() {
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

          LoggerService.debug('Recipient loaded: $_recipientName, online: $_recipientIsOnline');
        });
      }
    } catch (e) {
      LoggerService.error('Failed to load conversation details', e);
    }
  }

  String _getOnlineStatus() {
    if (_recipientIsOnline) {
      return 'Online';
    } else if (_recipientLastSeen != null) {
      // Convert to local time to avoid timezone issues
      final localLastSeen = _recipientLastSeen!.toLocal();
      final now = DateTime.now();
      final difference = now.difference(localLastSeen);

      // Handle negative differences (future times due to sync issues)
      if (difference.isNegative || difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return 'Last seen ${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return 'Last seen ${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return 'Last seen ${difference.inDays}d ago';
      } else {
        return 'Last seen ${DateFormat('MMM d').format(localLastSeen)}';
      }
    }
    return 'Offline';
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    context.read<MessageBloc>().add(
      SendMessageEvent(conversationId: widget.conversationId, content: content),
    );

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<MessageBloc, MessageState>(
      listener: (context, state) {
        // Note: MessageSent is now handled optimistically in the bloc,
        // so we don't need to reload. Only reload if we get NewMessageReceived
        // and it's not already in our current messages list.
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
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black87;

    return AppBar(
      backgroundColor: isDarkMode ? kBackgroundColorDark : Colors.white,
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
                    ? const Icon(Icons.person, color: Colors.white, size: 20)
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
                      color: Colors.green,
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _recipientName ?? 'Loading...',
                  style: GoogleFonts.plusJakartaSans(
                    color: primaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _getOnlineStatus(),
                  style: GoogleFonts.plusJakartaSans(
                    color: _recipientIsOnline ? Colors.green : Colors.grey,
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
    return BlocBuilder<MessageBloc, MessageState>(
      buildWhen: (previous, current) {
        // Rebuild when messages are loaded or updated
        return current is MessagesLoaded ||
            current is MessagesLoading ||
            current is MessageError;
      },
      builder: (context, state) {
        LoggerService.debug('Messages list state: ${state.runtimeType}');

        if (state is MessagesLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: kPrimaryColor),
                const SizedBox(height: 16),
                Text(
                  'Loading messages...',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        if (state is MessageError) {
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

        if (state is MessagesLoaded) {
          LoggerService.debug('Messages loaded: ${state.messages.length} messages');

          if (state.messages.isEmpty) {
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
                    'No messages yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Send a message to start the conversation',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            reverse: true,
            padding: const EdgeInsets.all(16),
            itemCount: state.messages.length,
            itemBuilder: (context, index) {
              final message = state.messages[index];
              final isFirstInDay =
                  index == state.messages.length - 1 ||
                  !_isSameDay(
                    message.createdAt,
                    state.messages[index + 1].createdAt,
                  );

              return Column(
                children: [
                  _buildMessageBubble(message, isDarkMode),
                  if (isFirstInDay)
                    _buildDateSeparator(message.createdAt, isDarkMode),
                ],
              );
            },
          );
        }

        if (state is MessageSent || state is MessageSending) {
          // Keep showing previous messages while sending
          LoggerService.debug('Message sending/sent state - keeping previous UI');
          return const SizedBox.shrink();
        }

        LoggerService.warning('Unknown message state: ${state.runtimeType}');
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMessageBubble(MessageEntity message, bool isDarkMode) {
    // Get current user ID from Supabase Auth
    final currentUserId = SupabaseConfig.client.auth.currentUser?.id ?? '';
    final isSent = message.senderId == currentUserId;

    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isSent
              ? kPrimaryColor
              : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: GoogleFonts.plusJakartaSans(
                color: isSent
                    ? kBackgroundColorDark
                    : (isDarkMode ? Colors.white : Colors.black87),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.createdAt.toLocal()),
                  style: GoogleFonts.plusJakartaSans(
                    color: isSent
                        ? kBackgroundColorDark.withValues(alpha: 0.7)
                        : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
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
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildMessageStatusIcon(MessageEntity message, bool isDarkMode) {
    final status = message.status;
    final color = status == MessageStatus.read
        ? kPrimaryColor // Blue for read
        : kBackgroundColorDark.withValues(
            alpha: 0.7,
          ); // Gray for sent/delivered

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

  Widget _buildDateSeparator(DateTime date, bool isDarkMode) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String dateText;
    if (messageDate == today) {
      dateText = 'Today';
    } else if (messageDate == yesterday) {
      dateText = 'Yesterday';
    } else if (now.difference(messageDate).inDays < 7) {
      dateText = DateFormat('EEEE').format(date); // Day name
    } else {
      dateText = DateFormat('MMM d, yyyy').format(date);
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.grey[800]!.withValues(alpha: 0.6)
              : Colors.grey[300]!.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          dateText,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(bool isDarkMode) {
    // Note: Message sending is now handled optimistically in the bloc,
    // so we don't need to reload messages here
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? kBackgroundColorDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              style: GoogleFonts.plusJakartaSans(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          BlocBuilder<MessageBloc, MessageState>(
            builder: (context, state) {
              final isSending = state is MessageSending;

              return CircleAvatar(
                backgroundColor: kPrimaryColor,
                child: isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: kBackgroundColorDark,
                        ),
                        onPressed: isSending ? null : _sendMessage,
                        padding: EdgeInsets.zero,
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
}
