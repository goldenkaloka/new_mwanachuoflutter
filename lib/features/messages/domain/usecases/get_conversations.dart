import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/messages/domain/entities/conversation_entity.dart';
import 'package:mwanachuo/features/messages/domain/repositories/message_repository.dart';

class GetConversations
    implements UseCase<List<ConversationEntity>, GetConversationsParams> {
  final MessageRepository repository;

  GetConversations(this.repository);

  @override
  Future<Either<Failure, List<ConversationEntity>>> call(
    GetConversationsParams params,
  ) async {
    return await repository.getConversations(
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class GetConversationsParams extends Equatable {
  final int? limit;
  final int? offset;

  const GetConversationsParams({this.limit, this.offset});

  @override
  List<Object?> get props => [limit, offset];
}

