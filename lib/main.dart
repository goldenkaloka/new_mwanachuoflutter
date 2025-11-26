import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:mwanachuo/config/supabase_config.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/core/services/notification_service.dart';
import 'package:mwanachuo/core/services/push_token_sync_service.dart';
import 'package:mwanachuo/main_app.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await SupabaseConfig.initialize();
  await initializeDependencies();

  final notificationService = NotificationService.instance;
  await notificationService.initialize();
  await notificationService.requestPermissions();

  final pushTokenSyncService = PushTokenSyncService(
    client: SupabaseConfig.client,
    notificationService: notificationService,
  );
  await pushTokenSyncService.start();

  runApp(const MwanachuoshopApp());
}
