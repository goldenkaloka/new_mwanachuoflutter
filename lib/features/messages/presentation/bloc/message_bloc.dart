import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/constants/storage_constants.dart';
import 'package:mwanachuo/features/messages/domain/repositories/message_repository.dart';
import 'package:mwanachuo/features/messages/domain/usecases/get_conversations.dart';
import 'package:mwanachuo/features/messages/domain/usecases/get_messages.dart';
import 'package:mwanachuo/features/messages/domain/usecases/get_or_create_conversation.dart';
import 'package:mwanachuo/features/messages/domain/usecases/send_message.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/message_event.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/message_state.dart';
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
    on<StartListeningToMessagesEvent>(_onStartListeningToMessages);
    on<StartListeningToConversationsEvent>(_onStartListeningToConversations);
    on<StopListeningEvent>(_onStopListening);
    on<SendTypingIndicatorEvent>(_onSendTypingIndicator);
    on<UploadImageEvent>(_onUploadImage);
    on<SearchMessagesEvent>(_onSearchMessages);
    on<LoadMoreMessagesEvent>(_onLoadMoreMessages);
    on<RetryMessageEvent>(_onRetryMessage);
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

    // Show sending state
    if (messagesLoadedState != null) {
      // Optimistically show sending state while keeping current messages
      emit(messagesLoadedState.copyWith(isSending: true));
    } else {
      emit(MessageSending());
    }

    final result = await sendMessage(
      SendMessageParams(
        conversationId: event.conversationId,
        content: event.content,
        imageUrl: event.imageUrl,
      ),
    );

    result.fold(
      (failure) {
        // On error, restore previous state or show error
        if (messagesLoadedState != null) {
          emit(messagesLoadedState.copyWith(isSending: false));
        } else {
          emit(MessageError(message: failure.message));
        }
      },
      (message) {
        // Successfully sent - optimistically add message to current state
        if (messagesLoadedState != null) {
          // Use the captured state (before isSending was set)
          // Messages are ordered newest first (descending), so add new message at the beginning
          final originalMessages = messagesLoadedState.messages;
          final updatedMessages = [message, ...originalMessages];
          emit(
            MessagesLoaded(
              messages: updatedMessages,
              conversationId: event.conversationId,
              isSending: false,
            ),
          );
        } else {
          // If we don't have messages loaded, emit MessageSent and reload
          emit(MessageSent(message: message));
          add(LoadMessagesEvent(conversationId: event.conversationId));
        }

        // The conversation table has been updated with last_message and last_message_time
        // The real-time subscription will pick this up and reload conversations automatically
        // Add a small delay fallback reload to ensure it updates even if real-time is slow
        if (!isClosed) {
          Future.delayed(const Duration(milliseconds: 500), () {
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
      // Success - the unread count will be updated via real-time subscription
      // Force reload conversations to update unread count immediately
      if (!isClosed) {
        add(const LoadConversationsEvent(forceRefresh: true));
      }
    } catch (e) {
      // Log error but don't emit error state - this is a background operation
      debugPrint('Failed to mark messages as read: $e');
    }
  }

  Future<void> _onStartListeningToMessages(
    StartListeningToMessagesEvent event,
    Emitter<MessageState> emit,
  ) async {
    // Cancel existing subscription
    await _messageSubscription?.cancel();

    // Subscribe to new messages in this conversation
    // Note: Supabase real-time requires proper setup
    // For now, we rely on manual refresh after sending
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
      emit(const MessageError(
        message: 'Failed to send message after multiple attempts',
      ));
      return;
    }

    // Exponential backoff: 2^retryCount seconds (1s, 2s, 4s)
    if (retryCount > 0) {
      final delaySeconds = (1 << retryCount); // 2^retryCount
      debugPrint('Retrying message after ${delaySeconds}s delay (attempt ${retryCount + 1}/$maxRetries)');
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
