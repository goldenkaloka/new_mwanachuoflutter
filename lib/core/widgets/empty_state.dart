import 'package:flutter/material.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';

/// Predefined empty state types for consistency across the app
enum EmptyStateType {
  noProducts,
  noServices,
  noAccommodations,
  noConversations,
  noNotifications,
  noResults,
  noConnection,
  error,
  networkError,
}

/// A standardized empty state widget that displays when there's no data
/// 
/// Provides consistent empty states with helpful icons, messages, and actions.
/// 
/// Example:
/// ```dart
/// EmptyState(
///   type: EmptyStateType.noProducts,
///   onAction: () => Navigator.pushNamed(context, '/categories'),
/// )
/// ```
class EmptyState extends StatelessWidget {
  final EmptyStateType type;
  final String? title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? customIcon;

  const EmptyState({
    super.key,
    required this.type,
    this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(type);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kSpacing3xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Container
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: config.backgroundColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(kRadiusXl),
              ),
              child: customIcon ?? Icon(
                config.icon,
                size: kIconSize2xl,
                color: config.iconColor,
              ),
            ),
            const SizedBox(height: kSpacing2xl),
            
            // Title
            Text(
              title ?? config.defaultTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: kSpacingMd),
            
            // Subtitle
            Text(
              subtitle ?? config.defaultSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            
            // Action button
            if (onAction != null) ...[
              const SizedBox(height: kSpacing2xl),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel ?? config.defaultActionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _EmptyStateConfig _getConfig(EmptyStateType type) {
    switch (type) {
      case EmptyStateType.noProducts:
        return const _EmptyStateConfig(
          icon: Icons.shopping_bag_outlined,
          iconColor: kPrimaryColor,
          backgroundColor: kPrimaryColor,
          defaultTitle: 'No Products Yet',
          defaultSubtitle: 'Check back later for new listings',
          defaultActionLabel: 'Browse Categories',
        );
        
      case EmptyStateType.noServices:
        return const _EmptyStateConfig(
          icon: Icons.build_outlined,
          iconColor: kInfoColor,
          backgroundColor: kInfoColor,
          defaultTitle: 'No Services Available',
          defaultSubtitle: 'Be the first to offer a service!',
          defaultActionLabel: 'Add Service',
        );
        
      case EmptyStateType.noAccommodations:
        return const _EmptyStateConfig(
          icon: Icons.home_outlined,
          iconColor: kSuccessColor,
          backgroundColor: kSuccessColor,
          defaultTitle: 'No Accommodations Found',
          defaultSubtitle: 'Try adjusting your search filters',
          defaultActionLabel: 'Clear Filters',
        );
        
      case EmptyStateType.noConversations:
        return const _EmptyStateConfig(
          icon: Icons.chat_bubble_outline,
          iconColor: kPrimaryColor,
          backgroundColor: kPrimaryColor,
          defaultTitle: 'No Conversations',
          defaultSubtitle: 'Start browsing to connect with sellers',
          defaultActionLabel: 'Explore',
        );
        
      case EmptyStateType.noNotifications:
        return const _EmptyStateConfig(
          icon: Icons.notifications_none_outlined,
          iconColor: kWarningColor,
          backgroundColor: kWarningColor,
          defaultTitle: 'No Notifications',
          defaultSubtitle: 'You\'re all caught up!',
          defaultActionLabel: 'Go to Home',
        );
        
      case EmptyStateType.noResults:
        return const _EmptyStateConfig(
          icon: Icons.search_off_outlined,
          iconColor: kTextSecondary,
          backgroundColor: kTextSecondary,
          defaultTitle: 'No Results Found',
          defaultSubtitle: 'Try different keywords or filters',
          defaultActionLabel: 'Clear Search',
        );
        
      case EmptyStateType.noConnection:
        return const _EmptyStateConfig(
          icon: Icons.wifi_off_outlined,
          iconColor: kWarningColor,
          backgroundColor: kWarningColor,
          defaultTitle: 'No Internet Connection',
          defaultSubtitle: 'Please check your connection and try again',
          defaultActionLabel: 'Retry',
        );
        
      case EmptyStateType.error:
        return const _EmptyStateConfig(
          icon: Icons.error_outline,
          iconColor: kErrorColor,
          backgroundColor: kErrorColor,
          defaultTitle: 'Oops! Something Went Wrong',
          defaultSubtitle: 'We couldn\'t load the data. Please try again',
          defaultActionLabel: 'Retry',
        );
        
      case EmptyStateType.networkError:
        return const _EmptyStateConfig(
          icon: Icons.cloud_off_outlined,
          iconColor: kErrorColor,
          backgroundColor: kErrorColor,
          defaultTitle: 'Connection Lost',
          defaultSubtitle: 'Unable to reach the server. Check your network',
          defaultActionLabel: 'Retry',
        );
    }
  }
}

/// Configuration class for empty state appearance
class _EmptyStateConfig {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String defaultTitle;
  final String defaultSubtitle;
  final String defaultActionLabel;

  const _EmptyStateConfig({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.defaultTitle,
    required this.defaultSubtitle,
    required this.defaultActionLabel,
  });
}

/// A compact empty state for inline use (e.g., in tabs or sections)
/// 
/// A smaller version of EmptyState for use in constrained spaces.
class CompactEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color? iconColor;

  const CompactEmptyState({
    Key? key,
    required this.icon,
    required this.message,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final effectiveIconColor = iconColor ?? 
      (isDarkMode ? kTextSecondaryDark : kTextSecondary);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kSpacing2xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: kIconSize2xl,
              color: effectiveIconColor,
            ),
            const SizedBox(height: kSpacingLg),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading state with message
/// 
/// Displays a loading indicator with optional message.
class LoadingState extends StatelessWidget {
  final String? message;
  final Color? color;

  const LoadingState({
    Key? key,
    this.message,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: color ?? kPrimaryColor,
          ),
          if (message != null) ...[
            const SizedBox(height: kSpacingLg),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Error state with retry option
/// 
/// Displays an error message with a retry button.
class ErrorState extends StatelessWidget {
  final String? title;
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const ErrorState({
    Key? key,
    this.title,
    required this.message,
    this.onRetry,
    this.retryLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kSpacing3xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: kIconSize3xl,
              color: kErrorColor,
            ),
            const SizedBox(height: kSpacing2xl),
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: kSpacingMd),
            ],
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: kSpacing2xl),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kErrorColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(retryLabel ?? 'Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

