import 'package:mwanachuo/config/supabase_config.dart';
import 'package:mwanachuo/core/services/logger_service.dart';
import 'package:mwanachuo/features/shared/notifications/domain/entities/notification_action_entity.dart';

/// Service for tracking and managing notification actions
class NotificationActionsService {
  static final NotificationActionsService _instance =
      NotificationActionsService._internal();
  factory NotificationActionsService() => _instance;
  NotificationActionsService._internal();

  /// Track a user action on a notification
  Future<void> trackAction({
    required String notificationId,
    required String actionType, // 'reply', 'view', 'dismiss', 'snooze', 'mark_read'
    String? actionLabel,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        LoggerService.warning('Cannot track action: User not authenticated');
        return;
      }

      await SupabaseConfig.client
          .from('notification_actions')
          .insert({
            'notification_id': notificationId,
            'user_id': userId,
            'action_type': actionType,
            'action_label': actionLabel,
            'action_url': actionUrl,
            'metadata': metadata,
          });

      LoggerService.debug(
        'Notification action tracked: $actionType for notification $notificationId',
      );
    } catch (e, stackTrace) {
      LoggerService.error('Failed to track notification action', e, stackTrace);
    }
  }

  /// Track notification reply action
  Future<void> trackReply({
    required String notificationId,
    String? conversationId,
    Map<String, dynamic>? metadata,
  }) async {
    await trackAction(
      notificationId: notificationId,
      actionType: 'reply',
      actionLabel: 'Reply',
      actionUrl: conversationId != null ? '/messages/$conversationId' : null,
      metadata: {
        ...?metadata,
        'conversation_id': conversationId,
      },
    );
  }

  /// Track notification view action
  Future<void> trackView({
    required String notificationId,
    String? targetScreen,
    Map<String, dynamic>? metadata,
  }) async {
    await trackAction(
      notificationId: notificationId,
      actionType: 'view',
      actionLabel: 'View',
      actionUrl: targetScreen,
      metadata: metadata,
    );
  }

  /// Track notification dismiss action
  Future<void> trackDismiss({
    required String notificationId,
    bool isAutomatic = false,
    Map<String, dynamic>? metadata,
  }) async {
    await trackAction(
      notificationId: notificationId,
      actionType: 'dismiss',
      actionLabel: 'Dismiss',
      metadata: {
        ...?metadata,
        'is_automatic': isAutomatic,
      },
    );
  }

  /// Track notification snooze action
  Future<void> trackSnooze({
    required String notificationId,
    Duration? snoozeDuration,
    Map<String, dynamic>? metadata,
  }) async {
    await trackAction(
      notificationId: notificationId,
      actionType: 'snooze',
      actionLabel: 'Snooze',
      metadata: {
        ...?metadata,
        'snooze_duration_minutes': snoozeDuration?.inMinutes,
      },
    );
  }

  /// Track notification mark as read action
  Future<void> trackMarkAsRead({
    required String notificationId,
    Map<String, dynamic>? metadata,
  }) async {
    await trackAction(
      notificationId: notificationId,
      actionType: 'mark_read',
      actionLabel: 'Mark as Read',
      metadata: metadata,
    );
  }

  /// Get actions for a specific notification
  Future<List<NotificationActionEntity>> getNotificationActions(
    String notificationId,
  ) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        LoggerService.warning('Cannot get actions: User not authenticated');
        return [];
      }

      final data = await SupabaseConfig.client
          .from('notification_actions')
          .select()
          .eq('notification_id', notificationId)
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return data.map((json) {
        return NotificationActionEntity(
          id: json['id'] as String,
          notificationId: json['notification_id'] as String,
          userId: json['user_id'] as String,
          actionType: json['action_type'] as String,
          actionLabel: json['action_label'] as String?,
          actionUrl: json['action_url'] as String?,
          metadata: json['metadata'] as Map<String, dynamic>?,
          createdAt: DateTime.parse(json['created_at'] as String),
        );
      }).toList();
    } catch (e, stackTrace) {
      LoggerService.error('Failed to get notification actions', e, stackTrace);
      return [];
    }
  }

  /// Get action statistics for analytics
  Future<Map<String, dynamic>> getActionStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        LoggerService.warning('Cannot get statistics: User not authenticated');
        return {};
      }

      var query = SupabaseConfig.client
          .from('notification_actions')
          .select()
          .eq('user_id', userId);

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final data = await query;

      // Calculate statistics
      final totalActions = data.length;
      final actionsByType = <String, int>{};
      final actionsByNotification = <String, int>{};

      for (final action in data) {
        final type = action['action_type'] as String;
        final notificationId = action['notification_id'] as String;

        actionsByType[type] = (actionsByType[type] ?? 0) + 1;
        actionsByNotification[notificationId] =
            (actionsByNotification[notificationId] ?? 0) + 1;
      }

      return {
        'total_actions': totalActions,
        'actions_by_type': actionsByType,
        'actions_by_notification': actionsByNotification,
        'unique_notifications': actionsByNotification.keys.length,
      };
    } catch (e, stackTrace) {
      LoggerService.error('Failed to get action statistics', e, stackTrace);
      return {};
    }
  }
}

