import 'dart:convert';
import 'package:mwanachuo/core/constants/storage_constants.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/features/messages/data/models/conversation_model.dart';
import 'package:mwanachuo/features/messages/data/models/message_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstract class defining message local data source operations
abstract class MessageLocalDataSource {
  /// Cache conversations
  Future<void> cacheConversations(List<ConversationModel> conversations);

  /// Get cached conversations
  Future<List<ConversationModel>> getCachedConversations();

  /// Cache messages for a conversation
  Future<void> cacheMessages(String conversationId, List<MessageModel> messages);

  /// Get cached messages for a conversation
  Future<List<MessageModel>> getCachedMessages(String conversationId);

  /// Update conversation cache (when new message arrives)
  Future<void> updateConversationCache(ConversationModel conversation);

  /// Check if conversations cache is expired
  bool isConversationsCacheExpired();

  /// Check if messages cache is expired for a conversation
  bool isMessagesCacheExpired(String conversationId);

  /// Clear all message cache
  Future<void> clearCache();
}

/// Implementation of MessageLocalDataSource using SharedPreferences
class MessageLocalDataSourceImpl implements MessageLocalDataSource {
  final SharedPreferences sharedPreferences;

  MessageLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheConversations(List<ConversationModel> conversations) async {
    try {
      final jsonList = conversations.map((c) => c.toJson()).toList();
      await sharedPreferences.setString(
        StorageConstants.conversationsCacheKey,
        json.encode(jsonList),
      );
      
      // Save timestamp
      await sharedPreferences.setInt(
        '${StorageConstants.conversationsCacheKey}_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      throw CacheException('Failed to cache conversations: $e');
    }
  }

  @override
  Future<List<ConversationModel>> getCachedConversations() async {
    try {
      final jsonString = sharedPreferences.getString(
        StorageConstants.conversationsCacheKey,
      );

      if (jsonString == null) {
        throw CacheException('No cached conversations found');
      }

      final jsonList = json.decode(jsonString) as List;
      return jsonList.map((json) => ConversationModel.fromJson(json)).toList();
    } catch (e) {
      throw CacheException('Failed to get cached conversations: $e');
    }
  }

  @override
  Future<void> cacheMessages(String conversationId, List<MessageModel> messages) async {
    try {
      final jsonList = messages.map((m) => m.toJson()).toList();
      await sharedPreferences.setString(
        '${StorageConstants.messagesCachePrefix}_$conversationId',
        json.encode(jsonList),
      );
      
      // Save timestamp
      await sharedPreferences.setInt(
        '${StorageConstants.conversationTimestampPrefix}_$conversationId',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      throw CacheException('Failed to cache messages: $e');
    }
  }

  @override
  Future<List<MessageModel>> getCachedMessages(String conversationId) async {
    try {
      final jsonString = sharedPreferences.getString(
        '${StorageConstants.messagesCachePrefix}_$conversationId',
      );

      if (jsonString == null) {
        throw CacheException('No cached messages found');
      }

      final jsonList = json.decode(jsonString) as List;
      return jsonList.map((json) => MessageModel.fromJson(json)).toList();
    } catch (e) {
      throw CacheException('Failed to get cached messages: $e');
    }
  }

  @override
  Future<void> updateConversationCache(ConversationModel conversation) async {
    try {
      // Get existing cached conversations
      final conversations = await getCachedConversations();
      
      // Find and update the conversation
      final index = conversations.indexWhere((c) => c.id == conversation.id);
      if (index != -1) {
        conversations[index] = conversation;
        await cacheConversations(conversations);
      }
    } catch (e) {
      // If no cache exists, just skip
    }
  }

  @override
  bool isConversationsCacheExpired() {
    final timestamp = sharedPreferences.getInt(
      '${StorageConstants.conversationsCacheKey}_timestamp',
    );

    if (timestamp == null) return true;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(cacheTime).inMinutes;

    return difference >= StorageConstants.conversationsCacheExpiration;
  }

  @override
  bool isMessagesCacheExpired(String conversationId) {
    final timestamp = sharedPreferences.getInt(
      '${StorageConstants.conversationTimestampPrefix}_$conversationId',
    );

    if (timestamp == null) return true;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(cacheTime).inMinutes;

    return difference >= StorageConstants.messagesCacheExpiration;
  }

  @override
  Future<void> clearCache() async {
    try {
      // Remove conversations cache
      await sharedPreferences.remove(StorageConstants.conversationsCacheKey);
      await sharedPreferences.remove('${StorageConstants.conversationsCacheKey}_timestamp');
      
      // Remove all message caches
      final keys = sharedPreferences.getKeys();
      final messageKeys = keys.where((key) =>
          key.startsWith(StorageConstants.messagesCachePrefix) ||
          key.startsWith(StorageConstants.conversationTimestampPrefix));
      
      for (final key in messageKeys) {
        await sharedPreferences.remove(key);
      }
    } catch (e) {
      throw CacheException('Failed to clear cache: $e');
    }
  }
}

