import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/messages/domain/entities/conversation_entity.dart';
import 'package:mwanachuo/features/messages/domain/repositories/message_repository.dart';

class GetOrCreateConversation
    implements UseCase<ConversationEntity, GetOrCreateConversationParams> {
  final MessageRepository repository;

  GetOrCreateConversation(this.repository);

  @override
  Future<Either<Failure, ConversationEntity>> call(
    GetOrCreateConversationParams params,
  ) async {
    return await repository.getOrCreateConversation(
      otherUserId: params.otherUserId,
    );
  }
}

class GetOrCreateConversationParams extends Equatable {
  final String otherUserId;

  const GetOrCreateConversationParams({required this.otherUserId});

  @override
  List<Object?> get props => [otherUserId];
}

