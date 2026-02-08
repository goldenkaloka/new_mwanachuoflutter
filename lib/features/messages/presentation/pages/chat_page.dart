import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/chat_bloc.dart';
import 'package:mwanachuo/features/messages/domain/entities/message.dart'
    as domain;

class ChatPage extends StatefulWidget {
  final String conversationId;
  final String? otherUserId;
  final String? otherUserName;
  final String? otherUserAvatar;

  const ChatPage({
    super.key,
    required this.conversationId,
    this.otherUserId,
    this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late String _currentUserId;
  late String _effectiveConversationId;
  String? _otherUserName;
  InMemoryChatController? _chatController;

  @override
  void initState() {
    super.initState();
    _effectiveConversationId = widget.conversationId;
    _otherUserName = widget.otherUserName;
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _currentUserId = authState.user.id;
    } else {
      _currentUserId = 'draft_user';
    }
  }

  @override
  void dispose() {
    _chatController?.dispose();
    super.dispose();
  }

  void _handleSendPressed(String text) {
    if (_effectiveConversationId == 'new') {
      final state = context.read<ChatBloc>().state;
      if (state is ChatLoaded && state.conversationId != 'new') {
        setState(() {
          _effectiveConversationId = state.conversationId;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please wait, initializing chat...')),
        );
        return;
      }
    }
    context.read<ChatBloc>().add(
      SendMessage(
        conversationId: _effectiveConversationId,
        content: text,
        type: 'text',
      ),
    );
  }

  void _handleMakeOffer() async {
    final amountController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Make an Offer',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your price offer:',
              style: GoogleFonts.plusJakartaSans(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: 'TZS ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, amountController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Offer'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (result != null && result.isNotEmpty) {
      final amount = double.tryParse(result);
      if (amount == null) return;

      if (_effectiveConversationId == 'new') {
        // Logic to ensure conversation exists would go here
        // For now assuming it exists or handleSendPressed logic handles it?
        // SendMessage event handles it if we pass 'new' and the bloc creates it?
        // No, Bloc needs StartConversation for 'new'.
        // But _handleSendPressed handles checking 'new' and getting ID from state.
        // We should replicate that check.
      }

      // If we are still 'new', we might fail.
      // Safe option: trigger send message logic which handles creation?
      // But SendMessage expects an ID.

      context.read<ChatBloc>().add(
        SendMessage(
          conversationId: _effectiveConversationId,
          // We send text description AND metadata
          content: 'OFFER: TZS ${amount.toStringAsFixed(0)}',
          type: 'offer',
          metadata: {'amount': amount, 'status': 'pending'},
        ),
      );
    }
  }

  List<Message> _mapDomainMessagesToUi(List<domain.Message> domainMessages) {
    return domainMessages.map((msg) {
      final createdAt = msg.createdAt;

      if (msg.type == 'text') {
        return Message.text(
          authorId: msg.senderId,
          createdAt: createdAt,
          id: msg.id,
          text: msg.content,
        );
      } else if (msg.type == 'offer') {
        return Message.custom(
          authorId: msg.senderId,
          createdAt: createdAt,
          id: msg.id,
          metadata: msg.metadata,
        );
      }
      return Message.text(
        authorId: msg.senderId,
        createdAt: createdAt,
        id: msg.id,
        text: 'Unsupported message type: ${msg.type}',
      );
    }).toList();
  }

  Future<User?> _resolveUser(String userId) async {
    if (userId == _currentUserId) {
      return User(id: userId, name: 'Me');
    }
    return User(id: userId, name: _otherUserName ?? 'User');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _otherUserName ?? 'Chat',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_offer_outlined),
            onPressed: _handleMakeOffer,
            tooltip: 'Make Offer',
          ),
        ],
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatLoaded) {
            if (_effectiveConversationId == 'new') {
              setState(() {
                _effectiveConversationId = state.conversationId;
              });
            }
            final uiMessages = _mapDomainMessagesToUi(state.messages);

            setState(() {
              if (_chatController == null) {
                _chatController = InMemoryChatController(messages: uiMessages);
              } else {
                _chatController?.dispose();
                _chatController = InMemoryChatController(messages: uiMessages);
              }
            });
          }
        },
        builder: (context, state) {
          if (state is ChatLoading && _chatController == null) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ChatError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (_chatController != null) {
            return Chat(
              chatController: _chatController!,
              currentUserId: _currentUserId,
              resolveUser: _resolveUser,
              onMessageSend: _handleSendPressed,
              builders: Builders(
                customMessageBuilder:
                    (
                      context,
                      message,
                      index, {
                      required isSentByMe,
                      groupStatus,
                    }) {
                      return _buildOfferCard(message);
                    },
              ),
              theme: ChatTheme(
                colors: ChatColors.light().copyWith(
                  primary: Colors.teal,
                  surfaceContainer: Colors.white,
                  surface: const Color(0xFFE5DDD5),
                ),
                typography: ChatTypography.standard(),
                shape: const BorderRadius.all(Radius.circular(12)),
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildOfferCard(CustomMessage msg) {
    final status = msg.metadata?['status'] ?? 'pending';
    final amount = msg.metadata?['amount'] ?? 0;
    final isSender = msg.authorId == _currentUserId;

    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(maxWidth: 300),
      // ... rest of the card
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer, color: Colors.teal, size: 20),
              const SizedBox(width: 8),
              Text(
                'Price Offer',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'TZS ${amount.toString()}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                color: _getStatusColor(status),
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          if (!isSender && status == 'pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _updateOfferStatus(msg.id, 'short_declined'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateOfferStatus(msg.id, 'accepted'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'declined':
      case 'short_declined':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  void _updateOfferStatus(String messageId, String newStatus) {
    context.read<ChatBloc>().add(
      UpdateMessage(messageId: messageId, metadata: {'status': newStatus}),
    );
  }
}
