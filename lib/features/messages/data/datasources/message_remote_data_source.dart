import 'dart:io';
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
  Future<void> sendTypingIndicator({
    required String conversationId,
    required bool isTyping,
  });
  Stream<bool> subscribeToTypingIndicator(String conversationId);
  Future<String> uploadImage(String filePath);
  Future<List<MessageModel>> searchMessages({
    required String query,
    int? limit,
  });
}

class MessageRemoteDataSourceImpl implements MessageRemoteDataSource {
  final SupabaseClient supabaseClient;

  MessageRemoteDataSourceImpl({required this.supabaseClient});

  /// Helper method to batch fetch unread message counts for multiple conversations
  Future<Map<String, int>> _getUnreadCounts(
    List<String> conversationIds,
    String currentUserId,
  ) async {
    if (conversationIds.isEmpty) return {};

    try {
      // Batch fetch unread counts for all conversations
      final results = await Future.wait(
        conversationIds.map((convId) async {
          final response = await supabaseClient
              .from(DatabaseConstants.messagesTable)
              .select('id')
              .eq('conversation_id', convId)
              .neq('sender_id', currentUserId)
              .eq('is_read', false);

          return MapEntry(convId, (response as List).length);
        }),
      );

      return Map.fromEntries(results);
    } catch (e) {
      debugPrint('⚠️ Failed to fetch unread counts: $e');
      return {};
    }
  }

  @override
  Future<List<ConversationModel>> getConversations({
    int? limit,
    int? offset,
  }) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) throw ServerException('User not authenticated');

      // Join with users table to get online status and last seen
      // Note: unread_count will be calculated separately due to Supabase limitations
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

      final List<dynamic> data = response as List<dynamic>;
      if (data.isEmpty) {
        return [];
      }

      // Batch fetch unread counts for all conversations
      final conversationIds = data.map((json) => json['id'] as String).toList();
      final unreadCounts = await _getUnreadCounts(
        conversationIds,
        currentUser.id,
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
          'unread_count': unreadCounts[conversationId] ?? 0,
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

      try {
        await supabaseClient
            .from(DatabaseConstants.conversationsTable)
            .update({
              'last_message': content,
              'last_message_time': updateTime,
              'updated_at': updateTime,
            })
            .eq('id', conversationId);
      } on PostgrestException catch (e) {
        debugPrint(
          '⚠️ Failed to update conversation last message: ${e.message}',
        );
        // Don't throw - message was sent successfully, just conversation update failed
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
          .asyncMap((rows) async {
            if (rows.isEmpty) return <MessageModel>[];

            // Batch fetch user details for all messages to avoid N+1 queries
            final senderIds = rows
                .map((r) => r['sender_id'] as String)
                .toSet()
                .toList();

            final users = await supabaseClient
                .from('users')
                .select('id, full_name, avatar_url')
                .inFilter('id', senderIds);

            // Create a map for quick lookup
            final userMap = <String, Map<String, dynamic>>{};
            for (var user in users) {
              userMap[user['id'] as String] = user;
            }

            return rows.map((json) {
              final senderId = json['sender_id'] as String;
              final user = userMap[senderId];
              return MessageModel.fromJson({
                ...json,
                'sender_name': user?['full_name'] ?? 'Unknown',
                'sender_avatar': user?['avatar_url'],
              });
            }).toList();
          })
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

      // Subscribe to conversations table with real-time updates
      return supabaseClient
          .from(DatabaseConstants.conversationsTable)
          .stream(primaryKey: ['id'])
          .asyncMap((data) async {
            // Filter conversations for current user
            final userConversations = data
                .where(
                  (json) =>
                      json['user1_id'] == currentUser.id ||
                      json['user2_id'] == currentUser.id,
                )
                .toList();

            if (userConversations.isEmpty) return <ConversationModel>[];

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

  @override
  Future<void> sendTypingIndicator({
    required String conversationId,
    required bool isTyping,
  }) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) throw ServerException('User not authenticated');

      if (isTyping) {
        // Insert or update typing indicator
        await supabaseClient.from('typing_indicators').upsert({
          'conversation_id': conversationId,
          'user_id': currentUser.id,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        // Remove typing indicator
        await supabaseClient
            .from('typing_indicators')
            .delete()
            .eq('conversation_id', conversationId)
            .eq('user_id', currentUser.id);
      }
    } catch (e) {
      // Silently fail for typing indicators as they're not critical
      debugPrint('⚠️ Failed to send typing indicator: $e');
    }
  }

  @override
  Stream<bool> subscribeToTypingIndicator(String conversationId) {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) throw ServerException('User not authenticated');

      return supabaseClient
          .from('typing_indicators')
          .stream(primaryKey: ['conversation_id', 'user_id'])
          .eq('conversation_id', conversationId)
          .map((data) {
            // Check if any other user is typing (not current user)
            final otherUsersTyping = data.where(
              (indicator) => indicator['user_id'] != currentUser.id,
            );

            if (otherUsersTyping.isEmpty) return false;

            // Check if typing indicator is recent (within last 5 seconds)
            final latestIndicator = otherUsersTyping.first;
            final updatedAt = DateTime.parse(
              latestIndicator['updated_at'] as String,
            );
            final difference = DateTime.now().difference(updatedAt);

            return difference.inSeconds < 5;
          });
    } catch (e) {
      debugPrint('⚠️ Failed to subscribe to typing indicator: $e');
      return Stream.value(false);
    }
  }

  @override
  Future<String> uploadImage(String filePath) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) throw ServerException('User not authenticated');

      final fileName =
          '${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'message_images/$fileName';

      // Upload to Supabase Storage
      await supabaseClient.storage
          .from('messages')
          .upload(storagePath, File(filePath));

      // Get public URL
      final publicUrl = supabaseClient.storage
          .from('messages')
          .getPublicUrl(storagePath);

      return publicUrl;
    } on StorageException catch (e) {
      throw ServerException('Failed to upload image: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to upload image: $e');
    }
  }

  @override
  Future<List<MessageModel>> searchMessages({
    required String query,
    int? limit,
  }) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) throw ServerException('User not authenticated');

      // Get all conversations for the current user first
      final conversations = await supabaseClient
          .from(DatabaseConstants.conversationsTable)
          .select('id')
          .or('user1_id.eq.${currentUser.id},user2_id.eq.${currentUser.id}');

      final conversationIds = (conversations as List)
          .map((c) => c['id'] as String)
          .toList();

      if (conversationIds.isEmpty) return [];

      // Search messages in user's conversations
      final response = await supabaseClient
          .from(DatabaseConstants.messagesTable)
          .select('*, users!inner(full_name, avatar_url)')
          .inFilter('conversation_id', conversationIds)
          .ilike('content', '%$query%')
          .order('created_at', ascending: false)
          .limit(limit ?? 50);

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
      throw ServerException('Search failed: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to search messages: $e');
    }
  }
}
