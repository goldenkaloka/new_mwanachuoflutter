import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Category-specific notification preferences
class CategoryPreference {
  final bool enabled;
  final bool sound;
  final bool vibration;
  final String priority; // 'high', 'medium', 'low'

  const CategoryPreference({
    this.enabled = true,
    this.sound = true,
    this.vibration = true,
    this.priority = 'medium',
  });

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'sound': sound,
        'vibration': vibration,
        'priority': priority,
      };

  factory CategoryPreference.fromJson(Map<String, dynamic> json) {
    return CategoryPreference(
      enabled: json['enabled'] as bool? ?? true,
      sound: json['sound'] as bool? ?? true,
      vibration: json['vibration'] as bool? ?? true,
      priority: json['priority'] as String? ?? 'medium',
    );
  }
}

/// Notification preferences entity with enhanced features
class NotificationPreferencesEntity extends Equatable {
  final String id;
  final String userId;
  final bool pushEnabled;
  final bool messagesEnabled;
  final bool reviewsEnabled;
  final bool listingsEnabled;
  final bool promotionsEnabled;
  final bool sellerRequestsEnabled;
  
  // Enhanced preferences
  final DateTime? quietHoursStart;
  final DateTime? quietHoursEnd;
  final bool groupNotifications;
  final bool groupByCategory;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool badgeEnabled;
  final bool inAppBannerEnabled;
  final Map<String, CategoryPreference> categoryPreferences;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationPreferencesEntity({
    required this.id,
    required this.userId,
    this.pushEnabled = true,
    this.messagesEnabled = true,
    this.reviewsEnabled = true,
    this.listingsEnabled = true,
    this.promotionsEnabled = true,
    this.sellerRequestsEnabled = true,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.groupNotifications = true,
    this.groupByCategory = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.badgeEnabled = true,
    this.inAppBannerEnabled = true,
    this.categoryPreferences = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if notification should be delivered based on preferences
  bool shouldDeliverNotification(String category) {
    if (!pushEnabled) return false;
    
    // Check category-specific preference
    final categoryPref = categoryPreferences[category];
    if (categoryPref != null && !categoryPref.enabled) {
      return false;
    }
    
    // Check quiet hours
    if (quietHoursStart != null && quietHoursEnd != null) {
      final now = DateTime.now();
      final currentTime = TimeOfDay.fromDateTime(now);
      final startTime = TimeOfDay.fromDateTime(quietHoursStart!);
      final endTime = TimeOfDay.fromDateTime(quietHoursEnd!);
      
      if (_isTimeInRange(currentTime, startTime, endTime)) {
        return false; // In quiet hours
      }
    }
    
    return true;
  }

  bool _isTimeInRange(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    
    if (startMinutes <= endMinutes) {
      // Normal range (e.g., 22:00 to 08:00)
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // Wraps around midnight (e.g., 22:00 to 08:00)
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        pushEnabled,
        messagesEnabled,
        reviewsEnabled,
        listingsEnabled,
        promotionsEnabled,
        sellerRequestsEnabled,
        quietHoursStart,
        quietHoursEnd,
        groupNotifications,
        groupByCategory,
        soundEnabled,
        vibrationEnabled,
        badgeEnabled,
        inAppBannerEnabled,
        categoryPreferences,
        createdAt,
        updatedAt,
      ];
}

