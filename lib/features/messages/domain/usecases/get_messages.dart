import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/messages/domain/entities/message_entity.dart';
import 'package:mwanachuo/features/messages/domain/repositories/message_repository.dart';

class GetMessages implements UseCase<List<MessageEntity>, GetMessagesParams> {
  final MessageRepository repository;

  GetMessages(this.repository);

  @override
  Future<Either<Failure, List<MessageEntity>>> call(
    GetMessagesParams params,
  ) async {
    return await repository.getMessages(
      conversationId: params.conversationId,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class GetMessagesParams extends Equatable {
  final String conversationId;
  final int? limit;
  final int? offset;

  const GetMessagesParams({
    required this.conversationId,
    this.limit,
    this.offset,
  });

  @override
  List<Object?> get props => [conversationId, limit, offset];
}

