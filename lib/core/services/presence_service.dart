import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to manage user online presence
class PresenceService {
  final SupabaseClient _supabaseClient;
  
  PresenceService(this._supabaseClient);

  /// Update user's last seen and mark as online
  Future<void> updatePresence() async {
    try {
      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser == null) return;

      await _supabaseClient.rpc('update_user_last_seen', params: {
        'user_id': currentUser.id,
      });
      
      debugPrint('💚 User presence updated');
    } catch (e) {
      debugPrint('⚠️ Failed to update presence: $e');
    }
  }

  /// Mark user as offline
  Future<void> goOffline() async {
    try {
      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser == null) return;

      await _supabaseClient.rpc('mark_user_offline', params: {
        'user_id': currentUser.id,
      });
      
      debugPrint('💔 User marked as offline');
    } catch (e) {
      debugPrint('⚠️ Failed to mark offline: $e');
    }
  }

  /// Start periodic presence updates (call every 2 minutes when app is active)
  void startPresenceUpdates() {
    updatePresence(); // Update immediately
    
    // You can add a periodic timer here if needed
    // Timer.periodic(Duration(minutes: 2), (timer) {
    //   updatePresence();
    // });
  }
}

