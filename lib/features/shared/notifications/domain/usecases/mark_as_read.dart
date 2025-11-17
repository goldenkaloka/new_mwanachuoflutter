import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/notifications/domain/repositories/notification_repository.dart';

/// Use case for marking a notification as read
class MarkAsRead implements UseCase<void, MarkAsReadParams> {
  final NotificationRepository repository;

  MarkAsRead(this.repository);

  @override
  Future<Either<Failure, void>> call(MarkAsReadParams params) async {
    return await repository.markAsRead(params.notificationId);
  }
}

class MarkAsReadParams extends Equatable {
  final String notificationId;

  const MarkAsReadParams({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

