import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/core/utils/content_filter.dart';
import 'package:mwanachuo/features/messages/domain/entities/message_entity.dart';
import 'package:mwanachuo/features/messages/domain/repositories/message_repository.dart';

class SendMessage implements UseCase<MessageEntity, SendMessageParams> {
  final MessageRepository repository;

  SendMessage(this.repository);

  @override
  Future<Either<Failure, MessageEntity>> call(SendMessageParams params) async {
    if (params.content.trim().isEmpty && params.imageUrl == null) {
      return Left(ValidationFailure('Message cannot be empty'));
    }

    // Validate content for restricted information (phone numbers, emails, etc.)
    final validationError = ContentFilter.validateMessage(
      params.content,
      recentMessages: params.recentMessages,
    );
    
    if (validationError != null) {
      return Left(ValidationFailure(validationError));
    }

    return await repository.sendMessage(
      conversationId: params.conversationId,
      content: params.content.trim(),
      imageUrl: params.imageUrl,
      repliedToMessageId: params.repliedToMessageId,
    );
  }
}

class SendMessageParams extends Equatable {
  final String conversationId;
  final String content;
  final String? imageUrl;
  final String? repliedToMessageId;
  final List<String> recentMessages; // For context-aware validation

  const SendMessageParams({
    required this.conversationId,
    required this.content,
    this.imageUrl,
    this.repliedToMessageId,
    this.recentMessages = const [], // Default to empty list
  });

  @override
  List<Object?> get props => [
        conversationId,
        content,
        imageUrl,
        repliedToMessageId,
        recentMessages,
      ];
}

