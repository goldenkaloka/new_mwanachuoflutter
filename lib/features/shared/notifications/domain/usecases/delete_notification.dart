import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/notifications/domain/repositories/notification_repository.dart';

/// Use case for deleting a notification
class DeleteNotification implements UseCase<void, DeleteNotificationParams> {
  final NotificationRepository repository;

  DeleteNotification(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteNotificationParams params) async {
    return await repository.deleteNotification(params.notificationId);
  }
}

class DeleteNotificationParams extends Equatable {
  final String notificationId;

  const DeleteNotificationParams({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

