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
  });

  /// Mark messages as read
  Future<Either<Failure, void>> markMessagesAsRead({
    required String conversationId,
  });

  /// Delete a message
  Future<Either<Failure, void>> deleteMessage(String messageId);

  /// Subscribe to messages in a conversation (real-time)
  Stream<MessageEntity> subscribeToMessages(String conversationId);

  /// Subscribe to conversations (real-time updates)
  Stream<ConversationEntity> subscribeToConversations();
}

