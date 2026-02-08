import 'package:mwanachuo/features/messages/domain/entities/conversation.dart';
import 'package:mwanachuo/features/messages/domain/entities/message.dart';

abstract class MessagesRepository {
  Future<List<Conversation>> getConversations();

  Future<List<Message>> getMessages(String conversationId);

  Stream<List<Message>> getMessagesStream(String conversationId);

  Future<Message> sendMessage({
    required String conversationId,
    required String content,
    String type = 'text',
    Map<String, dynamic> metadata = const {},
  });

  Future<Conversation> createConversation(List<String> participantIds);
  Future<void> updateMessage(String messageId, Map<String, dynamic> metadata);
  Future<void> markAsRead(String messageId);
}
