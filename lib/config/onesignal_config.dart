import 'dart:io';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mwanachuo/core/services/logger_service.dart';

class OneSignalConfig {
  // OneSignal App ID
  // Get this from OneSignal dashboard: Settings > Keys & IDs > App ID
  static const String oneSignalAppId = 'b108e16e-0426-4b7f-bd78-20f04056bade';

  static bool _isInitialized = false;

  /// Initialize OneSignal SDK
  static Future<void> initialize() async {
    if (_isInitialized) {
      LoggerService.debug('OneSignal already initialized');
      return;
    }

    // OneSignal only supports iOS and Android
    // Skip initialization on Windows, Linux, macOS (desktop), and Web
    if (!Platform.isAndroid && !Platform.isIOS) {
      LoggerService.info(
        'OneSignal is not supported on ${Platform.operatingSystem}. '
        'Push notifications will not be available.',
      );
      _isInitialized = false;
      return;
    }

    try {
      // Check if OneSignal App ID is configured
      if (oneSignalAppId == 'YOUR_ONESIGNAL_APP_ID') {
        LoggerService.warning(
          'OneSignal App ID not configured. Please set it in lib/config/onesignal_config.dart',
        );
        return;
      }

      // Request notification permissions
      await _requestNotificationPermissions();

      // Initialize OneSignal
      // Wrap in try-catch to handle MissingPluginException gracefully
      try {
        OneSignal.initialize(oneSignalAppId);
      } catch (e) {
        // Handle MissingPluginException - plugin not properly installed or unsupported platform
        if (e.toString().contains('MissingPluginException') ||
            e.toString().contains('MissingPlugin')) {
          LoggerService.warning(
            'OneSignal plugin not available on this platform. '
            'OneSignal only supports iOS and Android.',
          );
          _isInitialized = false;
          return;
        }
        LoggerService.warning('OneSignal initialization error: $e');
        _isInitialized = false;
        return;
      }

      // Set up notification handlers (with error handling)
      try {
        _setupNotificationHandlers();
      } catch (e) {
        if (e.toString().contains('MissingPluginException') ||
            e.toString().contains('MissingPlugin')) {
          LoggerService.warning(
            'OneSignal handlers not available - plugin not properly installed',
          );
          _isInitialized = false;
          return;
        }
        LoggerService.warning('Failed to setup OneSignal handlers: $e');
        // Continue even if handlers fail
      }

      // Request permission to send notifications (with error handling)
      // Note: OneSignal SDK 5.x handles lifecycle automatically
      // We only need to request permission explicitly
      try {
        OneSignal.Notifications.requestPermission(true);
      } catch (e) {
        if (e.toString().contains('MissingPluginException') ||
            e.toString().contains('MissingPlugin')) {
          LoggerService.warning(
            'OneSignal permission request not available on this platform',
          );
          _isInitialized = false;
          return;
        } else {
          LoggerService.warning('Failed to request OneSignal permissions: $e');
        }
        // Continue even if permission request fails
      }

      _isInitialized = true;
      LoggerService.info('OneSignal initialized successfully');
    } catch (e, stackTrace) {
      LoggerService.error('Failed to initialize OneSignal', e, stackTrace);
      // Don't throw - allow app to continue without push notifications
    }
  }

  /// Request notification permissions
  static Future<void> _requestNotificationPermissions() async {
    try {
      if (Platform.isAndroid) {
        // Android 13+ requires runtime permission
        final status = await Permission.notification.request();
        if (status.isDenied) {
          LoggerService.warning('Notification permission denied');
        }
      } else if (Platform.isIOS) {
        // iOS permissions are handled by OneSignal
        // User will be prompted automatically
      }
    } catch (e) {
      LoggerService.warning('Error requesting notification permissions: $e');
    }
  }

