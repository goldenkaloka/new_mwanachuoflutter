import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:mwanachuo/core/constants/storage_constants.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/network/network_info.dart';
import 'package:mwanachuo/features/messages/data/datasources/message_remote_data_source.dart';
import 'package:mwanachuo/features/messages/data/datasources/message_local_data_source.dart';
import 'package:mwanachuo/features/messages/domain/entities/conversation_entity.dart';
import 'package:mwanachuo/features/messages/domain/entities/message_entity.dart';
import 'package:mwanachuo/features/messages/domain/repositories/message_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MessageRepositoryImpl implements MessageRepository {
  final MessageRemoteDataSource remoteDataSource;
  final MessageLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final SharedPreferences sharedPreferences;

  MessageRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.sharedPreferences,
  });

  @override
  Future<Either<Failure, List<ConversationEntity>>> getConversations({
    int? limit,
    int? offset,
  }) async {
    // Try cache first if not expired
    if (!localDataSource.isConversationsCacheExpired()) {
      try {
        debugPrint('💾 Loading conversations from cache');
        final cachedConversations = await localDataSource.getCachedConversations();
        return Right(cachedConversations);
      } on CacheException {
        debugPrint('❌ Cache miss, fetching from server');
      }
    }

    // Check network
    if (!await networkInfo.isConnected) {
      // Try to return cached data even if expired
      try {
        final cachedConversations = await localDataSource.getCachedConversations();
        return Right(cachedConversations);
      } on CacheException {
        return Left(NetworkFailure('No internet connection and no cached data'));
      }
    }

    // Fetch from server
    try {
      debugPrint('🌐 Fetching conversations from server');
      final conversations = await remoteDataSource.getConversations(
        limit: limit,
        offset: offset,
      );
      
      // Cache the result
      await localDataSource.cacheConversations(conversations);
      debugPrint('✅ Conversations cached successfully');
      
      return Right(conversations);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get conversations: $e'));
    }
  }

  @override
  Future<Either<Failure, ConversationEntity>> getOrCreateConversation({
    required String otherUserId,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final conversation = await remoteDataSource.getOrCreateConversation(
        otherUserId: otherUserId,
      );
      return Right(conversation);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get or create conversation: $e'));
    }
  }

  @override
  Future<Either<Failure, List<MessageEntity>>> getMessages({
    required String conversationId,
    int? limit,
    int? offset,
  }) async {
    // Try cache first if not expired
    if (!localDataSource.isMessagesCacheExpired(conversationId)) {
      try {
        debugPrint('💾 Loading messages from cache for conversation: $conversationId');
        final cachedMessages = await localDataSource.getCachedMessages(conversationId);
        return Right(cachedMessages);
      } on CacheException {
        debugPrint('❌ Cache miss for messages, fetching from server');
      }
    }

    // Check network
    if (!await networkInfo.isConnected) {
      // Try to return cached data even if expired
      try {
        final cachedMessages = await localDataSource.getCachedMessages(conversationId);
        return Right(cachedMessages);
      } on CacheException {
        return Left(NetworkFailure('No internet connection and no cached messages'));
      }
    }

    // Fetch from server
    try {
      debugPrint('🌐 Fetching messages from server for conversation: $conversationId');
      final messages = await remoteDataSource.getMessages(
        conversationId: conversationId,
        limit: limit,
        offset: offset,
      );
      
      // Cache the result
      await localDataSource.cacheMessages(conversationId, messages);
      debugPrint('✅ Messages cached successfully');
      
      return Right(messages);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get messages: $e'));
    }
  }

  @override
  Future<Either<Failure, MessageEntity>> sendMessage({
    required String conversationId,
    required String content,
    String? imageUrl,
    String? repliedToMessageId,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final message = await remoteDataSource.sendMessage(
        conversationId: conversationId,
        content: content,
        imageUrl: imageUrl,
        repliedToMessageId: repliedToMessageId,
      );
      
      // Incrementally update cache instead of clearing it
      try {
        // Add message to messages cache
        await localDataSource.addMessageToCache(conversationId, message);
        
        // Update conversation's last message in conversations cache
        await localDataSource.updateConversationLastMessage(
          conversationId,
          content,
          message.createdAt,
        );
      } catch (e) {
        debugPrint('⚠️ Failed to update cache incrementally: $e');
      }
      
      return Right(message);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to send message: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markMessagesAsRead({
    required String conversationId,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Right(null);
    }

    try {
      await remoteDataSource.markMessagesAsRead(
        conversationId: conversationId,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to mark messages as read: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage(String messageId) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.deleteMessage(messageId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to delete message: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteConversation(String conversationId) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.deleteConversation(conversationId);
      // Clear cache after deletion
      await sharedPreferences.remove(StorageConstants.conversationsCacheKey);
      await sharedPreferences.remove(
        '${StorageConstants.conversationsCacheKey}_timestamp',
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to delete conversation: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessageForUser(String messageId) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.deleteMessageForUser(messageId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to delete message: $e'));
    }
  }

  @override
  Stream<MessageEntity> subscribeToMessages(String conversationId) {
    return remoteDataSource.subscribeToMessages(conversationId);
  }

  @override
  Stream<ConversationEntity> subscribeToConversations() {
    return remoteDataSource.subscribeToConversations();
  }

  @override
  Future<Either<Failure, void>> sendTypingIndicator({
    required String conversationId,
    required bool isTyping,
  }) async {
    try {
      await remoteDataSource.sendTypingIndicator(
        conversationId: conversationId,
        isTyping: isTyping,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to send typing indicator: $e'));
    }
  }

  @override
  Stream<bool> subscribeToTypingIndicator(String conversationId) {
    return remoteDataSource.subscribeToTypingIndicator(conversationId);
  }

  @override
  Future<Either<Failure, String>> uploadImage(String filePath) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final imageUrl = await remoteDataSource.uploadImage(filePath);
      return Right(imageUrl);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to upload image: $e'));
    }
  }

  @override
  Future<Either<Failure, List<MessageEntity>>> searchMessages({
    required String query,
    int? limit,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final messages = await remoteDataSource.searchMessages(
        query: query,
        limit: limit,
      );
      return Right(messages);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to search messages: $e'));
    }
  }
}

