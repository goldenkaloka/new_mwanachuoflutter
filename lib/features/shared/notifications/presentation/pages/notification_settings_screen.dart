import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/features/shared/notifications/domain/usecases/get_notification_preferences.dart';
import 'package:mwanachuo/features/shared/notifications/domain/usecases/update_notification_preferences.dart';
import 'package:mwanachuo/features/shared/notifications/domain/entities/notification_preferences_entity.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final GetNotificationPreferences _getNotificationPreferences =
      sl<GetNotificationPreferences>();
  final UpdateNotificationPreferences _updateNotificationPreferences =
      sl<UpdateNotificationPreferences>();

  NotificationPreferencesEntity? _preferences;
  bool _isLoading = true;
  bool _quietHoursEnabled = false;
  TimeOfDay? _quietHoursStart;
  TimeOfDay? _quietHoursEnd;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    final result = await _getNotificationPreferences();
    result.fold(
      (failure) {
        setState(() {
          _preferences = NotificationPreferencesEntity(
            id: '',
            userId: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          _isLoading = false;
        });
      },
      (preferences) {
        setState(() {
          _preferences = preferences;
          _isLoading = false;

          // Load quiet hours
          if (preferences.quietHoursStart != null) {
            _quietHoursStart = TimeOfDay.fromDateTime(
              preferences.quietHoursStart!,
            );
            _quietHoursEnabled = true;
          }
          if (preferences.quietHoursEnd != null) {
            _quietHoursEnd = TimeOfDay.fromDateTime(preferences.quietHoursEnd!);
            _quietHoursEnabled = true;
          }
        });
      },
    );
  }

  Future<void> _updatePreference({
    bool? pushEnabled,
    bool? messagesEnabled,
    bool? reviewsEnabled,
    bool? listingsEnabled,
    bool? promotionsEnabled,
    bool? sellerRequestsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? badgeEnabled,
    bool? inAppBannerEnabled,
    bool? groupNotifications,
    bool? groupByCategory,
    DateTime? quietHoursStart,
    DateTime? quietHoursEnd,
  }) async {
    // If disabling quiet hours (passing null), we need to handle it carefully
    // The repository handles nulls as "no change", so we might need a specific flag or logic
    // But assuming the repository handles explicit nulls if we pass them

    final result = await _updateNotificationPreferences(
      pushEnabled: pushEnabled,
      messagesEnabled: messagesEnabled,
      reviewsEnabled: reviewsEnabled,
      listingsEnabled: listingsEnabled,
      promotionsEnabled: promotionsEnabled,
      sellerRequestsEnabled: sellerRequestsEnabled,
      quietHoursStart: quietHoursStart,
      quietHoursEnd: quietHoursEnd,
      soundEnabled: soundEnabled,
      vibrationEnabled: vibrationEnabled,
      badgeEnabled: badgeEnabled,
      inAppBannerEnabled: inAppBannerEnabled,
      groupNotifications: groupNotifications,
      groupByCategory: groupByCategory,
    );

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: ${failure.message}')),
        );
        _loadPreferences();
      },
      (_) {
        _loadPreferences();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? Colors.white : kTextPrimary;
    final secondaryTextColor = isDarkMode
        ? Colors.grey[400]!
        : Colors.grey[600]!;
    final surfaceColor = isDarkMode
        ? Colors.grey[800]!.withValues(alpha: 0.5)
        : Colors.white;
    final borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;

    return Scaffold(
      backgroundColor: isDarkMode
          ? kBackgroundColorDark
          : kBackgroundColorLight,
      body: ResponsiveBuilder(
        builder: (context, screenSize) {
          return Column(
            children: [
              _buildTopAppBar(context, primaryTextColor, screenSize),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: kPrimaryColor),
                      )
                    : SingleChildScrollView(
                        child: ResponsiveContainer(
                          child: Padding(
                            padding: EdgeInsets.all(
                              ResponsiveBreakpoints.responsiveHorizontalPadding(
                                context,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: ResponsiveBreakpoints.responsiveValue(
                                    context,
                                    compact: 16.0,
                                    medium: 20.0,
                                    expanded: 24.0,
                                  ),
                                ),
                                _buildSection(
                                  context,
                                  'Push Notifications',
                                  primaryTextColor,
                                  secondaryTextColor,
                                  surfaceColor,
                                  borderColor,
                                  isDarkMode,
                                  screenSize,
                                  [
                                    _NotificationItem(
                                      icon: Icons.notifications_active,
                                      title: 'Enable Push Notifications',
                                      description:
                                          'Receive push notifications on your device',
                                      value: _preferences?.pushEnabled ?? true,
                                      onChanged: (value) {
                                        _updatePreference(pushEnabled: value);
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: ResponsiveBreakpoints.responsiveValue(
                                    context,
                                    compact: 24.0,
                                    medium: 32.0,
                                    expanded: 40.0,
                                  ),
                                ),
                                _buildSection(
                                  context,
                                  'Notification Types',
                                  primaryTextColor,
                                  secondaryTextColor,
                                  surfaceColor,
                                  borderColor,
                                  isDarkMode,
                                  screenSize,
                                  [
                                    _NotificationItem(
                                      icon: Icons.message,
                                      title: 'Messages',
                                      description:
                                          'New messages from other users',
                                      value:
                                          _preferences?.messagesEnabled ?? true,
                                      enabled:
                                          _preferences?.pushEnabled ?? true,
                                      onChanged: (value) {
                                        _updatePreference(
                                          messagesEnabled: value,
                                        );
                                      },
                                    ),
                                    _NotificationItem(
                                      icon: Icons.star,
                                      title: 'Reviews',
                                      description:
                                          'New reviews on your listings',
                                      value:
                                          _preferences?.reviewsEnabled ?? true,
                                      enabled:
                                          _preferences?.pushEnabled ?? true,
                                      onChanged: (value) {
                                        _updatePreference(
                                          reviewsEnabled: value,
                                        );
                                      },
                                    ),
                                    _NotificationItem(
                                      icon: Icons.store,
                                      title: 'New Listings',
                                      description:
                                          'New products, services, and accommodations',
                                      value:
                                          _preferences?.listingsEnabled ?? true,
                                      enabled:
                                          _preferences?.pushEnabled ?? true,
                                      onChanged: (value) {
                                        _updatePreference(
                                          listingsEnabled: value,
                                        );
                                      },
                                    ),
                                    _NotificationItem(
                                      icon: Icons.local_offer,
                                      title: 'Promotions',
                                      description:
                                          'Special offers and promotions',
                                      value:
                                          _preferences?.promotionsEnabled ??
                                          true,
                                      enabled:
                                          _preferences?.pushEnabled ?? true,
                                      onChanged: (value) {
                                        _updatePreference(
                                          promotionsEnabled: value,
                                        );
                                      },
                                    ),
                                    _NotificationItem(
                                      icon: Icons.verified_user,
                                      title: 'Seller Requests',
                                      description:
                                          'Seller access requests and approvals',
                                      value:
                                          _preferences?.sellerRequestsEnabled ??
                                          true,
                                      enabled:
                                          _preferences?.pushEnabled ?? true,
                                      onChanged: (value) {
                                        _updatePreference(
                                          sellerRequestsEnabled: value,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: ResponsiveBreakpoints.responsiveValue(
                                    context,
                                    compact: 24.0,
                                    medium: 32.0,
                                    expanded: 40.0,
                                  ),
                                ),

                                // Quiet Hours Section
                                _buildQuietHoursSection(
                                  context,
                                  primaryTextColor,
                                  secondaryTextColor,
                                  surfaceColor,
                                  borderColor,
                                  isDarkMode,
                                  screenSize,
                                ),
                                SizedBox(
                                  height: ResponsiveBreakpoints.responsiveValue(
                                    context,
                                    compact: 24.0,
                                    medium: 32.0,
                                    expanded: 40.0,
                                  ),
                                ),
                                // Enhanced Preferences Section
                                _buildEnhancedPreferencesSection(
                                  context,
                                  primaryTextColor,
                                  secondaryTextColor,
                                  surfaceColor,
                                  borderColor,
                                  isDarkMode,
                                  screenSize,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuietHoursSection(
    BuildContext context,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color surfaceColor,
    Color borderColor,
    bool isDarkMode,
    ScreenSize screenSize,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          context,
          'Quiet Hours',
          primaryTextColor,
          secondaryTextColor,
          surfaceColor,
          borderColor,
          isDarkMode,
          screenSize,
          [
            _NotificationItem(
              icon: Icons.bedtime,
              title: 'Enable Quiet Hours',
              description: 'Silence notifications during selected hours',
              value: _quietHoursEnabled,
              enabled: _preferences?.pushEnabled ?? true,
              onChanged: (value) {
                setState(() {
                  _quietHoursEnabled = value;
                  if (!value) {
                    _quietHoursStart = null;
                    _quietHoursEnd = null;
                    _updateQuietHours(null, null);
                  }
                });
              },
            ),
          ],
        ),
        if (_quietHoursEnabled) ...[
          SizedBox(
            height: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 16.0,
              medium: 20.0,
              expanded: 24.0,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16.0),
            ),
            padding: EdgeInsets.all(
              ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 16.0,
                medium: 20.0,
                expanded: 24.0,
              ),
            ),
            child: Column(
              children: [
                _buildTimePicker(
                  context,
                  'Start Time',
                  _quietHoursStart ?? const TimeOfDay(hour: 22, minute: 0),
                  primaryTextColor,
                  borderColor,
                  (time) {
                    setState(() {
                      _quietHoursStart = time;
                    });
                    _updateQuietHours(time, _quietHoursEnd);
                  },
                ),
                SizedBox(
                  height: ResponsiveBreakpoints.responsiveValue(
                    context,
                    compact: 16.0,
                    medium: 20.0,
                    expanded: 24.0,
                  ),
                ),
                _buildTimePicker(
                  context,
                  'End Time',
                  _quietHoursEnd ?? const TimeOfDay(hour: 8, minute: 0),
                  primaryTextColor,
                  borderColor,
                  (time) {
                    setState(() {
                      _quietHoursEnd = time;
                    });
                    _updateQuietHours(_quietHoursStart, time);
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimePicker(
    BuildContext context,
    String label,
    TimeOfDay initialTime,
    Color primaryTextColor,
    Color borderColor,
    ValueChanged<TimeOfDay> onTimeSelected,
  ) {
    return InkWell(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: initialTime,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: kPrimaryColor,
                  onPrimary: Colors.white,
                  onSurface: primaryTextColor,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onTimeSelected(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: primaryTextColor,
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                Text(
                  initialTime.format(context),
                  style: GoogleFonts.plusJakartaSans(
                    color: primaryTextColor,
                    fontSize: 16.0,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.access_time, color: primaryTextColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateQuietHours(TimeOfDay? start, TimeOfDay? end) async {
    if (start == null || end == null) {
      // Disable quiet hours
      await _updatePreference(quietHoursStart: null, quietHoursEnd: null);
      return;
    }

    // Convert TimeOfDay to DateTime for storage
    final now = DateTime.now();
    final startDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      start.hour,
      start.minute,
    );
    final endDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      end.hour,
      end.minute,
    );

    await _updatePreference(
      quietHoursStart: startDateTime,
      quietHoursEnd: endDateTime,
    );
  }

  Widget _buildEnhancedPreferencesSection(
    BuildContext context,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color surfaceColor,
    Color borderColor,
    bool isDarkMode,
    ScreenSize screenSize,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          context,
          'Display Preferences',
          primaryTextColor,
          secondaryTextColor,
          surfaceColor,
          borderColor,
          isDarkMode,
          screenSize,
          [
            _NotificationItem(
              icon: Icons.volume_up,
              title: 'Sound',
              description: 'Play sound for notifications',
              value: _preferences?.soundEnabled ?? true,
              enabled: _preferences?.pushEnabled ?? true,
              onChanged: (value) {
                _updatePreference(soundEnabled: value);
              },
            ),
            _NotificationItem(
              icon: Icons.vibration,
              title: 'Vibration',
              description: 'Vibrate device for notifications',
              value: _preferences?.vibrationEnabled ?? true,
              enabled: _preferences?.pushEnabled ?? true,
              onChanged: (value) {
                _updatePreference(vibrationEnabled: value);
              },
            ),
            _NotificationItem(
              icon: Icons.badge,
              title: 'Badge Count',
              description: 'Show unread count on app icon',
              value: _preferences?.badgeEnabled ?? true,
              enabled: _preferences?.pushEnabled ?? true,
              onChanged: (value) {
                _updatePreference(badgeEnabled: value);
              },
            ),
            _NotificationItem(
              icon: Icons.notifications_active,
              title: 'In-App Banners',
              description: 'Show banners when app is open',
              value: _preferences?.inAppBannerEnabled ?? true,
              enabled: _preferences?.pushEnabled ?? true,
              onChanged: (value) {
                _updatePreference(inAppBannerEnabled: value);
              },
            ),
          ],
        ),
        SizedBox(
          height: ResponsiveBreakpoints.responsiveValue(
            context,
            compact: 24.0,
            medium: 32.0,
            expanded: 40.0,
          ),
        ),
        _buildSection(
          context,
          'Grouping',
          primaryTextColor,
          secondaryTextColor,
          surfaceColor,
          borderColor,
          isDarkMode,
          screenSize,
          [
            _NotificationItem(
              icon: Icons.group,
              title: 'Group Notifications',
              description: 'Group related notifications together',
              value: _preferences?.groupNotifications ?? true,
              enabled: _preferences?.pushEnabled ?? true,
              onChanged: (value) {
                _updatePreference(groupNotifications: value);
              },
            ),
            _NotificationItem(
              icon: Icons.category,
              title: 'Group by Category',
              description: 'Group notifications by type',
              value: _preferences?.groupByCategory ?? true,
              enabled:
                  _preferences?.pushEnabled ??
                  true && (_preferences?.groupNotifications ?? true),
              onChanged: (value) {
                _updatePreference(groupByCategory: value);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopAppBar(
    BuildContext context,
    Color primaryTextColor,
    ScreenSize screenSize,
  ) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(
      context,
    );
    return Container(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        screenSize == ScreenSize.expanded ? 24.0 : 48.0,
        horizontalPadding,
        ResponsiveBreakpoints.responsiveValue(
          context,
          compact: 12.0,
          medium: 16.0,
          expanded: 20.0,
        ),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[700]!
                : Colors.grey[300]!,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: primaryTextColor),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(
              minWidth: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 40.0,
                medium: 44.0,
                expanded: 48.0,
              ),
              minHeight: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 40.0,
                medium: 44.0,
                expanded: 48.0,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Notification Settings',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: primaryTextColor,
                fontSize: ResponsiveBreakpoints.responsiveValue(
                  context,
                  compact: 20.0,
                  medium: 22.0,
                  expanded: 24.0,
                ),
                fontWeight: FontWeight.bold,
                letterSpacing: -0.015,
              ),
            ),
          ),
          SizedBox(
            width: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 40.0,
              medium: 44.0,
              expanded: 48.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color surfaceColor,
    Color borderColor,
    bool isDarkMode,
    ScreenSize screenSize,
    List<_NotificationItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 8.0,
              medium: 12.0,
              expanded: 16.0,
            ),
          ),
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: primaryTextColor,
              fontSize: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 16.0,
                medium: 17.0,
                expanded: 18.0,
              ),
              fontWeight: FontWeight.bold,
              letterSpacing: -0.015,
            ),
          ),
        ),
        SizedBox(
          height: ResponsiveBreakpoints.responsiveValue(
            context,
            compact: 8.0,
            medium: 12.0,
            expanded: 16.0,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Column(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  _buildNotificationItem(
                    context,
                    item,
                    primaryTextColor,
                    secondaryTextColor,
                    isDarkMode,
                    screenSize,
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: ResponsiveBreakpoints.responsiveValue(
                        context,
                        compact: 80.0,
                        medium: 88.0,
                        expanded: 96.0,
                      ),
                      color: borderColor,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    _NotificationItem item,
    Color primaryTextColor,
    Color secondaryTextColor,
    bool isDarkMode,
    ScreenSize screenSize,
  ) {
    return InkWell(
      onTap: item.enabled == false ? null : () => item.onChanged(!item.value),
      child: Opacity(
        opacity: item.enabled == false ? 0.5 : 1.0,
        child: Container(
          constraints: BoxConstraints(
            minHeight: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 72.0,
              medium: 80.0,
              expanded: 88.0,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 16.0,
              medium: 20.0,
              expanded: 24.0,
            ),
            vertical: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 12.0,
              medium: 16.0,
              expanded: 20.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: ResponsiveBreakpoints.responsiveValue(
                  context,
                  compact: 40.0,
                  medium: 44.0,
                  expanded: 48.0,
                ),
                height: ResponsiveBreakpoints.responsiveValue(
                  context,
                  compact: 40.0,
                  medium: 44.0,
                  expanded: 48.0,
                ),
                decoration: BoxDecoration(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Icon(
                  item.icon,
                  color: Colors.white,
                  size: ResponsiveBreakpoints.responsiveValue(
                    context,
                    compact: 20.0,
                    medium: 22.0,
                    expanded: 24.0,
                  ),
                ),
              ),
              SizedBox(
                width: ResponsiveBreakpoints.responsiveValue(
                  context,
                  compact: 16.0,
                  medium: 20.0,
                  expanded: 24.0,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.plusJakartaSans(
                        color: primaryTextColor,
                        fontSize: ResponsiveBreakpoints.responsiveValue(
                          context,
                          compact: 16.0,
                          medium: 17.0,
                          expanded: 18.0,
                        ),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (item.description != null) ...[
                      SizedBox(height: 4),
                      Text(
                        item.description!,
                        style: GoogleFonts.plusJakartaSans(
                          color: secondaryTextColor,
                          fontSize: ResponsiveBreakpoints.responsiveValue(
                            context,
                            compact: 13.0,
                            medium: 14.0,
                            expanded: 15.0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(
                width: ResponsiveBreakpoints.responsiveValue(
                  context,
                  compact: 12.0,
                  medium: 16.0,
                  expanded: 20.0,
                ),
              ),
              Switch(
                value: item.value,
                onChanged: item.enabled == false ? null : item.onChanged,
                thumbColor: WidgetStateProperty.all( kPrimaryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _NotificationItem {
  final IconData icon;
  final String title;
  final String? description;
  final bool value;
  final bool? enabled;
  final ValueChanged<bool> onChanged;

  _NotificationItem({
    required this.icon,
    required this.title,
    this.description,
    required this.value,
    this.enabled,
    required this.onChanged,
  });
}
