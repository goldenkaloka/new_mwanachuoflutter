class StorageConstants {
  // SharedPreferences Keys
  static const String selectedUniversityKey = 'selected_university';
  static const String universitiesCacheKey = 'universities_cache';
  static const String userTokenKey = 'user_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String isLoggedInKey = 'is_logged_in';
  static const String themeModeKey = 'theme_mode';
  static const String onboardingCompletedKey = 'onboarding_completed';
  static const String registrationCompletedKey = 'registration_completed';

  // Review caching
  static const String reviewsCachePrefix = 'reviews_cache';
  static const String reviewStatsCachePrefix = 'review_stats_cache';

  // Search history
  static String searchHistoryKey = 'search_history';
  static const String searchResultsCacheKey = 'search_results_cache';

  // Notifications
  static const String notificationsCacheKey = 'notifications_cache';
  static const String unreadCountKey = 'unread_count';

  // Products
  static const String productsCacheKey = 'products_cache';
  static const String productCachePrefix = 'product_cache';

  // Services
  static const String servicesCacheKey = 'services_cache';
  static const String serviceCachePrefix = 'service_cache';

  // Messages & Conversations
  static const String conversationsCacheKey = 'conversations_cache';
  static const String messagesCachePrefix = 'messages_cache';
  static const String conversationCachePrefix = 'conversation_cache';
  static const String conversationTimestampPrefix = 'conversation_timestamp';

  // Profile
  static const String myProfileCacheKey = 'my_profile_cache';
  static const String profileCachePrefix = 'profile_cache';
  static const String profileTimestampKey = 'profile_timestamp';

  // Accommodations
  static const String accommodationsCacheKey = 'accommodations_cache';
  static const String accommodationCachePrefix = 'accommodation_cache';

  // Subscription cache
  static const String subscriptionAccessKey = 'subscription_access';
  static const String subscriptionAccessTimestampKey =
      'subscription_access_timestamp';

  // Cache expiration durations (in minutes)
  static const int profileCacheExpiration = 30; // 30 minutes
  static const int conversationsCacheExpiration = 5; // 5 minutes
  static const int messagesCacheExpiration = 2; // 2 minutes
  static const int productsCacheExpiration = 10; // 10 minutes

  // Hive Box Names
  static const String userBoxName = 'user_box';
  static const String cacheBoxName = 'cache_box';
  static const String settingsBoxName = 'settings_box';
  static const String messagesBoxName = 'messages_box';
  static const String profileBoxName = 'profile_box';
}
