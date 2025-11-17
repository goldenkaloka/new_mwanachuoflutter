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
    on<StartListeningToMessagesEvent>(_onStartListeningToMessages);
    on<StartListeningToConversationsEvent>(_onStartListeningToConversations);
    on<StopListeningEvent>(_onStopListening);
  }

  Future<void> _onLoadConversations(
    LoadConversationsEvent event,
    Emitter<MessageState> emit,
  ) async {
    debugPrint('🔄 [LOAD CONVERSATIONS] Event received');
    debugPrint('   Force refresh: ${event.forceRefresh}');

    // If force refresh, clear cache first
    if (event.forceRefresh) {
      debugPrint('🗑️ [LOAD CONVERSATIONS] Clearing cache for force refresh');
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
      (failure) {
        debugPrint('❌ [LOAD CONVERSATIONS] Error: ${failure.message}');
        emit(MessageError(message: failure.message));
      },
      (conversations) {
        debugPrint(
          '✅ [LOAD CONVERSATIONS] Loaded ${conversations.length} conversations',
        );
        for (var conv in conversations) {
          debugPrint(
            '   - ${conv.otherUserName}: "${conv.lastMessage ?? 'NULL'}" at ${conv.lastMessageTime}',
          );
        }
        emit(ConversationsLoaded(conversations: conversations));
      },
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
        limit: event.limit,
        offset: event.offset,
      ),
    );

    result.fold(
      (failure) => emit(MessageError(message: failure.message)),
      (messages) => emit(
        MessagesLoaded(
          messages: messages,
          conversationId: event.conversationId,
        ),
      ),
    );
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<MessageState> emit,
  ) async {
    // Capture current state before async operation
    final currentState = state;
    final hadMessagesLoaded =
        currentState is MessagesLoaded &&
        currentState.conversationId == event.conversationId;

    // Show sending state
    if (hadMessagesLoaded) {
      // Optimistically show sending state while keeping current messages
      emit((currentState as MessagesLoaded).copyWith(isSending: true));
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
        if (hadMessagesLoaded) {
          emit((currentState as MessagesLoaded).copyWith(isSending: false));
        } else {
          emit(MessageError(message: failure.message));
        }
      },
      (message) {
        // Successfully sent - optimistically add message to current state
        if (hadMessagesLoaded) {
          // Use the captured state (before isSending was set)
          // Messages are ordered newest first (descending), so add new message at the beginning
          final originalMessages = (currentState as MessagesLoaded).messages;
          final updatedMessages = [message, ...originalMessages];
          emit(
            MessagesLoaded(
              messages: updatedMessages,
              conversationId: event.conversationId,
              isSending: false,
            ),
          );
          debugPrint(
            '✅ Message added optimistically. Total: ${updatedMessages.length}',
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
          debugPrint('🔄 [SEND MESSAGE] Scheduling conversation reload');
          debugPrint('   Message sent: "${message.content}"');
          debugPrint('   Conversation ID: ${event.conversationId}');

          // Use Future.microtask to delay the reload slightly, allowing DB update to be visible
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!isClosed) {
              debugPrint(
                '🔄 [SEND MESSAGE] Executing fallback reload after 500ms (FORCE REFRESH)',
              );
              add(const LoadConversationsEvent(forceRefresh: true));
            } else {
              debugPrint('⚠️ [SEND MESSAGE] Bloc closed, skipping reload');
            }
          });
        } else {
          debugPrint(
            '⚠️ [SEND MESSAGE] Bloc is closed, cannot reload conversations',
          );
        }
      },
    );
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
    debugPrint('🗑️ Cleared conversations cache');

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
        debugPrint('✅ Initial conversations loaded: ${conversations.length}');
      },
    );

    // Now subscribe to real-time updates
    // Note: We cannot use emit() in the stream callback since the handler
    // has already completed. Instead, we dispatch a new event.
    debugPrint('🔴 [REAL-TIME] Starting real-time subscription...');
    _conversationSubscription = messageRepository.subscribeToConversations().listen(
      (updatedConversation) async {
        debugPrint('🔔 [REAL-TIME] Update received!');
        debugPrint('   Conversation ID: ${updatedConversation.id}');
        debugPrint('   Other user: ${updatedConversation.otherUserName}');
        debugPrint(
          '   Last message: "${updatedConversation.lastMessage ?? 'NULL'}"',
        );
        debugPrint(
          '   Last message time: ${updatedConversation.lastMessageTime}',
        );

        // Clear cache to force fresh fetch
        await sharedPreferences.remove(StorageConstants.conversationsCacheKey);
        await sharedPreferences.remove(
          '${StorageConstants.conversationsCacheKey}_timestamp',
        );
        debugPrint('🗑️ [REAL-TIME] Cache cleared');

        // Dispatch a new event to reload conversations
        // This ensures emit() is called in a proper event handler context
        if (!isClosed) {
          debugPrint(
            '🔄 [REAL-TIME] Dispatching LoadConversationsEvent (FORCE REFRESH)',
          );
          add(const LoadConversationsEvent(forceRefresh: true));
        } else {
          debugPrint('⚠️ [REAL-TIME] Bloc closed, cannot reload');
        }
      },
      onError: (error) {
        debugPrint('❌ [REAL-TIME] Error: $error');
      },
      onDone: () {
        debugPrint('🔴 [REAL-TIME] Subscription closed');
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

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _conversationSubscription?.cancel();
    return super.close();
  }
}
