import 'package:flutter/foundation.dart';
import 'package:mwanachuo/core/constants/database_constants.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/features/messages/data/models/conversation_model.dart';
import 'package:mwanachuo/features/messages/data/models/message_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class MessageRemoteDataSource {
  Future<List<ConversationModel>> getConversations({int? limit, int? offset});
  Future<ConversationModel> getOrCreateConversation({
    required String otherUserId,
  });
  Future<List<MessageModel>> getMessages({
    required String conversationId,
    int? limit,
    int? offset,
  });
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
    String? imageUrl,
  });
  Future<void> markMessagesAsRead({required String conversationId});
  Future<void> deleteMessage(String messageId);
  Stream<MessageModel> subscribeToMessages(String conversationId);
  Stream<ConversationModel> subscribeToConversations();
}

class MessageRemoteDataSourceImpl implements MessageRemoteDataSource {
  final SupabaseClient supabaseClient;

  MessageRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<ConversationModel>> getConversations({
    int? limit,
    int? offset,
  }) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) throw ServerException('User not authenticated');

      // Join with users table to get online status and last seen
      final response = await supabaseClient
          .from(DatabaseConstants.conversationsTable)
          .select('''
            *,
            user1:users!conversations_user1_id_fkey(is_online, last_seen_at),
            user2:users!conversations_user2_id_fkey(is_online, last_seen_at)
          ''')
          .or('user1_id.eq.${currentUser.id},user2_id.eq.${currentUser.id}')
          .order('last_message_time', ascending: false)
          .limit(limit ?? 50);

      // Handle empty response gracefully
      final List<dynamic> data = response as List<dynamic>;
      if (data.isEmpty) {
        debugPrint('📭 No conversations found');
        return [];
      }

      debugPrint(
        '📬 [GET CONVERSATIONS] Fetched ${data.length} conversations from DB',
      );

      return data.map((json) {
        // Determine which user is "other"
        final isUser1 = json['user1_id'] == currentUser.id;

        // Get other user's online status
        final otherUserData = isUser1 ? json['user2'] : json['user1'];
        final otherIsOnline = otherUserData?['is_online'] as bool? ?? false;
        final otherLastSeen = otherUserData?['last_seen_at'] != null
            ? DateTime.parse(otherUserData!['last_seen_at'] as String)
            : null;

        final conversationId = json['id'] as String;
        final lastMessage = json['last_message'] as String?;
        final lastMessageTime = json['last_message_time'] as String?;
        final otherUserName = isUser1 ? json['user2_name'] : json['user1_name'];

        debugPrint('📥 [GET CONVERSATIONS] Conversation ID: $conversationId');
        debugPrint('   Other user: $otherUserName');
        debugPrint('   last_message from DB: "${lastMessage ?? 'NULL'}"');
        debugPrint(
          '   last_message_time from DB: ${lastMessageTime ?? 'NULL'}',
        );
        debugPrint('   is_online: $otherIsOnline');
        debugPrint('   last_seen: $otherLastSeen');

        return ConversationModel.fromJson({
          ...json,
          'user_id': currentUser.id,
          'other_user_id': isUser1 ? json['user2_id'] : json['user1_id'],
          'other_user_name': isUser1
              ? (json['user2_name'] ?? 'Unknown User')
              : (json['user1_name'] ?? 'Unknown User'),
          'other_user_avatar': isUser1
              ? json['user2_avatar']
              : json['user1_avatar'],
          'last_message': json['last_message'],
          'last_message_time': json['last_message_time'],
          'is_online': otherIsOnline,
          'last_seen_at': otherLastSeen?.toIso8601String(),
        });
      }).toList();
    } on PostgrestException catch (e) {
      // Return empty list instead of throwing exception if table is empty or no rows match
      if (e.code == 'PGRST116' || e.message.contains('no rows')) {
        return [];
      }
      throw ServerException('Database error: ${e.message}');
    } on ServerException {
      rethrow;
    } catch (e, stackTrace) {
      // Log the full error for debugging
      debugPrint('Error in getConversations: $e');
      debugPrint('Stack trace: $stackTrace');
      throw ServerException('Failed to load conversations. Please try again.');
    }
  }

  @override
  Future<ConversationModel> getOrCreateConversation({
    required String otherUserId,
  }) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) throw ServerException('User not authenticated');

      // Try to find existing conversation
      final existing = await supabaseClient
          .from(DatabaseConstants.conversationsTable)
          .select()
          .or(
            'and(user1_id.eq.${currentUser.id},user2_id.eq.$otherUserId),and(user1_id.eq.$otherUserId,user2_id.eq.${currentUser.id})',
          )
          .maybeSingle();

      if (existing != null) {
        final isUser1 = existing['user1_id'] == currentUser.id;
        return ConversationModel.fromJson({
          ...existing,
          'user_id': currentUser.id,
          'other_user_id': otherUserId,
          'other_user_name': isUser1
              ? existing['user2_name']
              : existing['user1_name'],
          'other_user_avatar': isUser1
              ? existing['user2_avatar']
              : existing['user1_avatar'],
        });
      }

      // Get other user details
      final otherUser = await supabaseClient
          .from('users')
          .select('full_name, avatar_url')
          .eq('id', otherUserId)
          .single();

      final currentUserData = await supabaseClient
          .from('users')
          .select('full_name, avatar_url')
          .eq('id', currentUser.id)
          .single();

      // Create new conversation
      final response = await supabaseClient
          .from(DatabaseConstants.conversationsTable)
          .insert({
            'user1_id': currentUser.id,
            'user2_id': otherUserId,
            'user1_name': currentUserData['full_name'],
            'user2_name': otherUser['full_name'],
            'user1_avatar': currentUserData['avatar_url'],
            'user2_avatar': otherUser['avatar_url'],
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return ConversationModel.fromJson({
        ...response,
        'user_id': currentUser.id,
        'other_user_id': otherUserId,
        'other_user_name': otherUser['full_name'],
        'other_user_avatar': otherUser['avatar_url'],
      });
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get or create conversation: $e');
    }
  }

  @override
  Future<List<MessageModel>> getMessages({
    required String conversationId,
    int? limit,
    int? offset,
  }) async {
    try {
      final response = await supabaseClient
          .from(DatabaseConstants.messagesTable)
          .select('*, users!inner(full_name, avatar_url)')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(limit ?? 50)
          .range(offset ?? 0, (offset ?? 0) + (limit ?? 50) - 1);

      return (response as List)
          .map(
            (json) => MessageModel.fromJson({
              ...json,
              'sender_name': json['users']['full_name'],
              'sender_avatar': json['users']['avatar_url'],
            }),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get messages: $e');
    }
  }

  @override
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
    String? imageUrl,
  }) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) throw ServerException('User not authenticated');

      final response = await supabaseClient
          .from(DatabaseConstants.messagesTable)
          .insert({
            'conversation_id': conversationId,
            'sender_id': currentUser.id,
            'content': content,
            'image_url': imageUrl,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('*, users!inner(full_name, avatar_url)')
          .single();

      // Update conversation's last message
      final updateTime = DateTime.now().toIso8601String();
      debugPrint('📝 [SEND MESSAGE] Updating conversation $conversationId');
      debugPrint('   Content: "$content"');
      debugPrint('   Time: $updateTime');

      try {
        final updateResponse = await supabaseClient
            .from(DatabaseConstants.conversationsTable)
            .update({
              'last_message': content,
              'last_message_time': updateTime,
              'updated_at': updateTime,
            })
            .eq('id', conversationId)
            .select('last_message, last_message_time')
            .single();

        debugPrint('✅ [SEND MESSAGE] Conversation updated in DB:');
        debugPrint('   last_message: "${updateResponse['last_message']}"');
        debugPrint(
          '   last_message_time: ${updateResponse['last_message_time']}',
        );

        // Check if update actually worked
        if (updateResponse['last_message'] != content) {
          debugPrint('⚠️ [SEND MESSAGE] Update returned wrong value!');
          debugPrint('   Expected: "$content"');
          debugPrint('   Got: "${updateResponse['last_message']}"');
        }
      } on PostgrestException catch (e) {
        debugPrint('❌ [SEND MESSAGE] Update failed: ${e.message}');
        debugPrint('   Code: ${e.code}');
        debugPrint('   Details: ${e.details}');
        debugPrint('   Hint: ${e.hint}');
        // Don't throw - message was sent successfully, just conversation update failed
      } catch (e) {
        debugPrint(
          '❌ [SEND MESSAGE] Unexpected error updating conversation: $e',
        );
      }

      // Verify the update by fetching the conversation again
      debugPrint('🔍 [SEND MESSAGE] Verifying update...');
      final verifyResponse = await supabaseClient
          .from(DatabaseConstants.conversationsTable)
          .select('last_message, last_message_time')
          .eq('id', conversationId)
          .single();

      debugPrint('✅ [SEND MESSAGE] Verification query result:');
      debugPrint('   last_message: "${verifyResponse['last_message']}"');
      debugPrint(
        '   last_message_time: ${verifyResponse['last_message_time']}',
      );

      if (verifyResponse['last_message'] != content) {
        debugPrint('⚠️ [SEND MESSAGE] WARNING: Update verification failed!');
        debugPrint('   Expected: "$content"');
        debugPrint('   Got: "${verifyResponse['last_message']}"');
      }

      return MessageModel.fromJson({
        ...response,
        'sender_name': response['users']['full_name'],
        'sender_avatar': response['users']['avatar_url'],
      });
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to send message: $e');
    }
  }

  @override
  Future<void> markMessagesAsRead({required String conversationId}) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) throw ServerException('User not authenticated');

      await supabaseClient
          .from(DatabaseConstants.messagesTable)
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('conversation_id', conversationId)
          .neq('sender_id', currentUser.id)
          .eq('is_read', false);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to mark messages as read: $e');
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) throw ServerException('User not authenticated');

      await supabaseClient
          .from(DatabaseConstants.messagesTable)
          .delete()
          .eq('id', messageId)
          .eq('sender_id', currentUser.id);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to delete message: $e');
    }
  }

  @override
  Stream<MessageModel> subscribeToMessages(String conversationId) {
    try {
      return supabaseClient
          .from(DatabaseConstants.messagesTable)
          .stream(primaryKey: ['id'])
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .map((data) => data.map((json) => MessageModel.fromJson(json)))
          .expand((messages) => messages);
    } catch (e) {
      throw ServerException('Failed to subscribe to messages: $e');
    }
  }

  @override
  Stream<ConversationModel> subscribeToConversations() {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) throw ServerException('User not authenticated');

      debugPrint('🔴 Starting real-time subscription to conversations table');

      // Subscribe to conversations table with real-time updates
      return supabaseClient
          .from(DatabaseConstants.conversationsTable)
          .stream(primaryKey: ['id'])
          .asyncMap((data) async {
            debugPrint(
              '🔔 Real-time update received: ${data.length} conversations',
            );

            // Filter conversations for current user
            final userConversations = data
                .where(
                  (json) =>
                      json['user1_id'] == currentUser.id ||
                      json['user2_id'] == currentUser.id,
                )
                .toList();

            // For each conversation, fetch online status
            final conversations = await Future.wait(
              userConversations.map((json) async {
                final isUser1 = json['user1_id'] == currentUser.id;
                final otherUserId = isUser1
                    ? json['user2_id']
                    : json['user1_id'];

                // Fetch other user's online status
                try {
                  final otherUser = await supabaseClient
                      .from('users')
                      .select('is_online, last_seen_at')
                      .eq('id', otherUserId)
                      .single();

                  return ConversationModel.fromJson({
                    ...json,
                    'user_id': currentUser.id,
                    'other_user_id': otherUserId,
                    'other_user_name': isUser1
                        ? json['user2_name']
                        : json['user1_name'],
                    'other_user_avatar': isUser1
                        ? json['user2_avatar']
                        : json['user1_avatar'],
                    'is_online': otherUser['is_online'] ?? false,
                    'last_seen_at': otherUser['last_seen_at'],
                  });
                } catch (e) {
                  debugPrint('⚠️ Failed to fetch user status: $e');
                  return ConversationModel.fromJson({
                    ...json,
                    'user_id': currentUser.id,
                    'other_user_id': otherUserId,
                    'other_user_name': isUser1
                        ? json['user2_name']
                        : json['user1_name'],
                    'other_user_avatar': isUser1
                        ? json['user2_avatar']
                        : json['user1_avatar'],
                    'is_online': false,
                  });
                }
              }).toList(),
            );

            return conversations;
          })
          .expand((conversations) => conversations);
    } catch (e) {
      debugPrint('❌ Failed to subscribe to conversations: $e');
      throw ServerException('Failed to subscribe to conversations: $e');
    }
  }
}
