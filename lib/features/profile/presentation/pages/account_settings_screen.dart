import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/utils/responsive.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? Colors.white : kTextPrimary;
    final secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final surfaceColor = isDarkMode ? Colors.grey[800]!.withValues(alpha: 0.5) : Colors.white;
    final borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;

    return Scaffold(
      backgroundColor: isDarkMode ? kBackgroundColorDark : kBackgroundColorLight,
      body: ResponsiveBuilder(
        builder: (context, screenSize) {
          return Column(
            children: [
              // Top App Bar
              _buildTopAppBar(context, primaryTextColor, screenSize),
              
              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  child: ResponsiveContainer(
                    child: Padding(
                      padding: EdgeInsets.all(
                        ResponsiveBreakpoints.responsiveHorizontalPadding(context),
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
                          
                          // Account Section
                          _buildSection(
                            context,
                            'Account',
                            primaryTextColor,
                            secondaryTextColor,
                            surfaceColor,
                            borderColor,
                            isDarkMode,
                            screenSize,
                            [
                              _SettingsItem(
                                icon: Icons.person,
                                title: 'Edit Profile',
                                onTap: () {
                                  Navigator.pushNamed(context, '/edit-profile');
                                },
                              ),
                              _SettingsItem(
                                icon: Icons.notifications,
                                title: 'Notification Settings',
                                hasToggle: true,
                                toggleValue: _notificationsEnabled,
                                onToggle: (value) {
                                  setState(() {
                                    _notificationsEnabled = value;
                                  });
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
                          
                          // Security Section
                          _buildSection(
                            context,
                            'Security',
                            primaryTextColor,
                            secondaryTextColor,
                            surfaceColor,
                            borderColor,
                            isDarkMode,
                            screenSize,
                            [
                              _SettingsItem(
                                icon: Icons.lock,
                                title: 'Change Password',
                                onTap: () {
                                  // Handle change password
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
                          
                          // More Info Section
                          _buildSection(
                            context,
                            'More Info',
                            primaryTextColor,
                            secondaryTextColor,
                            surfaceColor,
                            borderColor,
                            isDarkMode,
                            screenSize,
                            [
                              _SettingsItem(
                                icon: Icons.shield,
                                title: 'Privacy Policy',
                                onTap: () {
                                  // Handle privacy policy
                                },
                              ),
                              _SettingsItem(
                                icon: Icons.description,
                                title: 'Terms of Service',
                                onTap: () {
                                  // Handle terms of service
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

  Widget _buildTopAppBar(BuildContext context, Color primaryTextColor, ScreenSize screenSize) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(context);
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
              'Settings',
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
    List<_SettingsItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
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
        // Section Items Container
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
                  _buildSettingsItem(
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

  Widget _buildSettingsItem(
    BuildContext context,
    _SettingsItem item,
    Color primaryTextColor,
    Color secondaryTextColor,
    bool isDarkMode,
    ScreenSize screenSize,
  ) {
    final secondaryColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    
    return InkWell(
      onTap: item.onTap,
      child: Container(
        constraints: BoxConstraints(
          minHeight: ResponsiveBreakpoints.responsiveValue(
            context,
            compact: 64.0,
            medium: 72.0,
            expanded: 80.0,
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveBreakpoints.responsiveValue(
            context,
            compact: 16.0,
            medium: 20.0,
            expanded: 24.0,
          ),
        ),
        child: Row(
          children: [
            // Icon Container
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
            // Title
            Expanded(
              child: Text(
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
            ),
            SizedBox(
              width: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 12.0,
                medium: 16.0,
                expanded: 20.0,
              ),
            ),
            // Toggle or Chevron
            if (item.hasToggle)
              Switch(
                value: item.toggleValue ?? false,
                onChanged: item.onToggle,
                activeColor: kPrimaryColor,
              )
            else
              Icon(
                Icons.chevron_right,
                color: secondaryColor,
                size: ResponsiveBreakpoints.responsiveValue(
                  context,
                  compact: 24.0,
                  medium: 26.0,
                  expanded: 28.0,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool hasToggle;
  final bool? toggleValue;
  final ValueChanged<bool>? onToggle;

  _SettingsItem({
    required this.icon,
    required this.title,
    this.onTap,
    this.hasToggle = false,
    this.toggleValue,
    this.onToggle,
  });
}

