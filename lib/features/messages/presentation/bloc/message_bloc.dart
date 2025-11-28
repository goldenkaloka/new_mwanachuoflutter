import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/config/supabase_config.dart';
import 'package:mwanachuo/core/constants/storage_constants.dart';
import 'package:mwanachuo/core/services/logger_service.dart';

import 'package:mwanachuo/features/messages/domain/repositories/message_repository.dart';
import 'package:mwanachuo/features/messages/domain/usecases/get_conversations.dart';
import 'package:mwanachuo/features/messages/domain/usecases/get_messages.dart';
import 'package:mwanachuo/features/messages/domain/usecases/get_or_create_conversation.dart';
import 'package:mwanachuo/features/messages/domain/usecases/send_message.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/message_event.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/message_state.dart';
import 'package:mwanachuo/features/messages/domain/entities/message_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final GetConversations getConversations;
  final GetOrCreateConversation getOrCreateConversation;
  final GetMessages getMessages;
  final SendMessage sendMessage;
  final MessageRepository messageRepository;
  final SharedPreferences sharedPreferences;

  StreamSubscription? _messageSubscription;
  StreamSubscription? _conversationSubscription;

  MessageBloc({
    required this.getConversations,
    required this.getOrCreateConversation,
    required this.getMessages,
    required this.sendMessage,
    required this.messageRepository,
    required this.sharedPreferences,
  }) : super(MessageInitial()) {
    on<LoadConversationsEvent>(_onLoadConversations);
    on<GetOrCreateConversationEvent>(_onGetOrCreateConversation);
    on<LoadMessagesEvent>(_onLoadMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<MarkMessagesAsReadEvent>(_onMarkMessagesAsRead);
    on<DeleteConversationEvent>(_onDeleteConversation);
    on<DeleteMessageForUserEvent>(_onDeleteMessageForUser);
    on<StartListeningToMessagesEvent>(_onStartListeningToMessages);
    on<StartListeningToConversationsEvent>(_onStartListeningToConversations);
    on<StopListeningEvent>(_onStopListening);
    on<SendTypingIndicatorEvent>(_onSendTypingIndicator);
    on<UploadImageEvent>(_onUploadImage);
    on<SearchMessagesEvent>(_onSearchMessages);
    on<LoadMoreMessagesEvent>(_onLoadMoreMessages);
    on<RetryMessageEvent>(_onRetryMessage);
    on<MessagesUpdatedEvent>(_onMessagesUpdated);
  }

  Future<void> _onLoadConversations(
    LoadConversationsEvent event,
    Emitter<MessageState> emit,
  ) async {
    // If force refresh, clear cache first
    if (event.forceRefresh) {
      await sharedPreferences.remove(StorageConstants.conversationsCacheKey);
      await sharedPreferences.remove(
        '${StorageConstants.conversationsCacheKey}_timestamp',
      );
    }

    emit(ConversationsLoading());

    final result = await getConversations(
      GetConversationsParams(limit: event.limit, offset: event.offset),
    );

    result.fold(
      (failure) => emit(MessageError(message: failure.message)),
      (conversations) =>
          emit(ConversationsLoaded(conversations: conversations)),
    );
  }

  Future<void> _onGetOrCreateConversation(
    GetOrCreateConversationEvent event,
    Emitter<MessageState> emit,
  ) async {
    emit(ConversationLoading());

    final result = await getOrCreateConversation(
      GetOrCreateConversationParams(otherUserId: event.otherUserId),
    );

    result.fold(
      (failure) => emit(MessageError(message: failure.message)),
      (conversation) => emit(ConversationLoaded(conversation: conversation)),
    );
  }

  Future<void> _onLoadMessages(
    LoadMessagesEvent event,
    Emitter<MessageState> emit,
  ) async {
    emit(MessagesLoading());

    final result = await getMessages(
      GetMessagesParams(
        conversationId: event.conversationId,
        limit: event.limit ?? 50,
        offset: event.offset,
      ),
    );

    result.fold((failure) => emit(MessageError(message: failure.message)), (
      messages,
    ) {
      final hasMore = messages.length >= (event.limit ?? 50);
      emit(
        MessagesLoaded(
          messages: messages,
          conversationId: event.conversationId,
          hasMore: hasMore,
        ),
      );
    });
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<MessageState> emit,
  ) async {
    // Capture current state before async operation
    final currentState = state;
    final MessagesLoaded? messagesLoadedState =
        currentState is MessagesLoaded &&
            currentState.conversationId == event.conversationId
        ? currentState
        : null;

    final currentUser = SupabaseConfig.client.auth.currentUser;
    if (currentUser == null) {
      emit(const MessageError(message: 'User not authenticated'));
      return;
    }

    // Get recent messages for context-aware validation
    List<String> recentMessages = [];
    if (messagesLoadedState != null) {
      // Extract content from recent messages (last 5 messages from current user)
      recentMessages = messagesLoadedState.messages
          .where(
            (m) => m.senderId == currentUser.id,
          ) // Only user's own messages
          .take(5) // Last 5 messages
          .map((m) => m.content)
          .where((c) => c.isNotEmpty)
          .toList()
          .reversed
          .toList(); // Reverse to get chronological order
    }

    // 1. OPTIMISTIC UPDATE
    // Create a temporary message to show immediately
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    // We need to fetch current user details for the optimistic message
    // In a real app, we should have this in a UserBloc or similar
    // For now, we'll try to use data from existing messages if available, or placeholders
    String senderName = 'Me';
    String? senderAvatar;

    if (messagesLoadedState != null &&
        messagesLoadedState.messages.isNotEmpty) {
      final myMessage = messagesLoadedState.messages.firstWhere(
        (m) => m.senderId == currentUser.id,
        orElse: () => messagesLoadedState
            .messages
            .first, // Fallback (risky if no my messages)
      );
      if (myMessage.senderId == currentUser.id) {
        senderName = myMessage.senderName;
        senderAvatar = myMessage.senderAvatar;
      }
    }

    // Create the optimistic message entity
    // We need to import MessageEntity if not available, but it should be
    // We'll construct it manually since we can't import it here easily in the tool
    // Assuming MessageEntity is available as it's used in the state
    // We need to map it to the Entity class structure
    // Since we can't easily instantiate MessageEntity without importing it in this block
    // (it is imported at top of file), we assume it's available.

    // However, MessageEntity might not have a constructor that accepts all these directly
    // if it's not the default one. Let's assume standard constructor.

    // Wait, I cannot create MessageEntity here if I don't know the exact import or if it's not imported.
    // It IS imported: import 'package:mwanachuo/features/messages/domain/entities/message_entity.dart';

    // But I need to make sure I match the constructor.
    // const MessageEntity({
    //   required this.id,
    //   required this.conversationId,
    //   required this.senderId,
    //   required this.senderName,
    //   this.senderAvatar,
    //   required this.content,
    //   this.imageUrl,
    //   this.isRead = false,
    //   required this.createdAt,
    //   this.readAt,
    //   this.deliveredAt,
    //   this.repliedToMessageId,
    //   this.deletedBy = const [],
    // });

    // We'll create a "fake" entity for the optimistic update
    // We need to be careful about the type.
    // Since I cannot see the imports in this tool window (I saw them in previous turn),
    // I know MessageEntity is imported.

    // We need to use a dynamic approach or just trust the constructor.
    // Let's use the repository to create it if possible? No, repository returns models.

    // I will use a helper method or just instantiate it.

    // OPTIMISTIC UPDATE LOGIC
    if (messagesLoadedState != null) {
      // Create optimistic message
      final optimisticMessage = MessageEntity(
        id: tempId,
        conversationId: event.conversationId,
        senderId: currentUser.id,
        senderName: senderName,
        senderAvatar: senderAvatar,
        content: event.content,
        imageUrl: event.imageUrl,
        createdAt: DateTime.now(),
        isRead: false,
        repliedToMessageId: event.repliedToMessageId,
        // Status will be inferred as 'sent' (one tick) initially
        // We might want a way to indicate 'sending' (clock icon)
        // For now, we rely on isSending flag in state or we could add a local property
      );

      // Add to list immediately (at the top)
      final optimisticMessages = [
        optimisticMessage,
        ...messagesLoadedState.messages,
      ];
      emit(
        messagesLoadedState.copyWith(
          messages: optimisticMessages,
          isSending: true,
        ),
      );
    } else {
      emit(MessageSending());
    }

    final result = await sendMessage(
      SendMessageParams(
        conversationId: event.conversationId,
        content: event.content,
        imageUrl: event.imageUrl,
        repliedToMessageId: event.repliedToMessageId,
        recentMessages: recentMessages, // Pass context for validation
      ),
    );

    result.fold(
      (failure) {
        // On error, remove the optimistic message and show error
        if (messagesLoadedState != null) {
          // Revert to original messages (without optimistic one)
          // And set error message to be shown in UI (e.g. Snackbar)
          emit(
            messagesLoadedState.copyWith(
              messages: messagesLoadedState.messages,
              isSending: false,
              error: failure.message,
            ),
          );
        } else {
          emit(MessageError(message: failure.message));
        }
      },
      (message) {
        // Successfully sent
        if (messagesLoadedState != null) {
          // Replace the optimistic message with the real one
          // We assume the optimistic message is at index 0
          // But to be safe, we filter out the temp ID and add the new one
          final currentMessages = (state is MessagesLoaded)
              ? (state as MessagesLoaded).messages
              : messagesLoadedState.messages;

          final updatedMessages = [
            message,
            ...currentMessages.where((m) => m.id != tempId),
          ];

          emit(
            messagesLoadedState.copyWith(
              messages: updatedMessages,
              isSending: false,
            ),
          );
        } else {
          emit(MessageSent(message: message));
          add(LoadMessagesEvent(conversationId: event.conversationId));
        }

        // Also reload conversations to update last message (silently)
        if (!isClosed) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!isClosed) {
              add(const LoadConversationsEvent(forceRefresh: true));
            }
          });
        }
      },
    );
  }

  Future<void> _onMarkMessagesAsRead(
    MarkMessagesAsReadEvent event,
    Emitter<MessageState> emit,
  ) async {
    try {
      await messageRepository.markMessagesAsRead(
        conversationId: event.conversationId,
      );
      // Success - real-time subscription will handle UI updates
      // Optimistic UI already updated in the messages page
    } catch (e, stackTrace) {
      LoggerService.error('Failed to mark messages as read', e, stackTrace);
    }
  }

  Future<void> _onDeleteConversation(
    DeleteConversationEvent event,
    Emitter<MessageState> emit,
  ) async {
    try {
      final result = await messageRepository.deleteConversation(
        event.conversationId,
      );

      result.fold(
        (failure) {
          emit(MessageError(message: failure.message));
        },
        (_) {
          // Reload conversations after deletion
          add(const LoadConversationsEvent(forceRefresh: true));
        },
      );
    } catch (e, stackTrace) {
      LoggerService.error('Failed to delete conversation', e, stackTrace);
      emit(const MessageError(message: 'Failed to delete conversation'));
    }
  }

  Future<void> _onDeleteMessageForUser(
    DeleteMessageForUserEvent event,
    Emitter<MessageState> emit,
  ) async {
    try {
      final result = await messageRepository.deleteMessageForUser(
        event.messageId,
      );

      result.fold(
        (failure) {
          LoggerService.error('Failed to delete message: ${failure.message}');
          emit(MessageError(message: failure.message));
        },
        (_) {
          // Message deleted successfully - state will be updated via message reload
          LoggerService.debug(
            'Message ${event.messageId} deleted successfully',
          );
        },
      );
    } catch (e, stackTrace) {
      LoggerService.error('Failed to delete message', e, stackTrace);
      emit(const MessageError(message: 'Failed to delete message'));
    }
  }

  Future<void> _onStartListeningToMessages(
    StartListeningToMessagesEvent event,
    Emitter<MessageState> emit,
  ) async {
    // Cancel existing subscription
    await _messageSubscription?.cancel();

    // Subscribe to new messages in this conversation
    _messageSubscription = messageRepository
        .subscribeToMessages(event.conversationId)
        .listen(
          (messages) {
            add(
              MessagesUpdatedEvent(
                messages: messages,
                conversationId: event.conversationId,
              ),
            );
          },
          onError: (error) {
            debugPrint('⚠️ Real-time message subscription error: $error');
          },
        );
  }

  void _onMessagesUpdated(
    MessagesUpdatedEvent event,
    Emitter<MessageState> emit,
  ) {
    final currentState = state;

    // Only update if we are in loaded state for the same conversation
    // Or if we are loading (to show initial data)
    if (currentState is MessagesLoaded &&
        currentState.conversationId == event.conversationId) {
      // Merge logic to preserve pagination and optimistic updates:
      // 1. Create a map of current messages by ID
      final Map<String, MessageEntity> messageMap = {
        for (var m in currentState.messages) m.id: m,
      };

      // 2. Update/Add messages from the stream
      for (var m in event.messages) {
        messageMap[m.id] = m;
      }

      // 3. Convert back to list and sort by created_at desc
      final mergedMessages = messageMap.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      emit(currentState.copyWith(messages: mergedMessages));
    } else if (currentState is MessagesLoading ||
        currentState is MessageInitial) {
      // Initial load from stream
      emit(
        MessagesLoaded(
          messages: event.messages,
          conversationId: event.conversationId,
        ),
      );
    }
  }

  Future<void> _onStartListeningToConversations(
    StartListeningToConversationsEvent event,
    Emitter<MessageState> emit,
  ) async {
    // Cancel existing subscription
    await _conversationSubscription?.cancel();

    // Clear conversations cache to force fresh data on initial load
    await sharedPreferences.remove(StorageConstants.conversationsCacheKey);
    await sharedPreferences.remove(
      '${StorageConstants.conversationsCacheKey}_timestamp',
    );

    // Load initial data
    emit(ConversationsLoading());
    final initialResult = await getConversations(
      const GetConversationsParams(),
    );

    initialResult.fold(
      (failure) {
        emit(MessageError(message: failure.message));
        return;
      },
      (conversations) {
        emit(ConversationsLoaded(conversations: conversations));
      },
    );

    // Now subscribe to real-time updates
    // Note: We cannot use emit() in the stream callback since the handler
    // has already completed. Instead, we dispatch a new event.
    _conversationSubscription = messageRepository
        .subscribeToConversations()
        .listen(
          (updatedConversation) async {
            // Clear cache to force fresh fetch
            await sharedPreferences.remove(
              StorageConstants.conversationsCacheKey,
            );
            await sharedPreferences.remove(
              '${StorageConstants.conversationsCacheKey}_timestamp',
            );

            // Dispatch a new event to reload conversations
            // This ensures emit() is called in a proper event handler context
            if (!isClosed) {
              add(const LoadConversationsEvent(forceRefresh: true));
            }
          },
          onError: (error) {
            debugPrint('⚠️ Real-time subscription error: $error');
          },
        );
  }

  Future<void> _onStopListening(
    StopListeningEvent event,
    Emitter<MessageState> emit,
  ) async {
    await _messageSubscription?.cancel();
    await _conversationSubscription?.cancel();
  }

  Future<void> _onSendTypingIndicator(
    SendTypingIndicatorEvent event,
    Emitter<MessageState> emit,
  ) async {
    // Send typing indicator without emitting state
    // This is a fire-and-forget operation
    await messageRepository.sendTypingIndicator(
      conversationId: event.conversationId,
      isTyping: event.isTyping,
    );
  }

  Future<void> _onUploadImage(
    UploadImageEvent event,
    Emitter<MessageState> emit,
  ) async {
    emit(ImageUploading());

    final result = await messageRepository.uploadImage(event.filePath);

    result.fold(
      (failure) => emit(MessageError(message: failure.message)),
      (imageUrl) => emit(ImageUploaded(imageUrl: imageUrl)),
    );
  }

  Future<void> _onSearchMessages(
    SearchMessagesEvent event,
    Emitter<MessageState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(const SearchResultsLoaded(results: [], query: ''));
      return;
    }

    emit(MessagesLoading());

    final result = await messageRepository.searchMessages(
      query: event.query,
      limit: event.limit,
    );

    result.fold(
      (failure) => emit(MessageError(message: failure.message)),
      (messages) =>
          emit(SearchResultsLoaded(results: messages, query: event.query)),
    );
  }

  Future<void> _onLoadMoreMessages(
    LoadMoreMessagesEvent event,
    Emitter<MessageState> emit,
  ) async {
    final currentState = state;

    // Only load more if we have messages loaded and not already loading
    if (currentState is! MessagesLoaded) return;
    if (currentState.isLoadingMore || !currentState.hasMore) return;

    // Show loading state while keeping current messages
    emit(currentState.copyWith(isLoadingMore: true));

    final result = await getMessages(
      GetMessagesParams(
        conversationId: event.conversationId,
        limit: 50,
        offset: currentState.messages.length,
      ),
    );

    result.fold(
      (failure) {
        // Revert loading state on error
        emit(currentState.copyWith(isLoadingMore: false));
      },
      (newMessages) {
        final allMessages = [...currentState.messages, ...newMessages];
        final hasMore =
            newMessages.length >=
            50; // If we got less than limit, no more messages

        emit(
          MessagesLoaded(
            messages: allMessages,
            conversationId: event.conversationId,
            hasMore: hasMore,
            isLoadingMore: false,
          ),
        );
      },
    );
  }

  Future<void> _onRetryMessage(
    RetryMessageEvent event,
    Emitter<MessageState> emit,
  ) async {
    // Retry sending a failed message with exponential backoff
    final retryCount = event.retryCount ?? 0;
    final maxRetries = 3;

    if (retryCount >= maxRetries) {
      emit(
        const MessageError(
          message: 'Failed to send message after multiple attempts',
        ),
      );
      return;
    }

    // Exponential backoff: 2^retryCount seconds (1s, 2s, 4s)
    if (retryCount > 0) {
      final delaySeconds = (1 << retryCount); // 2^retryCount
      debugPrint(
        'Retrying message after ${delaySeconds}s delay (attempt ${retryCount + 1}/$maxRetries)',
      );
      await Future.delayed(Duration(seconds: delaySeconds));
    }

    // Retry sending the message
    add(
      SendMessageEvent(
        conversationId: event.conversationId,
        content: event.content,
        imageUrl: event.imageUrl,
      ),
    );
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _conversationSubscription?.cancel();
    return super.close();
  }
}
