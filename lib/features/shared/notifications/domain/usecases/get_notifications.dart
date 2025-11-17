import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/notifications/domain/entities/notification_entity.dart';
import 'package:mwanachuo/features/shared/notifications/domain/repositories/notification_repository.dart';

/// Use case for getting notifications
class GetNotifications
    implements UseCase<List<NotificationEntity>, GetNotificationsParams> {
  final NotificationRepository repository;

  GetNotifications(this.repository);

  @override
  Future<Either<Failure, List<NotificationEntity>>> call(
    GetNotificationsParams params,
  ) async {
    return await repository.getNotifications(
      limit: params.limit,
      offset: params.offset,
      unreadOnly: params.unreadOnly,
    );
  }
}

class GetNotificationsParams extends Equatable {
  final int? limit;
  final int? offset;
  final bool? unreadOnly;

  const GetNotificationsParams({
    this.limit,
    this.offset,
    this.unreadOnly,
  });

  @override
  List<Object?> get props => [limit, offset, unreadOnly];
}

