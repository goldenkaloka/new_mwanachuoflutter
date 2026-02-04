import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/features/profile/presentation/bloc/profile_bloc.dart';

import 'package:mwanachuo/config/onesignal_config.dart';

import 'package:mwanachuo/core/theme/app_theme.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/features/auth/presentation/pages/auth_pages.dart';
import 'package:mwanachuo/features/auth/presentation/pages/initial_route_handler.dart';

import 'package:mwanachuo/features/admin/presentation/pages/admin_course_list_page.dart';
import 'package:mwanachuo/features/home/home_page.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_bloc.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_bloc.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_bloc.dart';
import 'package:mwanachuo/features/promotions/presentation/bloc/promotion_cubit.dart';
import 'package:mwanachuo/features/products/presentation/pages/product_details_page.dart';
import 'package:mwanachuo/features/products/presentation/pages/post_product_screen.dart';
import 'package:mwanachuo/features/products/presentation/pages/all_products_page.dart';

import 'package:mwanachuo/features/profile/presentation/pages/profile_page.dart';
import 'package:mwanachuo/features/profile/presentation/pages/edit_profile_screen.dart';
import 'package:mwanachuo/features/profile/presentation/pages/my_listings_screen.dart';
import 'package:mwanachuo/features/profile/presentation/pages/account_settings_screen.dart';
import 'package:mwanachuo/features/shared/listings/presentation/pages/listings_page.dart';
import 'package:mwanachuo/features/shared/search/presentation/pages/search_results_page.dart';
import 'package:mwanachuo/features/shared/search/presentation/cubit/search_cubit.dart';
import 'package:mwanachuo/features/shared/categories/presentation/cubit/category_cubit.dart';
import 'package:mwanachuo/features/shared/notifications/presentation/pages/notifications_page.dart';
import 'package:mwanachuo/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:mwanachuo/features/wallet/presentation/pages/wallet_page.dart';
import 'package:mwanachuo/features/wallet/presentation/bloc/wallet_bloc.dart';
// ... (Logic to skip other imports if using replace_file_content for import replacement is complex, I will just do exact match replace for import line and separate for route)

// Wait, I can use multi_replace for main_app.dart or just replace_file_content if usage and import are close? No they are far.
// I will use multi_replace.
import 'package:mwanachuo/features/accommodations/presentation/pages/student_housing_screen.dart';
import 'package:mwanachuo/features/accommodations/presentation/pages/accommodation_detail_page.dart';
import 'package:mwanachuo/features/accommodations/presentation/pages/create_accommodation_screen.dart';
import 'package:mwanachuo/features/services/presentation/pages/services_screen.dart';
import 'package:mwanachuo/features/services/presentation/pages/service_detail_page.dart';
import 'package:mwanachuo/features/services/presentation/pages/create_service_screen.dart';
import 'package:mwanachuo/features/promotions/presentation/pages/create_promotion_screen.dart';
import 'package:mwanachuo/features/promotions/presentation/pages/promotion_detail_page.dart';
import 'package:mwanachuo/features/copilot/presentation/pages/copilot_wrapper_page.dart';
import 'package:mwanachuo/features/copilot/presentation/pages/copilot_library_page.dart';
import 'package:mwanachuo/features/copilot/presentation/pages/copilot_document_viewer_page.dart';
import 'package:mwanachuo/features/copilot/presentation/pages/copilot_upload_page.dart';
import 'package:mwanachuo/features/copilot/presentation/pages/copilot_chat_page.dart';
import 'package:mwanachuo/features/copilot/presentation/bloc/copilot_bloc.dart';
import 'package:mwanachuo/features/shared/notifications/presentation/pages/notification_settings_screen.dart';
import 'package:mwanachuo/features/subscriptions/presentation/pages/subscription_plans_page.dart';
import 'package:mwanachuo/features/subscriptions/presentation/cubit/subscription_cubit.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';

import 'package:mwanachuo/core/widgets/persistent_bottom_nav_wrapper.dart';

import 'package:app_links/app_links.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class MwanachuoshopApp extends StatefulWidget {
  const MwanachuoshopApp({super.key});

  @override
  State<MwanachuoshopApp> createState() => _MwanachuoshopAppState();
}

