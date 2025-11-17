import 'package:mwanachuo/core/constants/database_constants.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/features/shared/notifications/data/models/notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Abstract class defining notification remote data source operations
abstract class NotificationRemoteDataSource {
  /// Get notifications for the current user
  Future<List<NotificationModel>> getNotifications({
    int? limit,
    int? offset,
    bool? unreadOnly,
  });

  /// Get unread notification count
  Future<int> getUnreadCount();

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId);

  /// Mark all notifications as read
  Future<void> markAllAsRead();

  /// Delete a notification
  Future<void> deleteNotification(String notificationId);

  /// Delete all read notifications
  Future<void> deleteAllRead();

  /// Subscribe to real-time notifications
  Stream<NotificationModel> subscribeToNotifications();
}

/// Implementation of NotificationRemoteDataSource using Supabase
class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final SupabaseClient supabaseClient;

  NotificationRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<NotificationModel>> getNotifications({
    int? limit,
    int? offset,
    bool? unreadOnly,
  }) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw ServerException('User not authenticated');
      }

      var queryBuilder = supabaseClient
          .from(DatabaseConstants.notificationsTable)
          .select()
          .eq('user_id', currentUser.id);

      if (unreadOnly == true) {
        queryBuilder = queryBuilder.eq('is_read', false);
      }

      final response = await queryBuilder
          .order('created_at', ascending: false)
          .limit(limit ?? 20)
          .range(offset ?? 0, (offset ?? 0) + (limit ?? 20) - 1);

      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get notifications: $e');
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw ServerException('User not authenticated');
      }

      final response = await supabaseClient
          .from(DatabaseConstants.notificationsTable)
          .select()
          .eq('user_id', currentUser.id)
          .eq('is_read', false);

      return (response as List).length;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get unread count: $e');
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw ServerException('User not authenticated');
      }

      await supabaseClient
          .from(DatabaseConstants.notificationsTable)
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId)
          .eq('user_id', currentUser.id);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to mark notification as read: $e');
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw ServerException('User not authenticated');
      }

      await supabaseClient
          .from(DatabaseConstants.notificationsTable)
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', currentUser.id)
          .eq('is_read', false);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to mark all as read: $e');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw ServerException('User not authenticated');
      }

      await supabaseClient
          .from(DatabaseConstants.notificationsTable)
          .delete()
          .eq('id', notificationId)
          .eq('user_id', currentUser.id);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to delete notification: $e');
    }
  }

  @override
  Future<void> deleteAllRead() async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw ServerException('User not authenticated');
      }

      await supabaseClient
          .from(DatabaseConstants.notificationsTable)
          .delete()
          .eq('user_id', currentUser.id)
          .eq('is_read', true);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to delete read notifications: $e');
    }
  }

  @override
  Stream<NotificationModel> subscribeToNotifications() {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw ServerException('User not authenticated');
      }

      return supabaseClient
          .from(DatabaseConstants.notificationsTable)
          .stream(primaryKey: ['id'])
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false)
          .map((data) => data.map((json) => NotificationModel.fromJson(json)))
          .expand((notifications) => notifications);
    } catch (e) {
      throw ServerException('Failed to subscribe to notifications: $e');
    }
  }
}
