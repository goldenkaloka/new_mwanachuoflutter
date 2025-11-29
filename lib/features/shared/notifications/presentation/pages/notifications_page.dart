import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/services/notification_grouping_service.dart';

import 'package:mwanachuo/features/shared/notifications/domain/entities/notification_group_entity.dart';
import 'package:mwanachuo/config/supabase_config.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationGroupingService _groupingService =
      NotificationGroupingService();
  List<NotificationGroupEntity> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId != null) {
      final groups = await _groupingService.getUserGroups(userId: userId);
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
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

    return Scaffold(
      backgroundColor: isDarkMode
          ? kBackgroundColorDark
          : kBackgroundColorLight,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.plusJakartaSans(
            color: primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: primaryTextColor),
            onPressed: () =>
                Navigator.pushNamed(context, '/notification-settings'),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : _groups.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: secondaryTextColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: GoogleFonts.plusJakartaSans(
                      color: secondaryTextColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadGroups,
              color: kPrimaryColor,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _groups.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final group = _groups[index];
                  return _buildGroupItem(
                    context,
                    group,
                    primaryTextColor,
                    secondaryTextColor,
                    surfaceColor,
                  );
                },
              ),
            ),
    );
  }

  Widget _buildGroupItem(
    BuildContext context,
    NotificationGroupEntity group,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color surfaceColor,
  ) {
    IconData icon;
    Color iconColor;

    switch (group.category) {
      case 'message':
        icon = Icons.chat_bubble;
        iconColor = Colors.blue;
        break;
      case 'review':
        icon = Icons.star;
        iconColor = Colors.amber;
        break;
      case 'order':
        icon = Icons.shopping_bag;
        iconColor = kPrimaryColor;
        break;
      default:
        icon = Icons.notifications;
        iconColor = kPrimaryColor;
    }

    return Dismissible(
      key: Key(group.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _groupingService.deleteGroup(group.id);
        setState(() {
          _groups.removeAt(_groups.indexOf(group));
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  group.title,
                  style: GoogleFonts.plusJakartaSans(
                    color: primaryTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (group.latestNotificationAt != null)
                Text(
                  timeago.format(
                    group.latestNotificationAt!,
                    locale: 'en_short',
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    color: secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              if (group.summary != null)
                Text(
                  group.summary!,
                  style: GoogleFonts.plusJakartaSans(
                    color: secondaryTextColor,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (group.unreadCount > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${group.unreadCount} new',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          onTap: () {
            // Handle navigation based on category
            if (group.category == 'message') {
              // Extract conversation ID from group key if possible
              // Format: message_conversation_ID
              final parts = group.groupKey.split('_');
              if (parts.length >= 3 && parts[1] == 'conversation') {
                Navigator.pushNamed(context, '/chat', arguments: parts[2]);
              }
            }
            // Mark as read
            _groupingService.markGroupAsRead(group.id);
            setState(() {
              // Update local state to reflect read status
              final index = _groups.indexOf(group);
              if (index != -1) {
                _groups[index] = group.copyWith(unreadCount: 0);
              }
            });
          },
        ),
      ),
    );
  }
}
