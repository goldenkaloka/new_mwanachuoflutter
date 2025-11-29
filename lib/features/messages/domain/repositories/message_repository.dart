import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/messages/domain/entities/conversation_entity.dart';
import 'package:mwanachuo/features/messages/domain/entities/message_entity.dart';

/// Message repository interface
abstract class MessageRepository {
  /// Get all conversations for current user
  Future<Either<Failure, List<ConversationEntity>>> getConversations({
    int? limit,
    int? offset,
  });

  /// Get or create conversation with another user
  Future<Either<Failure, ConversationEntity>> getOrCreateConversation({
    required String otherUserId,
  });

  /// Get messages in a conversation
  Future<Either<Failure, List<MessageEntity>>> getMessages({
    required String conversationId,
    int? limit,
    int? offset,
  });

  /// Send a message
  Future<Either<Failure, MessageEntity>> sendMessage({
    required String conversationId,
    required String content,
    String? imageUrl,
    String? repliedToMessageId,
    Map<String, dynamic>? metadata,
  });

  /// Mark messages as read
  Future<Either<Failure, void>> markMessagesAsRead({
    required String conversationId,
  });

  /// Delete a message
  Future<Either<Failure, void>> deleteMessage(String messageId);

  /// Delete a message for current user only (WhatsApp-style soft delete)
  Future<Either<Failure, void>> deleteMessageForUser(String messageId);

  /// Delete a conversation and all its messages
  Future<Either<Failure, void>> deleteConversation(String conversationId);

  /// Subscribe to messages in a conversation (real-time)
  Stream<List<MessageEntity>> subscribeToMessages(String conversationId);

  /// Subscribe to conversations (real-time updates)
  Stream<ConversationEntity> subscribeToConversations();

  /// Send typing indicator
  Future<Either<Failure, void>> sendTypingIndicator({
    required String conversationId,
    required bool isTyping,
  });

  /// Subscribe to typing indicators
  Stream<bool> subscribeToTypingIndicator(String conversationId);

  /// Upload image for message
  Future<Either<Failure, String>> uploadImage(String filePath);

  /// Search messages across all conversations
  Future<Either<Failure, List<MessageEntity>>> searchMessages({
    required String query,
    int? limit,
  });
}
