import 'package:mwanachuo/features/auth/data/models/user_model.dart';
import 'package:mwanachuo/features/messages/domain/entities/conversation.dart';
import 'package:mwanachuo/features/messages/domain/entities/message.dart';

abstract class MessagesRepository {
  Future<Conversation> initiateConversation(String otherUserId);
  Future<List<Conversation>> getConversations();
  Stream<List<Conversation>> getConversationsStream();
  Future<List<Message>> getMessages(String conversationId);
  Stream<List<Message>> getMessagesStream(String conversationId);
  Future<Message> sendMessage({
    required String conversationId,
    required String content,
    MessageType type = MessageType.text,
    Map<String, dynamic> metadata = const {},
  });
  Future<void> markAsRead(String conversationId);
  Future<void> updateUserPresence(bool isOnline);
  Stream<UserModel> getUserStream(String userId);
}
