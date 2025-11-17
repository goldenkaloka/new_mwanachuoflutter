import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/notifications/domain/usecases/delete_all_read.dart';
import 'package:mwanachuo/features/shared/notifications/domain/usecases/delete_notification.dart';
import 'package:mwanachuo/features/shared/notifications/domain/usecases/get_notifications.dart';
import 'package:mwanachuo/features/shared/notifications/domain/usecases/get_unread_count.dart';
import 'package:mwanachuo/features/shared/notifications/domain/usecases/mark_all_as_read.dart';
import 'package:mwanachuo/features/shared/notifications/domain/usecases/mark_as_read.dart';
import 'package:mwanachuo/features/shared/notifications/domain/usecases/subscribe_to_notifications.dart';
import 'package:mwanachuo/features/shared/notifications/presentation/cubit/notification_state.dart';

/// Cubit for managing notification state
class NotificationCubit extends Cubit<NotificationState> {
  final GetNotifications getNotifications;
  final GetUnreadCount getUnreadCount;
  final MarkAsRead markAsRead;
  final MarkAllAsRead markAllAsRead;
  final DeleteNotification deleteNotification;
  final DeleteAllRead deleteAllRead;
  final SubscribeToNotifications subscribeToNotifications;

  StreamSubscription? _notificationSubscription;

  NotificationCubit({
    required this.getNotifications,
    required this.getUnreadCount,
    required this.markAsRead,
    required this.markAllAsRead,
    required this.deleteNotification,
    required this.deleteAllRead,
    required this.subscribeToNotifications,
  }) : super(NotificationInitial());

  /// Load notifications
  Future<void> loadNotifications({
    int? limit,
    int? offset,
    bool? unreadOnly,
  }) async {
    if (isClosed) return;
    emit(NotificationsLoading());

    // Load notifications and unread count in parallel
    final notificationsResult = await getNotifications(
      GetNotificationsParams(
        limit: limit,
        offset: offset,
        unreadOnly: unreadOnly,
      ),
    );

    final unreadCountResult = await getUnreadCount(NoParams());

    if (isClosed) return;
    notificationsResult.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (notifications) {
        unreadCountResult.fold(
          (failure) => emit(NotificationsLoaded(
            notifications: notifications,
            unreadCount: 0,
            hasMore: notifications.length == (limit ?? 20),
          )),
          (count) => emit(NotificationsLoaded(
            notifications: notifications,
            unreadCount: count,
            hasMore: notifications.length == (limit ?? 20),
          )),
        );
      },
    );
  }

  /// Load more notifications (pagination)
  Future<void> loadMore({
    required int offset,
    int? limit,
    bool? unreadOnly,
  }) async {
    if (isClosed || state is! NotificationsLoaded) return;

    final currentState = state as NotificationsLoaded;

    final result = await getNotifications(
      GetNotificationsParams(
        limit: limit,
        offset: offset,
        unreadOnly: unreadOnly,
      ),
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (notifications) {
        final allNotifications = [
          ...currentState.notifications,
          ...notifications,
        ];
        emit(NotificationsLoaded(
          notifications: allNotifications,
          unreadCount: currentState.unreadCount,
          hasMore: notifications.length == (limit ?? 20),
        ));
      },
    );
  }

  /// Load unread count only
  Future<void> loadUnreadCount() async {
    if (isClosed) return;
    emit(UnreadCountLoading());

    final result = await getUnreadCount(NoParams());

    if (isClosed) return;
    result.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (count) => emit(UnreadCountLoaded(count: count)),
    );
  }

  /// Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    if (isClosed) return;
    emit(MarkingAsRead());

    final result = await markAsRead(
      MarkAsReadParams(notificationId: notificationId),
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (_) {
        emit(MarkedAsRead());
        // Reload notifications to update UI
        loadNotifications();
      },
    );
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    if (isClosed) return;
    emit(MarkingAllAsRead());

    final result = await markAllAsRead(NoParams());

    if (isClosed) return;
    result.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (_) {
        emit(MarkedAllAsRead());
        // Reload notifications to update UI
        loadNotifications();
      },
    );
  }

  /// Delete a notification
  Future<void> deleteNotif(String notificationId) async {
    if (isClosed) return;
    emit(DeletingNotification());

    final result = await deleteNotification(
      DeleteNotificationParams(notificationId: notificationId),
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (_) {
        emit(NotificationDeleted());
        // Reload notifications to update UI
        loadNotifications();
      },
    );
  }

  /// Delete all read notifications
  Future<void> deleteAllReadNotifications() async {
    if (isClosed) return;
    emit(DeletingAllRead());

    final result = await deleteAllRead(NoParams());

    if (isClosed) return;
    result.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (_) {
        emit(AllReadDeleted());
        // Reload notifications to update UI
        loadNotifications();
      },
    );
  }

  /// Subscribe to real-time notifications
  void startListening() {
    _notificationSubscription?.cancel();
    _notificationSubscription = subscribeToNotifications(NoParams()).listen(
      (notification) {
        if (!isClosed) {
          emit(NewNotificationReceived(notification: notification));
          // Reload notifications to update list
          loadNotifications();
        }
      },
      onError: (error) {
        if (!isClosed) {
          emit(NotificationError(message: 'Real-time update error: $error'));
        }
      },
    );
  }

  /// Stop listening to real-time notifications
  void stopListening() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
  }

  @override
  Future<void> close() {
    stopListening();
    return super.close();
  }

  /// Reset to initial state
  void reset() {
    emit(NotificationInitial());
  }
}

