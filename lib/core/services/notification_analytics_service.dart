import 'package:mwanachuo/config/supabase_config.dart';
import 'package:mwanachuo/core/services/logger_service.dart';

/// Service for tracking push notification analytics
class NotificationAnalyticsService {
  static final NotificationAnalyticsService _instance =
      NotificationAnalyticsService._internal();
  factory NotificationAnalyticsService() => _instance;
  NotificationAnalyticsService._internal();

  /// Track notification delivery (received)
  Future<void> trackNotificationDelivery({
    required String notificationId,
    required String userId,
    required String type,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await SupabaseConfig.client.from('notification_analytics').insert({
        'notification_id': notificationId,
        'user_id': userId,
        'event_type': 'delivery',
        'notification_type': type,
        'metadata': metadata,
        'created_at': DateTime.now().toIso8601String(),
      });

      LoggerService.debug(
        'Tracked notification delivery: $notificationId (type: $type)',
      );
    } catch (e, stackTrace) {
      LoggerService.error(
        'Failed to track notification delivery',
        e,
        stackTrace,
      );
      // Don't throw - analytics failures shouldn't break app functionality
    }
  }

  /// Track notification tap/open
  Future<void> trackNotificationTap({
    required String notificationId,
    required String userId,
    required String type,
    String? targetScreen,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await SupabaseConfig.client.from('notification_analytics').insert({
        'notification_id': notificationId,
        'user_id': userId,
        'event_type': 'tap',
        'notification_type': type,
        'target_screen': targetScreen,
        'metadata': metadata,
        'created_at': DateTime.now().toIso8601String(),
      });

      LoggerService.debug(
        'Tracked notification tap: $notificationId → $targetScreen',
      );
    } catch (e, stackTrace) {
      LoggerService.error('Failed to track notification tap', e, stackTrace);
    }
  }

  /// Track notification dismissal
  Future<void> trackNotificationDismissal({
    required String notificationId,
    required String userId,
    required String type,
    bool isAutomatic = false,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await SupabaseConfig.client.from('notification_analytics').insert({
        'notification_id': notificationId,
        'user_id': userId,
        'event_type': 'dismiss',
        'notification_type': type,
        'is_automatic_dismiss': isAutomatic,
        'metadata': metadata,
        'created_at': DateTime.now().toIso8601String(),
      });

      LoggerService.debug(
        'Tracked notification dismissal: $notificationId (auto: $isAutomatic)',
      );
    } catch (e, stackTrace) {
      LoggerService.error(
        'Failed to track notification dismissal',
        e,
        stackTrace,
      );
    }
  }

  /// Track notification conversion (user took desired action)
  Future<void> trackNotificationConversion({
    required String notificationId,
    required String userId,
    required String type,
    required String conversionAction,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await SupabaseConfig.client.from('notification_analytics').insert({
        'notification_id': notificationId,
        'user_id': userId,
        'event_type': 'conversion',
        'notification_type': type,
        'conversion_action': conversionAction,
        'metadata': metadata,
        'created_at': DateTime.now().toIso8601String(),
      });

      LoggerService.debug(
        'Tracked notification conversion: $notificationId → $conversionAction',
      );
    } catch (e, stackTrace) {
      LoggerService.error(
        'Failed to track notification conversion',
        e,
        stackTrace,
      );
    }
  }

  /// Get notification analytics summary for dashboard
  Future<Map<String, dynamic>> getNotificationAnalyticsSummary({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Build query
      var query = SupabaseConfig.client
          .from('notification_analytics')
          .select('event_type, notification_type')
          .eq('user_id', userId);

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final data = await query;

      // Process data
      final summary = <String, dynamic>{
        'total_delivered': 0,
        'total_opened': 0,
        'total_dismissed': 0,
        'total_conversions': 0,
        'by_type': <String, Map<String, int>>{},
        'open_rate': 0.0,
        'conversion_rate': 0.0,
      };

      for (final record in data) {
        final eventType = record['event_type'] as String;
        final notificationType = record['notification_type'] as String;

        // Update totals
        switch (eventType) {
          case 'delivery':
            summary['total_delivered'] =
                (summary['total_delivered'] as int) + 1;
            break;
          case 'tap':
            summary['total_opened'] = (summary['total_opened'] as int) + 1;
            break;
          case 'dismiss':
            summary['total_dismissed'] =
                (summary['total_dismissed'] as int) + 1;
            break;
          case 'conversion':
            summary['total_conversions'] =
                (summary['total_conversions'] as int) + 1;
            break;
        }

        // Update by-type stats
        final byType = summary['by_type'] as Map<String, Map<String, int>>;
        byType[notificationType] ??= {
          'delivered': 0,
          'opened': 0,
          'dismissed': 0,
          'conversions': 0,
        };

        switch (eventType) {
          case 'delivery':
            byType[notificationType]!['delivered'] =
                byType[notificationType]!['delivered']! + 1;
            break;
          case 'tap':
            byType[notificationType]!['opened'] =
                byType[notificationType]!['opened']! + 1;
            break;
          case 'dismiss':
            byType[notificationType]!['dismissed'] =
                byType[notificationType]!['dismissed']! + 1;
            break;
          case 'conversion':
            byType[notificationType]!['conversions'] =
                byType[notificationType]!['conversions']! + 1;
            break;
        }
      }

      // Calculate rates
      final totalDelivered = summary['total_delivered'] as int;
      if (totalDelivered > 0) {
        summary['open_rate'] =
            (summary['total_opened'] as int) / totalDelivered * 100;
        summary['conversion_rate'] =
            (summary['total_conversions'] as int) / totalDelivered * 100;
      }

      return summary;
    } catch (e, stackTrace) {
      LoggerService.error(
        'Failed to get notification analytics summary',
        e,
        stackTrace,
      );
      return {
        'total_delivered': 0,
        'total_opened': 0,
        'total_dismissed': 0,
        'total_conversions': 0,
        'by_type': {},
        'open_rate': 0.0,
        'conversion_rate': 0.0,
      };
    }
  }
}
