import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mwanachuo/features/auth/data/models/user_model.dart';
import 'package:mwanachuo/features/messages/data/models/conversation_model.dart';
import 'package:mwanachuo/features/messages/data/models/message_model.dart';
import 'package:mwanachuo/features/messages/domain/entities/conversation.dart';
import 'package:mwanachuo/features/messages/domain/entities/message.dart';
import 'package:mwanachuo/features/messages/domain/repositories/messages_repository.dart';

class MessagesRepositoryImpl implements MessagesRepository {
  final SupabaseClient _supabase;

  MessagesRepositoryImpl(this._supabase);

  String get _currentUserId => _supabase.auth.currentUser!.id;

  @override
  Future<Conversation> initiateConversation(String otherUserId) async {
    final response = await _supabase.rpc(
      'get_or_create_conversation',
      params: {'other_user_id': otherUserId},
    );
    return await _fetchConversation(response as String);
  }

  Future<Conversation> _fetchConversation(String convId) async {
    final convData = await _supabase
        .from('conversations')
        .select(
          '*, participants:participants(user:users(*), last_read_at), last_message:messages!last_message_id(*)',
        )
        .eq('id', convId)
        .single();

    final participants = convData['participants'] as List;
    final currentUserParticipant = participants.firstWhere(
      (p) => p['user']['id'] == _currentUserId,
      orElse: () => null,
    );

    int unreadCount = 0;
    if (currentUserParticipant != null) {
      final unreadData = await _supabase
          .from('messages')
          .select('id')
          .eq('conversation_id', convId)
          .neq('sender_id', _currentUserId)
          .eq('is_read', false);
      unreadCount = (unreadData as List).length;
    }

    return ConversationModel.fromMap(
      {...convData, 'unread_count': unreadCount},
      participants: participants
          .map((p) => p['user'] as Map<String, dynamic>)
          .toList(),
    );
  }

  @override
  Future<List<Conversation>> getConversations() async {
    // 1. Get IDs of conversations where user is a participant
    final participantData = await _supabase
        .from('participants')
        .select('conversation_id')
        .eq('user_id', _currentUserId);

    final convIds = (participantData as List)
        .map((p) => p['conversation_id'] as String)
        .toList();

    if (convIds.isEmpty) return [];

    // 2. Fetch full conversation data for those IDs
    final data = await _supabase
        .from('conversations')
        .select(
          '*, participants:participants(user:users(*), last_read_at), last_message:messages!last_message_id(*)',
        )
        .inFilter('id', convIds)
        .order('last_message_at', ascending: false);

    // 3. Parallelize unread count fetching
    final results = await Future.wait(
      (data as List).map((conv) async {
        final participants = conv['participants'] as List;

        // Calculate unread count using the is_read column
        final unreadData = await _supabase
            .from('messages')
            .select('id')
            .eq('conversation_id', conv['id'])
            .neq('sender_id', _currentUserId)
            .eq('is_read', false);

        final unreadCount = (unreadData as List).length;

        return ConversationModel.fromMap(
          {...conv, 'unread_count': unreadCount},
          participants: participants
              .map((p) => p['user'] as Map<String, dynamic>)
              .toList(),
        );
      }),
    );

    return results;
  }

  @override
  Stream<List<Conversation>> getConversationsStream() {
    // Listen to conversations table for updates.
    // RLS "Users can see conversations they are part of" ensures we only get our own.
    // This triggers when any of our conversations are updated (e.g. new message).
    return _supabase.from('conversations').stream(primaryKey: ['id']).asyncMap((
      event,
    ) async {
      return await getConversations();
    });
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    final data = await _supabase
        .from('messages')
        .select('*')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (data as List).map((m) => MessageModel.fromMap(m)).toList();
  }

  @override
  Stream<List<Message>> getMessagesStream(String conversationId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((event) => event.map((m) => MessageModel.fromMap(m)).toList());
  }

  @override
  Future<Message> sendMessage({
    required String conversationId,
    required String content,
    MessageType type = MessageType.text,
    Map<String, dynamic> metadata = const {},
  }) async {
    final messageData = await _supabase
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': _currentUserId,
          'content': content,
          'type': type,
          'metadata': metadata,
        })
        .select()
        .single();

    return MessageModel.fromMap(messageData);
  }

  @override
  Future<void> markAsRead(String conversationId) async {
    final now = DateTime.now().toIso8601String();

    // 1. Update participant's last_read_at
    await _supabase.from('participants').update({'last_read_at': now}).match({
      'conversation_id': conversationId,
      'user_id': _currentUserId,
    });

    // 2. Update all incoming messages as read
    await _supabase
        .from('messages')
        .update({'is_read': true})
        .match({'conversation_id': conversationId})
        .neq('sender_id', _currentUserId)
        .eq('is_read', false);

    // 3. Touch conversation to trigger realtime streams
    await _supabase
        .from('conversations')
        .update({'updated_at': now})
        .eq('id', conversationId);
  }

  @override
  Future<void> updateUserPresence(bool isOnline) async {
    final now = DateTime.now().toIso8601String();
    await _supabase
        .from('users')
        .update({'is_online': isOnline, 'last_seen_at': now})
        .eq('id', _currentUserId);
  }

  @override
  Stream<UserModel> getUserStream(String userId) {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) {
          if (data.isEmpty) {
            throw Exception('User not found');
          }
          return UserModel.fromJson(data.first);
        });
  }
}
