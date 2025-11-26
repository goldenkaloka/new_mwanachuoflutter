import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

/// Handles all FCM + local notification coordination for the app.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final Logger _logger = Logger();
  final StreamController<String?> _notificationTapController =
      StreamController<String?>.broadcast();

  AndroidNotificationChannel? _androidChannel;

  Stream<String?> get notificationTaps => _notificationTapController.stream;

  /// Call once during app start.
  Future<void> initialize() async {
    await _configureLocalNotifications();

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// Requests runtime permissions (recommended to call after onboarding).
  Future<NotificationSettings> requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    _logger.i('Notification permission status: ${settings.authorizationStatus}');
    return settings;
  }

  Future<String?> getToken() => _messaging.getToken();

  StreamSubscription<String> listenForTokenRefresh(
    Future<void> Function(String token) callback,
  ) {
    return _messaging.onTokenRefresh.listen((token) {
      unawaited(callback(token));
    });
  }

  Future<void> _configureLocalNotifications() async {
    _androidChannel ??= const AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Used for important updates like chats and orders.',
      importance: Importance.high,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel!);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _localNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        _notificationTapController.add(response.payload);
      },
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final android = notification?.android;

    if (notification == null) {
      _logger.w('Foreground data message received with no notification payload');
      return;
    }

    _localNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: android != null
            ? AndroidNotificationDetails(
                _androidChannel!.id,
                _androidChannel!.name,
                channelDescription: _androidChannel!.description,
                icon: android.smallIcon ?? '@mipmap/ic_launcher',
              )
            : null,
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    _notificationTapController.add(message.data.isNotEmpty ? message.data.toString() : null);
  }

  Future<void> dispose() async {
    await _notificationTapController.close();
  }
}

