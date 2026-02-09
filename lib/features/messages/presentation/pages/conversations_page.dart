import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/conversations_bloc.dart';
import 'package:mwanachuo/features/messages/presentation/pages/chat_page.dart';
import 'package:mwanachuo/features/messages/domain/entities/conversation.dart';
import 'package:timeago/timeago.dart' as timeago;

class ConversationsPage extends StatelessWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ConversationsBloc>()..add(LoadConversations()),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF075E54),
          foregroundColor: Colors.white,
          title: Text(
            'Mwanachuo Chat',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
          ),
          elevation: 1,
        ),
        body: BlocBuilder<ConversationsBloc, ConversationsState>(
          builder: (context, state) {
            if (state is ConversationsLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ConversationsError) {
              return Center(child: Text('Error: ${state.message}'));
            } else if (state is ConversationsLoaded) {
              if (state.conversations.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No conversations yet',
                        style: GoogleFonts.plusJakartaSans(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: state.conversations.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  indent: 90,
                  endIndent: 16,
                  color: Color(0xFFEEEEEE),
                ),
                itemBuilder: (context, index) {
                  final conv = state.conversations[index];
                  return _ConversationTile(conversation: conv);
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF25D366),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Search soon to be implemented!')),
            );
          },
          child: const Icon(Icons.message, color: Colors.white),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;

  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return const SizedBox.shrink();

    final currentUserId = authState.user.id;
    final otherUser = conversation.participantsData.firstWhere(
      (u) => u.id != currentUserId,
      orElse: () => conversation.participantsData.first,
    );

    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              conversationId: conversation.id,
              otherUserId: otherUser.id,
              otherUserName: otherUser.name,
              otherUserAvatar: otherUser.profilePicture,
            ),
          ),
        );
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: Colors.grey[200],
        backgroundImage: otherUser.profilePicture != null
            ? NetworkImage(otherUser.profilePicture!)
            : null,
        child: otherUser.profilePicture == null
            ? const Icon(Icons.person, color: Colors.grey, size: 32)
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              otherUser.name,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conversation.lastMessageAt != null)
            Text(
              timeago.format(conversation.lastMessageAt!, locale: 'en_short'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                conversation.lastMessage?.content ?? 'Start chatting...',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Unread Badge
            if (conversation.unreadCount > 0)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF25D366),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${conversation.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
