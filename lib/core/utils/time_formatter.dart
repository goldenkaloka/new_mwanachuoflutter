import 'package:intl/intl.dart';
import 'package:mwanachuo/core/services/logger_service.dart';

/// Unified time formatting utility to ensure consistency across the app
/// Matches WhatsApp's time display standards
class TimeFormatter {
  TimeFormatter._();

  /// Format time for conversation list items
  /// WhatsApp style: "Just now", "Xm", "HH:mm", "Yesterday", "Mon", "Jan 15"
  static String formatConversationTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    try {
      final localTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
      final now = DateTime.now();
      final difference = now.difference(localTime);

      // Handle negative differences (future times due to clock sync issues)
      // Only show "Just now" for very recent messages (less than 10 seconds)
      if (difference.isNegative || difference.inSeconds < 10) {
        return 'Just now';
      }

      // Less than 1 hour - show minutes
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m';
      }

      // Today - show time
      final today = DateTime(now.year, now.month, now.day);
      final messageDay = DateTime(localTime.year, localTime.month, localTime.day);

      if (messageDay == today) {
        // Use device's 12h/24h preference
        return DateFormat.jm().format(localTime); // "3:45 PM" or "15:45"
      }

      // Yesterday
      final yesterday = today.subtract(const Duration(days: 1));
      if (messageDay == yesterday) {
        return 'Yesterday';
      }

      // Within the last week - show day name
      if (difference.inDays < 7) {
        return DateFormat('EEE').format(localTime); // Mon, Tue, etc.
      }

      // This year - show date without year
      if (localTime.year == now.year) {
        return DateFormat('MMM d').format(localTime); // Jan 15
      }

      // Different year - show full date
      return DateFormat('MMM d, yyyy').format(localTime); // Jan 15, 2023
    } catch (e) {
      LoggerService.error('Error formatting conversation time', e);
      return '';
    }
  }

  /// Format time for message bubbles
  /// WhatsApp style: "3:45 PM" or "15:45" based on device settings
  static String formatMessageTime(DateTime dateTime) {
    try {
      final localTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
      // Use device's 12h/24h preference
      return DateFormat.jm().format(localTime);
    } catch (e) {
      LoggerService.error('Error formatting message time', e);
      return '';
    }
  }

  /// Format online status for user presence
  /// WhatsApp style: "Online", "Last seen today at 3:45 PM", "Last seen yesterday at 3:45 PM"
  static String formatOnlineStatus({
    required bool isOnline,
    DateTime? lastSeenAt,
  }) {
    if (isOnline) {
      return 'Online';
    }

    if (lastSeenAt == null) {
      return 'Offline';
    }

    try {
      final localLastSeen = lastSeenAt.isUtc ? lastSeenAt.toLocal() : lastSeenAt;
      final now = DateTime.now();
      final difference = now.difference(localLastSeen);

      // Handle negative differences (future times)
      if (difference.isNegative || difference.inSeconds < 60) {
        return 'Online'; // Just came online
      }

      final today = DateTime(now.year, now.month, now.day);
      final lastSeenDay = DateTime(
        localLastSeen.year,
        localLastSeen.month,
        localLastSeen.day,
      );
      final yesterday = today.subtract(const Duration(days: 1));

      final timeStr = DateFormat.jm().format(localLastSeen);

      // Today
      if (lastSeenDay == today) {
        return 'Last seen today at $timeStr';
      }

      // Yesterday
      if (lastSeenDay == yesterday) {
        return 'Last seen yesterday at $timeStr';
      }

      // Within a week
      if (difference.inDays < 7) {
        final dayName = DateFormat('EEEE').format(localLastSeen);
        return 'Last seen $dayName at $timeStr';
      }

      // Older - show full date
      final dateStr = DateFormat('MMM d').format(localLastSeen);
      return 'Last seen $dateStr at $timeStr';
    } catch (e) {
      LoggerService.error('Error formatting online status', e);
      return 'Offline';
    }
  }

  /// Format date separator for chat messages
  /// WhatsApp style: "Today", "Yesterday", "Monday", "January 15, 2024"
  static String formatDateSeparator(DateTime dateTime) {
    try {
      final localTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(localTime.year, localTime.month, localTime.day);
      final yesterday = today.subtract(const Duration(days: 1));

      if (messageDate == today) {
        return 'Today';
      }

      if (messageDate == yesterday) {
        return 'Yesterday';
      }

      final difference = now.difference(messageDate);

      // Within the last week - show day name
      if (difference.inDays < 7) {
        return DateFormat('EEEE').format(localTime); // Monday, Tuesday, etc.
      }

      // Older - show full date
      return DateFormat('MMMM d, yyyy').format(localTime); // January 15, 2024
    } catch (e) {
      LoggerService.error('Error formatting date separator', e);
      return '';
    }
  }

  /// Check if two dates are on the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    final local1 = date1.isUtc ? date1.toLocal() : date1;
    final local2 = date2.isUtc ? date2.toLocal() : date2;

    return local1.year == local2.year &&
        local1.month == local2.month &&
        local1.day == local2.day;
  }

  /// Format relative time for typing indicator or activity
  /// "typing...", "recording audio...", "online"
  static String formatActivity(String activity) {
    return activity;
  }
}

