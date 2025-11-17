import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mwanachuo/config/supabase_config.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/constants/database_constants.dart';
import 'package:mwanachuo/core/services/logger_service.dart';
import 'package:mwanachuo/core/utils/time_formatter.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/message_bloc.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/message_event.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/message_state.dart';
import 'package:mwanachuo/features/messages/domain/entities/message_entity.dart';

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
  final ImagePicker _imagePicker = ImagePicker();
  String? _recipientName;
  String? _recipientAvatar;
  String? _recipientId;
  bool _recipientIsOnline = false;
  DateTime? _recipientLastSeen;
  StreamSubscription? _onlineStatusSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
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
    _updateUserOnlineStatus(false);
    _onlineStatusSubscription?.cancel();
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

          LoggerService.debug('Recipient loaded: $_recipientName, online: $_recipientIsOnline');
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

    context.read<MessageBloc>().add(
      SendMessageEvent(conversationId: widget.conversationId, content: content),
    );

    _messageController.clear();
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
      context.read<MessageBloc>().add(
        UploadImageEvent(filePath: image.path),
      );

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
      context.read<MessageBloc>().add(
        UploadImageEvent(filePath: photo.path),
      );

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
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
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
                  child: const Icon(Icons.camera_alt, color: kBackgroundColorDark),
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
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80, // WhatsApp uses 80%
        ),
        decoration: BoxDecoration(
          // WhatsApp colors: sent = light green, received = white/dark grey
          color: isSent
              ? (isDarkMode 
                  ? const Color(0xFF005C4B) // Dark mode sent (dark teal)
                  : const Color(0xFFDCF8C6)) // Light mode sent (light green)
              : (isDarkMode 
                  ? const Color(0xFF262D31) // Dark mode received (dark grey)
                  : Colors.white), // Light mode received (white)
          borderRadius: BorderRadius.circular(8), // WhatsApp uses 8dp
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display image if available
            if (message.imageUrl != null && message.imageUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  message.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: kPrimaryColor,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 48),
                      ),
                    );
                  },
                ),
              ),
              if (message.content.isNotEmpty) const SizedBox(height: 8),
            ],
            // Display text content (can be empty if it's an image-only message)
            if (message.content.isNotEmpty)
              Text(
                message.content,
                style: GoogleFonts.plusJakartaSans(
                  // WhatsApp text colors
                  color: isSent
                      ? (isDarkMode 
                          ? Colors.white // White text on dark teal
                          : const Color(0xFF000000)) // Black text on light green
                      : (isDarkMode 
                          ? Colors.white // White text on dark grey
                          : const Color(0xFF000000)), // Black text on white
                  fontSize: 15, // WhatsApp uses slightly larger text
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  TimeFormatter.formatMessageTime(message.createdAt),
                  style: GoogleFonts.plusJakartaSans(
                    // WhatsApp time colors
                    color: isSent
                        ? (isDarkMode
                            ? Colors.white.withValues(alpha: 0.7) // Light grey on dark teal
                            : const Color(0xFF667781)) // Grey on light green
                        : (isDarkMode
                            ? Colors.white.withValues(alpha: 0.6) // Light grey on dark grey
                            : const Color(0xFF667781)), // Grey on white
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
    return TimeFormatter.isSameDay(date1, date2);
  }

  Widget _buildMessageStatusIcon(MessageEntity message, bool isDarkMode) {
    final status = message.status;
    // WhatsApp style: Blue for read, gray for sent/delivered
    final color = status == MessageStatus.read
        ? const Color(0xFF53BDEB) // WhatsApp blue for read receipts
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
    final dateText = TimeFormatter.formatDateSeparator(date);

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
          // Attachment button
          IconButton(
            icon: Icon(
              Icons.attach_file,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            onPressed: _showAttachmentOptions,
            tooltip: 'Attach file',
          ),
          const SizedBox(width: 4),
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
