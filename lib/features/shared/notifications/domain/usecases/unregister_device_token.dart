import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/shared/notifications/domain/repositories/notification_repository.dart';

/// Use case for unregistering a device token
class UnregisterDeviceToken {
  final NotificationRepository repository;

  UnregisterDeviceToken(this.repository);

  Future<Either<Failure, void>> call(String playerId) async {
    return await repository.unregisterDeviceToken(playerId);
  }
}

