import 'dart:io';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mwanachuo/core/services/logger_service.dart';
import 'package:mwanachuo/core/widgets/in_app_notification_banner.dart';
import 'package:mwanachuo/core/services/notification_grouping_service.dart';
import 'package:mwanachuo/config/supabase_config.dart';
import 'package:mwanachuo/features/shared/notifications/data/models/notification_preferences_model.dart';
import 'package:mwanachuo/core/services/notification_analytics_service.dart';
import 'package:mwanachuo/core/services/notification_actions_service.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/constants/database_constants.dart';

class OneSignalConfig {
  // OneSignal App ID
  // Get this from OneSignal dashboard: Settings > Keys & IDs > App ID
  static const String oneSignalAppId = 'b108e16e-0426-4b7f-bd78-20f04056bade';

  static bool _isInitialized = false;

  /// Global navigator key for showing in-app notifications
  static GlobalKey<NavigatorState>? navigatorKey;

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
      // Handle foreground notifications
      // IMPORTANT: We allow system notifications to show even in foreground (like WhatsApp)
      // This ensures users always see notifications with sound and banner
      OneSignal.Notifications.addForegroundWillDisplayListener((event) async {
        try {
          LoggerService.debug(
            'Foreground notification received: ${event.notification.notificationId}',
          );

          // Check user preferences before showing notification
          final shouldShow = await _shouldShowNotification(event.notification);
          if (!shouldShow) {
            LoggerService.debug(
              'Notification suppressed by user preferences: ${event.notification.notificationId}',
            );
            event.preventDefault();
            return;
          }

          // Track notification delivery
          _trackNotificationDelivery(event.notification);

          // Create/update notification group if grouping is enabled
          await _handleNotificationGrouping(event.notification);

          // DON'T prevent default - allow system notification to show with sound and banner
          // This matches WhatsApp/Instagram behavior where notifications always show
          // even when app is in foreground
          
          // Also show custom in-app banner for better UX (both will show)
          try {
            _showInAppBanner(event.notification);
          } catch (e) {
            LoggerService.warning('Failed to show in-app banner, system notification will still show', e);
          }
          
          // Let the system notification display normally (with sound and banner)
          // This ensures users always get alerted, just like WhatsApp
        } catch (e) {
          LoggerService.error('Error handling foreground notification', e);
          // Fallback: display notification normally (don't prevent)
        }
      });

      // Handle notification tapped/opened
      // NOTE: This works for BOTH foreground and background notifications
      // When app is closed/background, OneSignal automatically shows system notifications
      // and this listener is called when user taps the notification
      OneSignal.Notifications.addClickListener((event) {
        try {
          LoggerService.debug(
            'Notification tapped (app may have been closed/background): ${event.notification.notificationId}',
          );
          final notification = event.notification;
          final additionalData = notification.additionalData;
          final actionId = event.result.actionId;

          // Track notification tap
          _trackNotificationTap(notification, additionalData);

          if (actionId != null && actionId.isNotEmpty) {
            // Handle specific action button clicks
            _handleNotificationAction(actionId, notification, additionalData);
          } else if (additionalData != null) {
            final notificationType = additionalData['type'] as String?;
            final actionUrl = additionalData['actionUrl'] as String?;

            // Handle navigation based on notification type
            _handleNotificationTap(notificationType, actionUrl, additionalData);
          } else {
            // Fallback: try to parse from notification title/body
            LoggerService.debug(
              'No additional data in notification, using default handling',
            );
          }
        } catch (e) {
          LoggerService.error('Error handling notification tap', e);
        }
      });

