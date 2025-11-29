import 'dart:io';
import 'package:mwanachuo/config/onesignal_config.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/core/services/logger_service.dart';
import 'package:mwanachuo/features/shared/notifications/domain/usecases/register_device_token.dart';
import 'package:mwanachuo/features/shared/notifications/domain/usecases/unregister_device_token.dart';

/// Service for managing push notifications and device tokens
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  /// Get RegisterDeviceToken use case (lazy initialization)
  RegisterDeviceToken get _registerDeviceToken => sl<RegisterDeviceToken>();

  /// Get UnregisterDeviceToken use case (lazy initialization)
  UnregisterDeviceToken get _unregisterDeviceToken =>
      sl<UnregisterDeviceToken>();

  /// Register device token for the current user with retry logic
  Future<void> registerDeviceTokenForUser(
    String userId, {
    int maxRetries = 3,
    int initialDelayMs = 1000,
  }) async {
    int attempt = 0;
    int delay = initialDelayMs;

    while (attempt < maxRetries) {
      try {
        // Get OneSignal player ID
        final playerId = await OneSignalConfig.getPlayerId();
        if (playerId == null) {
          LoggerService.warning(
            'Cannot register device token: No OneSignal player ID',
          );
          return;
        }

        // Determine platform
        final platform = Platform.isIOS ? 'ios' : 'android';

        // Set OneSignal user ID
        await OneSignalConfig.setUserId(userId);

        // Register device token in database
        final result = await _registerDeviceToken.call(
          playerId: playerId,
          platform: platform,
        );

        final isSuccess = result.fold(
          (failure) {
            LoggerService.error(
              'Failed to register device token (attempt ${attempt + 1}/$maxRetries)',
              failure.message,
            );
            return false;
          },
          (_) {
            LoggerService.info(
              'Device token registered successfully: $playerId',
            );
            return true;
          },
        );

        // Success - exit retry loop
        if (isSuccess) {
          return;
        }

        // Failure - retry with exponential backoff
        attempt++;
        if (attempt < maxRetries) {
          LoggerService.debug('Retrying token registration in ${delay}ms...');
          await Future.delayed(Duration(milliseconds: delay));
          delay *= 2; // Exponential backoff
        }
      } catch (e, stackTrace) {
        LoggerService.error(
          'Error registering device token (attempt ${attempt + 1}/$maxRetries)',
          e,
          stackTrace,
        );

        attempt++;
        if (attempt < maxRetries) {
          LoggerService.debug('Retrying token registration in ${delay}ms...');
          await Future.delayed(Duration(milliseconds: delay));
          delay *= 2; // Exponential backoff
        }
      }
    }

    // All retries exhausted
    LoggerService.warning(
      'Failed to register device token after $maxRetries attempts. '
      'Will retry on next app launch.',
    );
  }

  /// Unregister device token (on logout)
  Future<void> unregisterDeviceToken() async {
    try {
      // Get OneSignal player ID
      final playerId = await OneSignalConfig.getPlayerId();
      if (playerId == null) {
        LoggerService.warning(
          'Cannot unregister device token: No OneSignal player ID',
        );
        return;
      }

      // Logout from OneSignal
      await OneSignalConfig.logout();

      // Unregister device token from database
      final result = await _unregisterDeviceToken.call(playerId);

      result.fold(
        (failure) {
          LoggerService.error(
            'Failed to unregister device token',
            failure.message,
          );
        },
        (_) {
          LoggerService.info('Device token unregistered successfully');
        },
      );
    } catch (e, stackTrace) {
      LoggerService.error('Error unregistering device token', e, stackTrace);
    }
  }
}
