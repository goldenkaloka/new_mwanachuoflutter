import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/core/widgets/app_background.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/conversations_bloc.dart';
import 'package:mwanachuo/core/enums/user_role.dart';
import 'package:mwanachuo/features/auth/data/models/user_model.dart';
import 'package:mwanachuo/features/messages/domain/entities/conversation.dart';
import 'package:timeago/timeago.dart' as timeago;

class ConversationsPage extends StatelessWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ConversationsBloc>()..add(LoadConversations()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Messages',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
        ),
        body: AppBackground(
          child: BlocBuilder<ConversationsBloc, ConversationsState>(
            builder: (context, state) {
              if (state is ConversationsLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ConversationsError) {
                return Center(child: Text('Error: ${state.message}'));
              } else if (state is ConversationsLoaded) {
                if (state.conversations.isEmpty) {
                  return Center(
                    child: Text(
                      'No conversations yet',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: state.conversations.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return _ConversationTile(
                      conversation: state.conversations[index],
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
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
    final currentUserId = context.read<AuthBloc>().state is Authenticated
        ? (context.read<AuthBloc>().state as Authenticated).user.id
        : '';

    // Find other participant
    final otherParticipantId = conversation.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    final otherUser = conversation.participantsData?.firstWhere(
      (user) => user.id == otherParticipantId,
      orElse: () => UserModel(
        id: otherParticipantId,
        email: '',
        name: 'User ${otherParticipantId.substring(0, 4)}...',
        role: UserRole.buyer,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final displayName = otherUser?.name ?? 'User';
    final avatarUrl = otherUser?.profilePicture;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[200],
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
        child: avatarUrl == null
            ? const Icon(Icons.person, color: Colors.grey)
            : null,
      ),
      title: Text(
        displayName,
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        conversation.lastMessage ?? 'No messages',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.plusJakartaSans(),
      ),
      trailing: Text(
        timeago.format(conversation.updatedAt),
        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey),
      ),
      onTap: () {
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: {
            'conversationId': conversation.id,
            'otherUserId': otherParticipantId,
            'otherUserName': displayName,
            'otherUserAvatar': avatarUrl,
          },
        );
      },
    );
  }
}
