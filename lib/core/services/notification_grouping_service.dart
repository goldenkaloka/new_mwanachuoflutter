import 'package:mwanachuo/config/supabase_config.dart';
import 'package:mwanachuo/core/services/logger_service.dart';
import 'package:mwanachuo/features/shared/notifications/domain/entities/notification_group_entity.dart';

/// Service for managing notification grouping
class NotificationGroupingService {
  static final NotificationGroupingService _instance =
      NotificationGroupingService._internal();
  factory NotificationGroupingService() => _instance;
  NotificationGroupingService._internal();

  /// Generate a group key for a notification based on its category and context
  static String generateGroupKey({
    required String category,
    required Map<String, dynamic> additionalData,
  }) {
    switch (category) {
      case 'message':
        // Group by conversation ID
        final conversationId = additionalData['conversationId'] as String?;
        return conversationId != null
            ? 'message_conversation_$conversationId'
            : 'message_${DateTime.now().millisecondsSinceEpoch}';

      case 'review':
        // Group by product/service ID
        final itemId = additionalData['itemId'] as String?;
        final itemType = additionalData['itemType'] as String?;
        return itemId != null && itemType != null
            ? 'review_${itemType}_$itemId'
            : 'review_${DateTime.now().millisecondsSinceEpoch}';

      case 'order':
        // Group by order ID
        final orderId = additionalData['orderId'] as String?;
        return orderId != null
            ? 'order_$orderId'
            : 'order_${DateTime.now().millisecondsSinceEpoch}';

      default:
        // Default: group by category and date (daily grouping)
        final date = DateTime.now().toIso8601String().split('T')[0];
        return '${category}_$date';
    }
  }

  /// Create or update a notification group
  Future<String> createOrUpdateGroup({
    required String userId,
    required String groupKey,
    required String category,
    required String title,
    String? summary,
    required String notificationId,
  }) async {
    try {
      // Check if group exists
      final existingGroup = await SupabaseConfig.client
          .from('notification_groups')
          .select('id')
          .eq('user_id', userId)
          .eq('group_key', groupKey)
          .maybeSingle();

      String groupId;

      if (existingGroup != null) {
        // Update existing group
        groupId = existingGroup['id'] as String;
        await SupabaseConfig.client
            .from('notification_groups')
            .update({
              'title': title,
              'summary': summary,
              'latest_notification_id': notificationId,
              'latest_notification_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', groupId);
      } else {
        // Create new group
        final response = await SupabaseConfig.client
            .from('notification_groups')
            .insert({
              'user_id': userId,
              'group_key': groupKey,
              'category': category,
              'title': title,
              'summary': summary,
              'latest_notification_id': notificationId,
              'latest_notification_at': DateTime.now().toIso8601String(),
            })
            .select('id')
            .single();

        groupId = response['id'] as String;
      }

      // Add notification to group
      await SupabaseConfig.client
          .from('notification_group_members')
          .upsert({
            'group_id': groupId,
            'notification_id': notificationId,
          }, onConflict: 'group_id,notification_id');

      LoggerService.debug(
        'Notification group created/updated: $groupId for notification: $notificationId',
      );

      return groupId;
    } catch (e, stackTrace) {
      LoggerService.error(
        'Failed to create/update notification group',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Get notification groups for a user
  Future<List<NotificationGroupEntity>> getUserGroups({
    required String userId,
    String? category,
    int? limit,
    int? offset,
  }) async {
    try {
      var query = SupabaseConfig.client
          .from('notification_groups')
          .select()
          .eq('user_id', userId);

      if (category != null) {
        query = query.eq('category', category);
      }

      final data = await query.order('updated_at', ascending: false);

      return data.map((json) {
        return NotificationGroupEntity(
          id: json['id'] as String,
          userId: json['user_id'] as String,
          groupKey: json['group_key'] as String,
          category: json['category'] as String,
          title: json['title'] as String,
          summary: json['summary'] as String?,
          unreadCount: json['unread_count'] as int? ?? 0,
          latestNotificationId: json['latest_notification_id'] as String?,
          latestNotificationAt: json['latest_notification_at'] != null
              ? DateTime.parse(json['latest_notification_at'] as String)
              : null,
          createdAt: DateTime.parse(json['created_at'] as String),
          updatedAt: DateTime.parse(json['updated_at'] as String),
        );
      }).toList();
    } catch (e, stackTrace) {
      LoggerService.error('Failed to get notification groups', e, stackTrace);
      return [];
    }
  }

  /// Mark a notification group as read
  Future<void> markGroupAsRead(String groupId) async {
    try {
      await SupabaseConfig.client.rpc(
        'mark_notification_group_read',
        params: {'group_id_param': groupId},
      );

      LoggerService.debug('Notification group marked as read: $groupId');
    } catch (e, stackTrace) {
      LoggerService.error(
        'Failed to mark notification group as read',
        e,
        stackTrace,
      );
    }
  }

  /// Delete a notification group
  Future<void> deleteGroup(String groupId) async {
    try {
      await SupabaseConfig.client
          .from('notification_groups')
          .delete()
          .eq('id', groupId);

      LoggerService.debug('Notification group deleted: $groupId');
    } catch (e, stackTrace) {
      LoggerService.error('Failed to delete notification group', e, stackTrace);
    }
  }
}

