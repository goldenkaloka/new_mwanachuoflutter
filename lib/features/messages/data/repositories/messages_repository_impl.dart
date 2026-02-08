import 'package:mwanachuo/config/supabase_config.dart';
import 'package:mwanachuo/features/auth/data/models/user_model.dart';
import 'package:mwanachuo/features/messages/data/models/conversation_model.dart';
import 'package:mwanachuo/features/messages/data/models/message_model.dart';
import 'package:mwanachuo/features/messages/domain/entities/conversation.dart';
import 'package:mwanachuo/features/messages/domain/entities/message.dart';
import 'package:mwanachuo/features/messages/domain/repositories/messages_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessagesRepositoryImpl implements MessagesRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  @override
  Future<Conversation> createConversation(List<String> participantIds) async {
    final userId = _client.auth.currentUser!.id;
    // Sort participants to ensure consistent querying if needed,
    // but here we rely on "contains" logic.
    final allParticipants = {...participantIds, userId}.toList();

    // Check if conversation already exists
    // This is tricky with simple queries.
    // For now, we'll try to find one or create.
    // A better approach is an RPC, but let's try standard query.
    // Actually, finding an exact match of participants is hard without an RPC.
    // We will just create a new one if not found, or maybe just create.
    // For 1-on-1, typically we check if there is a conv with these 2 users.

    if (allParticipants.length == 2) {
      final otherUserId = allParticipants.firstWhere((id) => id != userId);
      final response = await _client.from('conversations').select().contains(
        'participants',
        [userId, otherUserId],
      ).maybeSingle();

      if (response != null) {
        return ConversationModel.fromJson(response);
      }
    }

    final response = await _client
        .from('conversations')
        .insert({'participants': allParticipants})
        .select()
        .single();

    return ConversationModel.fromJson(response);
  }

  @override
  Future<List<Conversation>> getConversations() async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('conversations')
        .select()
        .contains('participants', [userId])
        .order('updated_at', ascending: false);

    final conversations = (response as List)
        .map((e) => ConversationModel.fromJson(e))
        .toList();

    if (conversations.isEmpty) return [];

    // Extract all unique participant IDs
    final allParticipantIds = conversations
        .expand((c) => c.participants)
        .toSet()
        .toList();

    if (allParticipantIds.isEmpty) return conversations;

    // Fetch profiles for these users
    final profilesResponse = await _client
        .from('profiles')
        .select()
        .inFilter('id', allParticipantIds);

    final profiles = (profilesResponse as List)
        .map((e) => UserModel.fromJson(e))
        .toList();

    // Map profiles to conversations
    return conversations.map((conversation) {
      final conversationParticipants = profiles
          .where((user) => conversation.participants.contains(user.id))
          .toList();

      return conversation.copyWith(participantsData: conversationParticipants);
    }).toList();
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    final response = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (response as List).map((e) => MessageModel.fromJson(e)).toList();
  }

  @override
  Stream<List<Message>> getMessagesStream(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((event) => event.map((e) => MessageModel.fromJson(e)).toList());
  }

  @override
  Future<void> markAsRead(String messageId) async {
    await _client
        .from('messages')
        .update({'is_read': true})
        .eq('id', messageId);
  }

  @override
  Future<Message> sendMessage({
    required String conversationId,
    required String content,
    String type = 'text',
    Map<String, dynamic> metadata = const {},
  }) async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': userId,
          'content': content,
          'type': type,
          'metadata': metadata,
        })
        .select()
        .single();

    return MessageModel.fromJson(response);
  }

  @override
  Future<void> updateMessage(
    String messageId,
    Map<String, dynamic> metadata,
  ) async {
    await _client
        .from('messages')
        .update({'metadata': metadata})
        .eq('id', messageId);
  }
}
