import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/notifications/domain/repositories/notification_repository.dart';

/// Use case for deleting all read notifications
class DeleteAllRead implements UseCase<void, NoParams> {
  final NotificationRepository repository;

  DeleteAllRead(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.deleteAllRead();
  }
}

