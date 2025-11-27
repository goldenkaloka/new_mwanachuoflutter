import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/shared/notifications/domain/repositories/notification_repository.dart';

/// Use case for registering a device token (OneSignal player ID)
class RegisterDeviceToken {
  final NotificationRepository repository;

  RegisterDeviceToken(this.repository);

  Future<Either<Failure, void>> call({
    required String playerId,
    required String platform,
  }) async {
    return await repository.registerDeviceToken(
      playerId: playerId,
      platform: platform,
    );
  }
}