      // Monitor notification permission changes
      OneSignal.Notifications.addPermissionObserver((hasPrompted) {
        LoggerService.info(
          'Notification permission has been prompted: $hasPrompted',
        );
      });
    } catch (e) {
      LoggerService.warning(
        'Failed to setup OneSignal notification handlers: $e',
      );
    }
  }

  /// Show custom in-app notification banner for foreground notifications
  static void _showInAppBanner(OSNotification notification) {
    final context = navigatorKey?.currentContext;
    if (context == null) {
      LoggerService.warning(
        'Cannot show in-app banner: Navigator context not available',
      );
      // Fallback: show system notification
      notification.display();
      return;
    }

    final title = notification.title ?? 'Notification';
    final body = notification.body ?? '';
    final imageUrl = notification.bigPicture;
    final additionalData = notification.additionalData;

    // Determine icon and color based on notification type
    // Use brand colors for all notifications
    IconData icon = Icons.notifications;
    Color? iconColor = kPrimaryColor; // Default to brand color

    if (additionalData != null) {
      final type = additionalData['type'] as String?;
      switch (type) {
        case 'message':
        case 'chat':
          icon = Icons.chat_bubble;
          iconColor = kPrimaryColor; // Brand green for messages
          break;
        case 'review':
          icon = Icons.star;
          iconColor = Colors.amber;
          break;
        case 'order':
          icon = Icons.shopping_bag;
          iconColor = kPrimaryColor; // Brand green
          break;
        case 'promotion':
          icon = Icons.local_offer;
          iconColor = kPrimaryColor; // Brand green
          break;
        default:
          icon = Icons.notifications;
          iconColor = kPrimaryColor; // Brand green for all
      }
    }

    InAppNotificationBanner.show(
      context,
      title: title,
      body: body,
      imageUrl: imageUrl,
      icon: icon,
      iconColor: iconColor,
      onTap: () {
        // Track notification tap
        _trackNotificationTap(notification, additionalData);

        // Handle tap - navigate based on notification data
        if (additionalData != null) {
          final notificationType = additionalData['type'] as String?;
          final actionUrl = additionalData['actionUrl'] as String?;
          _handleNotificationTap(notificationType, actionUrl, additionalData);
        }
      },
    );
  }

  /// Track notification delivery for analytics
  static void _trackNotificationDelivery(OSNotification notification) {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return;

      final notificationId = notification.notificationId;
      final type = notification.additionalData?['type'] as String? ?? 'unknown';

      NotificationAnalyticsService().trackNotificationDelivery(
        notificationId: notificationId,
        userId: userId,
        type: type,
        metadata: notification.additionalData,
      );
    } catch (e) {
      LoggerService.debug('Failed to track notification delivery: $e');
    }
  }

  /// Track notification tap for analytics
  static void _trackNotificationTap(
    OSNotification notification,
    Map<String, dynamic>? additionalData,
  ) {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return;

      final notificationId = notification.notificationId;
      final type = additionalData?['type'] as String? ?? 'unknown';
      final targetScreen = additionalData?['actionUrl'] as String?;

      NotificationAnalyticsService().trackNotificationTap(
        notificationId: notificationId,
        userId: userId,
        type: type,
        targetScreen: targetScreen,
        metadata: additionalData,
      );
    } catch (e) {
      LoggerService.debug('Failed to track notification tap: $e');
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

    LoggerService.debug(
      'Notification tap handled: type=$type, actionUrl=$actionUrl',
    );
  }

  /// Handle notification action button clicks
  static Future<void> _handleNotificationAction(
    String actionId,
    OSNotification notification,
    Map<String, dynamic>? additionalData,
  ) async {
    LoggerService.debug('Handling notification action: $actionId');

    // Track conversion for specific actions
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId != null) {
      final notificationId = notification.notificationId;
      final type = additionalData?['type'] as String? ?? 'unknown';

      NotificationAnalyticsService().trackNotificationConversion(
        notificationId: notificationId,
        userId: userId,
        type: type,
        conversionAction: actionId,
        metadata: additionalData,
      );
    }

    switch (actionId) {
      case 'reply':
      case 'chat_reply':
        // Handle reply action - navigate to chat screen
        // The conversationId can be in data.conversationId or directly in additionalData
        if (additionalData != null) {
          final conversationId = additionalData['conversationId'] as String? ??
              additionalData['data']?['conversationId'] as String?;
          if (conversationId != null) {
            final context = navigatorKey?.currentContext;
            if (context != null) {
              Navigator.of(
                context,
              ).pushNamed('/chat', arguments: conversationId);
            }
          } else {
            // Fallback: try to navigate to general chat if conversation ID not found
            LoggerService.warning(
              'Reply action triggered but no conversationId found',
            );
            final context = navigatorKey?.currentContext;
            if (context != null) {
              Navigator.of(context).pushNamed('/chat');
            }
          }
        }
        break;

      case 'view':
      case 'view_details':
        // Navigate to details (same as tapping notification)
        if (additionalData != null) {
          final type = additionalData['type'] as String?;
          final actionUrl = additionalData['actionUrl'] as String?;
          _handleNotificationTap(type, actionUrl, additionalData);
        }
        break;

      case 'dismiss':
      case 'close':
        // Just dismiss (already handled by OS)
        break;

      case 'mark_read':
        // Mark notification as read in database
        await _markNotificationAsRead(notification, additionalData);
        break;

      default:
        LoggerService.warning('Unknown notification action: $actionId');
    }
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

      // First, logout to clear any existing user association
      // This prevents "alias claimed by another user" errors when
      // a new user logs in on a device previously used by another user
      try {
        await OneSignal.logout();
        LoggerService.debug('OneSignal logged out previous user');
      } catch (e) {
        // Ignore logout errors - might not have a previous user
        LoggerService.debug('OneSignal logout (may not have previous user): $e');
      }

      // Small delay to ensure logout completes
      await Future.delayed(const Duration(milliseconds: 100));

      // Now login with the new user ID
      await OneSignal.login(userId);
      LoggerService.debug('OneSignal user ID set: $userId');
    } catch (e) {
      // Handle MissingPluginException gracefully
      if (e.toString().contains('MissingPluginException') ||
          e.toString().contains('MissingPlugin')) {
        LoggerService.debug('OneSignal plugin not available on this platform');
        return;
      }

      // Handle alias conflict error gracefully
      if (e.toString().contains('user-2') ||
          e.toString().contains('Aliases claimed') ||
          e.toString().contains('409')) {
        LoggerService.warning(
          'OneSignal user ID conflict (user may have logged in on another device): $userId. '
          'This is usually harmless and notifications will still work.',
        );
        // Try to continue - the device token is still registered in our database
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
  static Future<void> sendTestNotification({
    String? title,
    String? message,
  }) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        LoggerService.warning('Cannot send test notification: User not authenticated');
        return;
      }

      final playerId = await getPlayerId();
      if (playerId == null) {
        LoggerService.warning('Cannot send test notification: No player ID');
        return;
      }

      LoggerService.debug(
        'Sending test notification to player: $playerId',
      );

      // Send test notification using the database function
      await SupabaseConfig.client.rpc(
        'send_immediate_push_notification',
        params: {
          'p_user_id': userId,
          'p_title': title ?? 'Test Notification',
          'p_message': message ?? 'This is a test push notification! 🎉',
          'p_type': 'system',
          'p_action_url': null,
          'p_metadata': {
            'test': true,
            'player_id': playerId,
            'timestamp': DateTime.now().toIso8601String(),
          },
        },
      );

      LoggerService.info('Test notification sent successfully!');
    } catch (e, stackTrace) {
      LoggerService.error('Failed to send test notification', e, stackTrace);
      rethrow;
    }
  }

  /// Check if notification should be shown based on user preferences
  static Future<bool> _shouldShowNotification(
    OSNotification notification,
  ) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return true; // Default: show if not logged in

      // Get user preferences
      final prefsResponse = await SupabaseConfig.client
          .from('notification_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (prefsResponse == null) {
        // No preferences set, default to showing
        return true;
      }

      final preferences = NotificationPreferencesModel.fromJson(prefsResponse);

      // Extract notification category from additional data
      final additionalData = notification.additionalData;
      final category = additionalData?['type'] as String? ?? 'unknown';

      // Check if notification should be delivered
      return preferences.shouldDeliverNotification(category);
    } catch (e) {
      LoggerService.debug('Error checking notification preferences: $e');
      // Default: show notification on error
      return true;
    }
  }

  /// Handle notification grouping
  static Future<void> _handleNotificationGrouping(
    OSNotification notification,
  ) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return;

      // Check if grouping is enabled
      final prefsResponse = await SupabaseConfig.client
          .from('notification_preferences')
          .select('group_notifications')
          .eq('user_id', userId)
          .maybeSingle();

      final groupNotifications =
          prefsResponse?['group_notifications'] as bool? ?? true;
      if (!groupNotifications) return;

      final additionalData = notification.additionalData;
      final category = additionalData?['type'] as String? ?? 'unknown';
      final notificationId = notification.notificationId;

      // Generate group key
      final groupKey = NotificationGroupingService.generateGroupKey(
        category: category,
        additionalData: additionalData ?? {},
      );

      // Create or update group
      final title = notification.title ?? 'Notification';
      final summary = notification.body;

      await NotificationGroupingService().createOrUpdateGroup(
        userId: userId,
        groupKey: groupKey,
        category: category,
        title: title,
        summary: summary,
        notificationId: notificationId,
      );

      LoggerService.debug(
        'Notification grouped: $notificationId in group $groupKey',
      );
    } catch (e) {
      LoggerService.debug('Error handling notification grouping: $e');
      // Don't throw - grouping failure shouldn't prevent notification display
    }
  }

  /// Mark a notification as read in the database
  static Future<void> _markNotificationAsRead(
    OSNotification notification,
    Map<String, dynamic>? additionalData,
  ) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        LoggerService.debug('Cannot mark as read: User not authenticated');
        return;
      }

      final oneSignalNotificationId = notification.notificationId;

      // Track the action first
      await NotificationActionsService().trackMarkAsRead(
        notificationId: oneSignalNotificationId,
        metadata: {
          ...?additionalData,
          'onesignal_notification_id': oneSignalNotificationId,
        },
      );

      // Try to find the database notification by searching for the OneSignal ID in metadata
      // The OneSignal notification ID might be stored in the notification's data/metadata field
      try {
        // First, try to find by searching the data JSONB field for the OneSignal notification ID
        // Check multiple possible field names where the OneSignal ID might be stored
        List<String> notificationIds = [];

        // Try searching in data->onesignal_notification_id
        try {
          final response1 = await SupabaseConfig.client
              .from(DatabaseConstants.notificationsTable)
              .select('id')
              .eq('user_id', userId)
              .eq('is_read', false)
              .eq('data->onesignal_notification_id', oneSignalNotificationId);
          notificationIds.addAll(response1.map((n) => n['id'] as String));
        } catch (_) {
          // Field might not exist or query failed, continue
        }

        // Try searching in data->notification_id
        if (notificationIds.isEmpty) {
          try {
            final response2 = await SupabaseConfig.client
                .from(DatabaseConstants.notificationsTable)
                .select('id')
                .eq('user_id', userId)
                .eq('is_read', false)
                .eq('data->notification_id', oneSignalNotificationId);
            notificationIds.addAll(response2.map((n) => n['id'] as String));
          } catch (_) {
            // Field might not exist or query failed, continue
          }
        }

        if (notificationIds.isNotEmpty) {
          // Found matching notification(s), mark them as read
          await SupabaseConfig.client
              .from(DatabaseConstants.notificationsTable)
              .update({
                'is_read': true,
                'read_at': DateTime.now().toIso8601String(),
              })
              .inFilter('id', notificationIds)
              .eq('user_id', userId);

          LoggerService.debug(
            'Marked ${notificationIds.length} notification(s) as read: $notificationIds',
          );
        } else {
          // If not found by metadata, try to find by matching title/message
          // This is a fallback for cases where the OneSignal notification
          // corresponds to a database notification but the ID isn't stored in metadata
          final title = notification.title;
          final message = notification.body;

          if (title != null || message != null) {
            var query = SupabaseConfig.client
                .from(DatabaseConstants.notificationsTable)
                .select('id')
                .eq('user_id', userId)
                .eq('is_read', false);

            if (title != null) {
              query = query.eq('title', title);
            }
            if (message != null) {
              query = query.eq('message', message);
            }

            final matchingNotifications = await query.limit(1);

            if (matchingNotifications.isNotEmpty) {
              final notificationId =
                  matchingNotifications.first['id'] as String;
              await SupabaseConfig.client
                  .from(DatabaseConstants.notificationsTable)
                  .update({
                    'is_read': true,
                    'read_at': DateTime.now().toIso8601String(),
                  })
                  .eq('id', notificationId)
                  .eq('user_id', userId);

              LoggerService.debug(
                'Marked notification as read by title/message match: $notificationId',
              );
            } else {
              LoggerService.debug(
                'No matching database notification found for OneSignal notification: $oneSignalNotificationId',
              );
            }
          } else {
            LoggerService.debug(
              'No matching database notification found for OneSignal notification: $oneSignalNotificationId',
            );
          }
        }
      } catch (e) {
        LoggerService.debug('Error finding/marking database notification: $e');
        // Continue - action was already tracked
      }
    } catch (e, stackTrace) {
      LoggerService.error('Failed to mark notification as read', e, stackTrace);
    }
  }
}
