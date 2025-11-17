import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/notifications/domain/entities/notification_entity.dart';
import 'package:mwanachuo/features/shared/notifications/domain/repositories/notification_repository.dart';

/// Use case for subscribing to real-time notifications
class SubscribeToNotifications implements StreamUseCase<NotificationEntity, NoParams> {
  final NotificationRepository repository;

  SubscribeToNotifications(this.repository);

  @override
  Stream<NotificationEntity> call(NoParams params) {
    return repository.subscribeToNotifications();
  }
}

