import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/shared/notifications/domain/entities/notification_preferences_entity.dart';
import 'package:mwanachuo/features/shared/notifications/domain/repositories/notification_repository.dart';

/// Use case for getting notification preferences
class GetNotificationPreferences {
  final NotificationRepository repository;

  GetNotificationPreferences(this.repository);

  Future<Either<Failure, NotificationPreferencesEntity>> call() async {
    return await repository.getNotificationPreferences();
  }
}

