import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/messages/domain/repositories/message_repository.dart';

class DeleteConversation implements UseCase<void, DeleteConversationParams> {
  final MessageRepository repository;

  DeleteConversation(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteConversationParams params) async {
    return await repository.deleteConversation(params.conversationId);
  }
}

class DeleteConversationParams extends Equatable {
  final String conversationId;

  const DeleteConversationParams({
    required this.conversationId,
  });

  @override
  List<Object?> get props => [conversationId];
}