class _MwanachuoshopAppState extends State<MwanachuoshopApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();

    // Set navigator key for OneSignal in-app notifications
    OneSignalConfig.navigatorKey = navigatorKey;

    // Initialize plugins in background so they don't block app startup
    _initializePlugins();

    // Check for pending notification data on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handlePendingNotification();
      if (_appLinks != null) {
        _initDeepLinks();
      }
    });
  }

  Future<void> _initializePlugins() async {
    // AppLinks only works on mobile platforms (iOS/Android)
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        _appLinks = AppLinks();
        if (_appLinks != null) {
          _initDeepLinks();
        }
      } catch (e) {
        debugPrint('AppLinks initialization failed: $e');
      }

      // Initialize OneSignal
      try {
        await OneSignalConfig.initialize();
      } catch (e) {
        debugPrint('OneSignal initialization failed: $e');
      }
    }
  }

  void _initDeepLinks() {
    if (_appLinks == null) return;

    try {
      // Handle initial link (when app is opened from a deep link)
      _appLinks!
          .getInitialLink()
          .then((uri) {
            if (uri != null) {
              _handleDeepLink(uri);
            }
          })
          .catchError((err) {
            debugPrint('Error getting initial deep link: $err');
          });

      // Listen for deep links while app is running
      _linkSubscription = _appLinks!.uriLinkStream.listen(
        (uri) => _handleDeepLink(uri),
        onError: (err) => debugPrint('Deep link error: $err'),
      );
    } catch (e) {
      debugPrint('Error initializing deep links: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Deep link received: $uri');

    if (uri.scheme != 'mwanachuo') {
      return;
    }

    // Stripe deep link handling removed
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _handlePendingNotification() {
    final notificationData = OneSignalConfig.getPendingNotificationData();
    if (notificationData != null) {
      _navigateFromNotification(notificationData);
    }
  }

  void _navigateFromNotification(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final actionUrl = data['actionUrl'] as String?;
    final notificationData = data['data'] as Map<String, dynamic>?;

    if (type == null) return;

    switch (type) {
      case 'review':
        final itemId = notificationData?['itemId'] as String?;
        final itemType = notificationData?['itemType'] as String?;
        if (itemId != null &&
            itemType != null &&
            navigatorKey.currentContext != null) {
          if (itemType == 'product') {
            Navigator.of(
              navigatorKey.currentContext!,
            ).pushNamed('/product-details', arguments: {'productId': itemId});
          } else if (itemType == 'service') {
            Navigator.of(
              navigatorKey.currentContext!,
            ).pushNamed('/service-details', arguments: {'serviceId': itemId});
          } else if (itemType == 'accommodation') {
            Navigator.of(navigatorKey.currentContext!).pushNamed(
              '/accommodation-details',
              arguments: {'accommodationId': itemId},
            );
          }
        }
        break;
      case 'promotion':
        final promotionId = notificationData?['promotionId'] as String?;
        if (promotionId != null && navigatorKey.currentContext != null) {
          Navigator.of(navigatorKey.currentContext!).pushNamed(
            '/promotion-details',
            arguments: {'promotionId': promotionId},
          );
        }
        break;
      case 'sellerRequest':
      case 'productApproval':
        if (navigatorKey.currentContext != null) {
          Navigator.of(navigatorKey.currentContext!).pushNamed('/dashboard');
        }
        break;
      default:
        // For other types, try to use actionUrl if available
        if (actionUrl != null && navigatorKey.currentContext != null) {
          // Parse actionUrl and navigate accordingly
          // This is a simple implementation - you may want to use a proper router
          debugPrint('Notification actionUrl: $actionUrl');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<AuthBloc>()),
        BlocProvider(create: (context) => sl<ProfileBloc>()),
        BlocProvider(create: (context) => sl<PromotionCubit>()),
        BlocProvider(
          create: (context) => sl<WalletBloc>()..add(LoadWalletData()),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Mwanachuoshop',
        debugShowCheckedModeBanner: false,
        theme: lightTheme(),
        themeMode: ThemeMode.light,
        home: const InitialRouteHandler(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/signup': (context) => const CreateAccountScreen(),
          '/onboarding': (context) => const OnboardingScreen(),

          '/admin-courses': (context) => const AdminCourseListPage(),
          '/home': (context) => PersistentBottomNavWrapper(
            initialIndex: 0,
            child: MultiBlocProvider(
              providers: [
                BlocProvider(create: (context) => sl<ProductBloc>()),
                BlocProvider(create: (context) => sl<ServiceBloc>()),
                BlocProvider(create: (context) => sl<AccommodationBloc>()),
              ],
              child: const HomePage(),
            ),
          ),
          '/product-details': (context) => const ProductDetailsPage(),
          '/post-product': (context) => BlocProvider(
            create: (context) => sl<ProductBloc>(),
            child: const PostProductScreen(),
          ),

          '/profile': (context) => PersistentBottomNavWrapper(
            initialIndex: 4,
            child: const ProfilePage(),
          ),
          '/search': (context) {
            final args = ModalRoute.of(context)!.settings.arguments;
            return PersistentBottomNavWrapper(
              initialIndex: 1,
              child: SearchResultsPage(
                searchQuery: args is String ? args : null,
              ),
            );
          },
          '/listings': (context) => PersistentBottomNavWrapper(
            initialIndex: 1,
            child: BlocProvider(
              create: (context) => sl<SearchCubit>(),
              child: const ListingsPage(),
            ),
          ),
          '/browse-listings': (context) => PersistentBottomNavWrapper(
            initialIndex: 1,
            child: BlocProvider(
              create: (context) => sl<SearchCubit>(),
              child: const ListingsPage(),
            ),
          ),
          '/university-selection': (context) {
            final args = ModalRoute.of(context)!.settings.arguments;
            return UniversitySelectionScreen(
              selectedUniversity: args is Map
                  ? args['selectedUniversity'] as String?
                  : null,
              isFromOnboarding: args is Map
                  ? (args['isFromOnboarding'] as bool?) ?? false
                  : false,
            );
          },
          '/account-settings': (context) => const AccountSettingsScreen(),
          '/edit-profile': (context) => const EditProfileScreen(),
          '/become-seller': (context) => const SubscriptionPlansPage(),
          '/my-listings': (context) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => sl<ProductBloc>()),
              BlocProvider(create: (context) => sl<ServiceBloc>()),
              BlocProvider(create: (context) => sl<AccommodationBloc>()),
            ],
            child: const MyListingsScreen(),
          ),
          '/dashboard': (context) => PersistentBottomNavWrapper(
            initialIndex: 3,
            child: const DashboardScreen(),
          ),
          '/wallet': (context) => const WalletPage(),
          '/student-housing': (context) => BlocProvider(
            create: (context) => sl<AccommodationBloc>(),
            child: const StudentHousingScreen(),
          ),
          '/services': (context) => BlocProvider(
            create: (context) => sl<ServiceBloc>(),
            child: const ServicesScreen(),
          ),
          '/create-promotion': (context) => BlocProvider(
            create: (context) => sl<PromotionCubit>(),
            child: const CreatePromotionScreen(),
          ),
          '/create-service': (context) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => sl<ServiceBloc>()),
              BlocProvider(
                create: (context) =>
                    sl<CategoryCubit>()..loadServiceCategories(),
              ),
            ],
            child: const CreateServiceScreen(),
          ),
          '/create-accommodation': (context) => BlocProvider(
            create: (context) => sl<AccommodationBloc>(),
            child: const CreateAccommodationScreen(),
          ),
          '/notifications': (context) => const NotificationsPage(),
          '/promotion-details': (context) => const PromotionDetailPage(),
          '/service-details': (context) => const ServiceDetailPage(),
          '/accommodation-details': (context) =>
              const AccommodationDetailPage(),
          '/all-products': (context) => BlocProvider(
            create: (context) => sl<ProductBloc>(),
            child: const AllProductsPage(),
          ),
          '/notification-settings': (context) =>
              const NotificationSettingsScreen(),
          '/subscription-plans': (context) => BlocProvider(
            create: (context) => sl<SubscriptionCubit>(),
            child: const SubscriptionPlansPage(),
          ),
          '/copilot': (context) => PersistentBottomNavWrapper(
            initialIndex: 2,
            child: const CopilotWrapperPage(),
          ),
          '/copilot-library': (context) {
            final args =
                ModalRoute.of(context)!.settings.arguments
                    as Map<String, dynamic>;
            return BlocProvider(
              create: (context) => sl<CopilotBloc>(),
              child: CopilotLibraryPage(
                courseId: args['courseId'],
                initialSearchQuery: args['initialSearchQuery'],
              ),
            );
          },
          '/copilot-viewer': (context) {
            final args =
                ModalRoute.of(context)!.settings.arguments
                    as Map<String, dynamic>;
            return BlocProvider(
              create: (context) => sl<CopilotBloc>(),
              child: CopilotDocumentViewerPage(
                noteId: args['noteId'],
                courseId: args['courseId'],
              ),
            );
          },
          '/copilot-upload': (context) {
            final args =
                ModalRoute.of(context)!.settings.arguments
                    as Map<String, dynamic>;
            return BlocProvider(
              create: (context) => sl<CopilotBloc>(),
              child: CopilotUploadPage(courseId: args['courseId']),
            );
          },
          '/copilot-chat': (context) {
            final args =
                ModalRoute.of(context)!.settings.arguments
                    as Map<String, dynamic>;
            return BlocProvider(
              create: (context) => sl<CopilotBloc>(),
              child: CopilotChatPage(
                courseId: args['courseId'],
                initialQuery: args['initialQuery'],
                noteId: args['noteId'],
              ),
            );
          },
        },
      ),
    );
  }
}
