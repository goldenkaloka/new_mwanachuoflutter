import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/theme/app_theme.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/features/auth/presentation/pages/auth_pages.dart';
import 'package:mwanachuo/features/auth/presentation/pages/signup_university_selection.dart';
import 'package:mwanachuo/features/auth/presentation/pages/become_seller_screen.dart';
import 'package:mwanachuo/features/admin/presentation/pages/seller_requests_page.dart';
import 'package:mwanachuo/features/home/home_page.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_bloc.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_bloc.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_bloc.dart';
import 'package:mwanachuo/features/promotions/presentation/bloc/promotion_cubit.dart';
import 'package:mwanachuo/features/products/presentation/pages/product_details_page.dart';
import 'package:mwanachuo/features/products/presentation/pages/post_product_screen.dart';
import 'package:mwanachuo/features/products/presentation/pages/all_products_page.dart';
import 'package:mwanachuo/features/messages/presentation/pages/messages_page.dart';
import 'package:mwanachuo/features/messages/presentation/pages/chat_screen.dart';
import 'package:mwanachuo/features/profile/presentation/pages/profile_page.dart';
import 'package:mwanachuo/features/profile/presentation/pages/edit_profile_screen.dart';
import 'package:mwanachuo/features/profile/presentation/pages/my_listings_screen.dart';
import 'package:mwanachuo/features/profile/presentation/pages/account_settings_screen.dart';
import 'package:mwanachuo/features/shared/search/presentation/pages/search_results_page.dart';
import 'package:mwanachuo/features/shared/notifications/presentation/pages/notifications_page.dart';
import 'package:mwanachuo/features/dashboard/presentation/pages/seller_dashboard_screen.dart';
import 'package:mwanachuo/features/accommodations/presentation/pages/student_housing_screen.dart';
import 'package:mwanachuo/features/accommodations/presentation/pages/accommodation_detail_page.dart';
import 'package:mwanachuo/features/accommodations/presentation/pages/create_accommodation_screen.dart';
import 'package:mwanachuo/features/services/presentation/pages/services_screen.dart';
import 'package:mwanachuo/features/services/presentation/pages/service_detail_page.dart';
import 'package:mwanachuo/features/services/presentation/pages/create_service_screen.dart';
import 'package:mwanachuo/features/promotions/presentation/pages/create_promotion_screen.dart';
import 'package:mwanachuo/features/promotions/presentation/pages/promotion_detail_page.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/message_bloc.dart';

class MwanachuoshopApp extends StatelessWidget {
  const MwanachuoshopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<AuthBloc>()),
        BlocProvider(create: (context) => sl<MessageBloc>()),
      ],
      child: MaterialApp(
        title: 'Mwanachuoshop',
        debugShowCheckedModeBanner: false,
        theme: lightTheme(),
        themeMode: ThemeMode.light,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/signup': (context) => const CreateAccountScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/signup-university-selection': (context) =>
              const SignupUniversitySelectionScreen(),
          '/become-seller': (context) => const BecomeSellerScreen(),
          '/seller-requests': (context) => const SellerRequestsPage(),
          '/home': (context) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => sl<ProductBloc>()),
              BlocProvider(create: (context) => sl<ServiceBloc>()),
              BlocProvider(create: (context) => sl<AccommodationBloc>()),
              BlocProvider(create: (context) => sl<PromotionCubit>()),
            ],
            child: const HomePage(),
          ),
          '/product-details': (context) => const ProductDetailsPage(),
          '/post-product': (context) => BlocProvider(
            create: (context) => sl<ProductBloc>(),
            child: const PostProductScreen(),
          ),
          '/messages': (context) => BlocProvider.value(
            value: context.read<MessageBloc>(),
            child: const MessagesPage(),
          ),
          '/chat': (context) => BlocProvider.value(
            value: context.read<MessageBloc>(),
            child: const ChatScreen(),
          ),
          '/profile': (context) => const ProfilePage(),
          '/search': (context) {
            final args = ModalRoute.of(context)!.settings.arguments;
            return SearchResultsPage(searchQuery: args is String ? args : null);
          },
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
          '/my-listings': (context) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => sl<ProductBloc>()),
              BlocProvider(create: (context) => sl<ServiceBloc>()),
              BlocProvider(create: (context) => sl<AccommodationBloc>()),
            ],
            child: const MyListingsScreen(),
          ),
          '/dashboard': (context) => const SellerDashboardScreen(),
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
          '/create-service': (context) => BlocProvider(
            create: (context) => sl<ServiceBloc>(),
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
        },
      ),
    );
  }
}
