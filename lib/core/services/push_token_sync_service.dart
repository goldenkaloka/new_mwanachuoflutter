import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:mwanachuo/core/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keeps the latest FCM token in sync with Supabase via Edge Functions.
class PushTokenSyncService {
  PushTokenSyncService({
    required SupabaseClient client,
    required NotificationService notificationService,
  }) : _client = client,
       _notificationService = notificationService;

  final SupabaseClient _client;
  final NotificationService _notificationService;
  final Logger _logger = Logger();
  StreamSubscription<String>? _tokenRefreshSub;

  Future<void> start() async {
    await _syncCurrentTokenIfNeeded();

    _client.auth.onAuthStateChange.listen((data) async {
      if (data.session != null) {
        await _syncCurrentTokenIfNeeded();
      }
    });

    _tokenRefreshSub = _notificationService.listenForTokenRefresh(
      (token) async => _sendTokenToSupabase(token),
    );
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
  }

  Future<void> _syncCurrentTokenIfNeeded() async {
    if (_client.auth.currentSession == null) return;
    final token = await _notificationService.getToken();
    await _sendTokenToSupabase(token);
  }

  Future<void> _sendTokenToSupabase(String? token) async {
    final user = _client.auth.currentUser;
    if (token == null || user == null) return;

    final payload = {
      'token': token,
      'platform': _resolvePlatform(),
      'deviceModel': _resolveDeviceLabel(),
    };

    try {
      await _client.functions.invoke('upsert-device-token', body: payload);
      _logger.i('Push token synced (${payload['platform']})');
    } catch (error, stackTrace) {
      _logger.e(
        'Failed to sync push token',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  String _resolvePlatform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'unknown';
    }
  }

  String? _resolveDeviceLabel() {
    if (kIsWeb) return 'web-browser';
    return null;
  }
}
