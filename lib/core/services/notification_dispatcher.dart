import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationDispatcher {
  NotificationDispatcher(this._client);

  final SupabaseClient _client;
  final Logger _logger = Logger();

  Future<void> notifyConversation({
    required String conversationId,
    required String senderId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _client.functions.invoke(
        'send-notification',
        body: {
          'conversationId': conversationId,
          'senderId': senderId,
          'title': title,
          'body': body,
          'data': data ?? {},
        },
      );
      _logger.i('Notification dispatched for conversation $conversationId');
    } catch (error, stackTrace) {
      _logger.e(
        'Failed to dispatch notification',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

