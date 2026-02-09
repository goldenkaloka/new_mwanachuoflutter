import 'package:equatable/equatable.dart';

enum MessageType {
  text,
  productShare,
  offer,
  dealConfirmed,
  unknown;

  String get toDbString {
    switch (this) {
      case MessageType.productShare:
        return 'product_share';
      case MessageType.offer:
        return 'offer';
      case MessageType.dealConfirmed:
        return 'deal_confirmed';
      case MessageType.text:
      case MessageType.unknown:
        return 'text';
    }
  }

  static MessageType fromDbString(String? type) {
    switch (type) {
      case 'product_share':
        return MessageType.productShare;
      case 'offer':
        return MessageType.offer;
      case 'deal_confirmed':
        return MessageType.dealConfirmed;
      case 'text':
      default:
        return MessageType.text;
    }
  }
}

class Message extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final MessageType type;
  final Map<String, dynamic> metadata;
  final String? replyToId;
  final DateTime createdAt;
  final bool isRead;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.type,
    this.metadata = const {},
    this.replyToId,
    required this.createdAt,
    this.isRead = false,
  });

  @override
  List<Object?> get props => [
    id,
    conversationId,
    senderId,
    content,
    type,
    metadata,
    replyToId,
    createdAt,
    isRead,
  ];
}