  /// Set up notification handlers
  static void _setupNotificationHandlers() {
    try {
      // Note: OneSignal Flutter SDK 5.x API may vary
      // Foreground notifications are handled automatically by OneSignal
      // If you need custom foreground handling, check the latest OneSignal SDK docs
      
      // Handle notification tapped/opened
      OneSignal.Notifications.addClickListener((event) {
        try {
          LoggerService.debug('Notification tapped: ${event.notification.notificationId}');
          final notification = event.notification;
          final additionalData = notification.additionalData;

          if (additionalData != null) {
            final notificationType = additionalData['type'] as String?;
            final actionUrl = additionalData['actionUrl'] as String?;

            // Handle navigation based on notification type
            _handleNotificationTap(notificationType, actionUrl, additionalData);
          } else {
            // Fallback: try to parse from notification title/body
            LoggerService.debug('No additional data in notification, using default handling');
          }
        } catch (e) {
          LoggerService.error('Error handling notification tap', e);
        }
      });
    } catch (e) {
      LoggerService.warning('Failed to setup OneSignal notification handlers: $e');
    }
  }

  /// Handle notification tap - navigate to appropriate screen
  static void _handleNotificationTap(
    String? type,
    String? actionUrl,
    Map<String, dynamic>? additionalData,
  ) {
    if (type == null) return;

    // Store notification data for navigation
    // This will be handled by the app router
    _pendingNotificationData = {
      'type': type,
      'actionUrl': actionUrl,
      'data': additionalData,
    };

    LoggerService.debug('Notification tap handled: type=$type, actionUrl=$actionUrl');
  }

  /// Get pending notification data (for navigation)
  static Map<String, dynamic>? _pendingNotificationData;
  static Map<String, dynamic>? getPendingNotificationData() {
    final data = _pendingNotificationData;
    _pendingNotificationData = null; // Clear after reading
    return data;
  }

  /// Get OneSignal player ID (device token)
  static Future<String?> getPlayerId() async {
    // Return null immediately on unsupported platforms
    if (!Platform.isAndroid && !Platform.isIOS) {
      return null;
    }

    try {
      if (!_isInitialized) {
        LoggerService.debug('OneSignal not initialized, cannot get player ID');
        return null;
      }
      final deviceState = OneSignal.User.pushSubscription.id;
      return deviceState;
    } catch (e) {
      // Handle MissingPluginException gracefully
      if (e.toString().contains('MissingPluginException') ||
          e.toString().contains('MissingPlugin')) {
        LoggerService.debug('OneSignal plugin not available on this platform');
        return null;
      }
      LoggerService.error('Failed to get OneSignal player ID', e);
      return null;
    }
  }

  /// Set user ID for OneSignal (for targeted notifications)
  static Future<void> setUserId(String userId) async {
    // Skip on unsupported platforms
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    try {
      if (!_isInitialized) {
        LoggerService.debug('OneSignal not initialized, cannot set user ID');
        return;
      }
      await OneSignal.login(userId);
      LoggerService.debug('OneSignal user ID set: $userId');
    } catch (e) {
      // Handle MissingPluginException gracefully
      if (e.toString().contains('MissingPluginException') ||
          e.toString().contains('MissingPlugin')) {
        LoggerService.debug('OneSignal plugin not available on this platform');
        return;
      }
      LoggerService.error('Failed to set OneSignal user ID', e);
    }
  }

  /// Logout user from OneSignal
  static Future<void> logout() async {
    // Skip on unsupported platforms
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    try {
      if (!_isInitialized) {
        LoggerService.debug('OneSignal not initialized, cannot logout');
        return;
      }
      await OneSignal.logout();
      LoggerService.debug('OneSignal user logged out');
    } catch (e) {
      // Handle MissingPluginException gracefully
      if (e.toString().contains('MissingPluginException') ||
          e.toString().contains('MissingPlugin')) {
        LoggerService.debug('OneSignal plugin not available on this platform');
        return;
      }
      LoggerService.error('Failed to logout OneSignal user', e);
    }
  }

  /// Send a test notification (for debugging)
  static Future<void> sendTestNotification() async {
    try {
      final playerId = await getPlayerId();
      if (playerId == null) {
        LoggerService.warning('Cannot send test notification: No player ID');
        return;
      }

      LoggerService.debug('Test notification would be sent to player: $playerId');
      // Actual sending is done via backend/OneSignal dashboard
    } catch (e) {
      LoggerService.error('Failed to send test notification', e);
    }
  }
}

