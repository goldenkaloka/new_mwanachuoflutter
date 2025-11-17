import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mwanachuo/config/supabase_config.dart';
import 'package:mwanachuo/core/network/network_info.dart';
import 'package:mwanachuo/core/services/presence_service.dart';

// Auth
import 'package:mwanachuo/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:mwanachuo/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mwanachuo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mwanachuo/features/auth/domain/repositories/auth_repository.dart';
import 'package:mwanachuo/features/auth/domain/usecases/approve_seller_request.dart';
import 'package:mwanachuo/features/auth/domain/usecases/check_registration_completion.dart';
import 'package:mwanachuo/features/auth/domain/usecases/complete_registration.dart';
import 'package:mwanachuo/features/auth/domain/usecases/get_current_user.dart';
import 'package:mwanachuo/features/auth/domain/usecases/get_seller_request_status.dart';
import 'package:mwanachuo/features/auth/domain/usecases/get_seller_requests.dart';
import 'package:mwanachuo/features/auth/domain/usecases/reject_seller_request.dart';
import 'package:mwanachuo/features/auth/domain/usecases/request_seller_access.dart';
import 'package:mwanachuo/features/auth/domain/usecases/sign_in.dart';
import 'package:mwanachuo/features/auth/domain/usecases/sign_out.dart';
import 'package:mwanachuo/features/auth/domain/usecases/sign_up.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/shared/university/data/datasources/university_local_data_source.dart';
import 'package:mwanachuo/features/shared/university/data/datasources/university_remote_data_source.dart';
import 'package:mwanachuo/features/shared/university/data/repositories/university_repository_impl.dart';
import 'package:mwanachuo/features/shared/university/domain/repositories/university_repository.dart';
import 'package:mwanachuo/features/shared/university/domain/usecases/get_selected_university.dart';
import 'package:mwanachuo/features/shared/university/domain/usecases/get_universities.dart';
import 'package:mwanachuo/features/shared/university/domain/usecases/search_universities.dart';
import 'package:mwanachuo/features/shared/university/domain/usecases/set_selected_university.dart';
import 'package:mwanachuo/features/shared/university/presentation/cubit/university_cubit.dart';
import 'package:mwanachuo/features/shared/media/data/datasources/media_local_data_source.dart';
import 'package:mwanachuo/features/shared/media/data/datasources/media_remote_data_source.dart';
import 'package:mwanachuo/features/shared/media/data/repositories/media_repository_impl.dart';
import 'package:mwanachuo/features/shared/media/domain/repositories/media_repository.dart';
import 'package:mwanachuo/features/shared/media/domain/usecases/delete_image.dart';
import 'package:mwanachuo/features/shared/media/domain/usecases/pick_image.dart';
import 'package:mwanachuo/features/shared/media/domain/usecases/pick_multiple_images.dart';
import 'package:mwanachuo/features/shared/media/domain/usecases/upload_image.dart';
import 'package:mwanachuo/features/shared/media/domain/usecases/upload_multiple_images.dart';
import 'package:mwanachuo/features/shared/media/presentation/cubit/media_cubit.dart';
import 'package:mwanachuo/features/shared/reviews/data/datasources/review_local_data_source.dart';
import 'package:mwanachuo/features/shared/reviews/data/datasources/review_remote_data_source.dart';
import 'package:mwanachuo/features/shared/reviews/data/repositories/review_repository_impl.dart';
import 'package:mwanachuo/features/shared/reviews/domain/repositories/review_repository.dart';
import 'package:mwanachuo/features/shared/reviews/domain/usecases/delete_review.dart';
import 'package:mwanachuo/features/shared/reviews/domain/usecases/get_review_stats.dart';
import 'package:mwanachuo/features/shared/reviews/domain/usecases/get_reviews.dart';
import 'package:mwanachuo/features/shared/reviews/domain/usecases/get_user_review.dart';
import 'package:mwanachuo/features/shared/reviews/domain/usecases/mark_review_helpful.dart';
import 'package:mwanachuo/features/shared/reviews/domain/usecases/submit_review.dart';
import 'package:mwanachuo/features/shared/reviews/domain/usecases/update_review.dart';
import 'package:mwanachuo/features/shared/reviews/presentation/cubit/review_cubit.dart';
import 'package:mwanachuo/features/shared/search/data/datasources/search_local_data_source.dart';
import 'package:mwanachuo/features/shared/search/data/datasources/search_remote_data_source.dart';
import 'package:mwanachuo/features/shared/search/data/repositories/search_repository_impl.dart';
import 'package:mwanachuo/features/shared/search/domain/repositories/search_repository.dart';
import 'package:mwanachuo/features/shared/search/domain/usecases/clear_search_history.dart';
import 'package:mwanachuo/features/shared/search/domain/usecases/get_popular_searches.dart';
import 'package:mwanachuo/features/shared/search/domain/usecases/get_recent_searches.dart';
import 'package:mwanachuo/features/shared/search/domain/usecases/get_search_suggestions.dart';
import 'package:mwanachuo/features/shared/search/domain/usecases/save_search_query.dart';
import 'package:mwanachuo/features/shared/search/domain/usecases/search_content.dart';
import 'package:mwanachuo/features/shared/search/presentation/cubit/search_cubit.dart';
import 'package:mwanachuo/features/shared/notifications/data/datasources/notification_local_data_source.dart';
import 'package:mwanachuo/features/shared/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:mwanachuo/features/shared/notifications/data/repositories/notification_repository_impl.dart';
import 'package:mwanachuo/features/shared/notifications/domain/repositories/notification_repository.dart';
import 'package:mwanachuo/features/shared/notifications/domain/usecases/delete_all_read.dart';
import 'package:mwanachuo/features/shared/notifications/domain/usecases/delete_notification.dart';
import 'package:mwanachuo/features/shared/notifications/domain/usecases/get_notifications.dart';
import 'package:mwanachuo/features/shared/notifications/domain/usecases/get_unread_count.dart';
import 'package:mwanachuo/features/shared/notifications/domain/usecases/mark_all_as_read.dart';
import 'package:mwanachuo/features/shared/notifications/domain/usecases/mark_as_read.dart';
import 'package:mwanachuo/features/shared/notifications/domain/usecases/subscribe_to_notifications.dart';
import 'package:mwanachuo/features/shared/notifications/presentation/cubit/notification_cubit.dart';
import 'package:mwanachuo/features/products/data/datasources/product_local_data_source.dart';
import 'package:mwanachuo/features/products/data/datasources/product_remote_data_source.dart';
import 'package:mwanachuo/features/products/data/repositories/product_repository_impl.dart';
import 'package:mwanachuo/features/products/domain/repositories/product_repository.dart';
import 'package:mwanachuo/features/products/domain/usecases/create_product.dart';
import 'package:mwanachuo/features/products/domain/usecases/delete_product.dart';
import 'package:mwanachuo/features/products/domain/usecases/get_my_products.dart';
import 'package:mwanachuo/features/products/domain/usecases/get_product_by_id.dart';
import 'package:mwanachuo/features/products/domain/usecases/get_products.dart';
import 'package:mwanachuo/features/products/domain/usecases/increment_view_count.dart';
import 'package:mwanachuo/features/products/domain/usecases/update_product.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_bloc.dart';
import 'package:mwanachuo/features/services/data/datasources/service_local_data_source.dart';
import 'package:mwanachuo/features/services/data/datasources/service_remote_data_source.dart';
import 'package:mwanachuo/features/services/data/repositories/service_repository_impl.dart';
import 'package:mwanachuo/features/services/domain/repositories/service_repository.dart';
import 'package:mwanachuo/features/services/domain/usecases/create_service.dart';
import 'package:mwanachuo/features/services/domain/usecases/delete_service.dart';
import 'package:mwanachuo/features/services/domain/usecases/get_my_services.dart';
import 'package:mwanachuo/features/services/domain/usecases/get_service_by_id.dart';
import 'package:mwanachuo/features/services/domain/usecases/get_services.dart';
import 'package:mwanachuo/features/services/domain/usecases/update_service.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_bloc.dart';
import 'package:mwanachuo/features/accommodations/data/datasources/accommodation_remote_data_source.dart';
import 'package:mwanachuo/features/accommodations/data/repositories/accommodation_repository_impl.dart';
import 'package:mwanachuo/features/accommodations/domain/repositories/accommodation_repository.dart';
import 'package:mwanachuo/features/accommodations/domain/usecases/create_accommodation.dart';
import 'package:mwanachuo/features/accommodations/domain/usecases/get_accommodations.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_bloc.dart';
import 'package:mwanachuo/features/messages/data/datasources/message_remote_data_source.dart';
import 'package:mwanachuo/features/messages/data/datasources/message_local_data_source.dart';
import 'package:mwanachuo/features/messages/data/repositories/message_repository_impl.dart';
import 'package:mwanachuo/features/messages/domain/repositories/message_repository.dart';
import 'package:mwanachuo/features/messages/domain/usecases/get_conversations.dart';
import 'package:mwanachuo/features/messages/domain/usecases/get_messages.dart';
import 'package:mwanachuo/features/messages/domain/usecases/get_or_create_conversation.dart';
import 'package:mwanachuo/features/messages/domain/usecases/send_message.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/message_bloc.dart';
import 'package:mwanachuo/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:mwanachuo/features/profile/data/datasources/profile_local_data_source.dart';
import 'package:mwanachuo/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:mwanachuo/features/profile/domain/repositories/profile_repository.dart';
import 'package:mwanachuo/features/profile/domain/usecases/get_my_profile.dart';
import 'package:mwanachuo/features/profile/domain/usecases/update_profile.dart';
import 'package:mwanachuo/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:mwanachuo/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:mwanachuo/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:mwanachuo/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:mwanachuo/features/dashboard/domain/usecases/get_dashboard_stats.dart';
import 'package:mwanachuo/features/dashboard/presentation/bloc/dashboard_cubit.dart';
import 'package:mwanachuo/features/promotions/data/datasources/promotion_remote_data_source.dart';
import 'package:mwanachuo/features/promotions/data/repositories/promotion_repository_impl.dart';
import 'package:mwanachuo/features/promotions/domain/repositories/promotion_repository.dart';
import 'package:mwanachuo/features/promotions/domain/usecases/get_active_promotions.dart';
import 'package:mwanachuo/features/promotions/presentation/bloc/promotion_cubit.dart';
import 'package:uuid/uuid.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // ============================================================================
  // External Dependencies
  // ============================================================================
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  
  sl.registerLazySingleton(() => Connectivity());
  
  sl.registerLazySingleton(() => SupabaseConfig.client);
  
  // ============================================================================
  // Core
  // ============================================================================
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl()),
  );
  
  sl.registerLazySingleton(() => PresenceService(sl()));
  
  // ============================================================================
  // SHARED FEATURES
  // ============================================================================
  await _initUniversityFeature();
  await _initMediaFeature();
  await _initReviewsFeature();
  await _initSearchFeature();
  await _initNotificationsFeature();

  // ============================================================================
  // STANDALONE FEATURES
  // ============================================================================
  await _initProductsFeature();
  await _initServicesFeature();
  await _initAccommodationsFeature();
  await _initMessagesFeature();
  await _initProfileFeature();
  await _initDashboardFeature();
  await _initPromotionsFeature();

  // ============================================================================
  // Features - Authentication
  // ============================================================================
  
  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );
  
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sl()),
  );
  
  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  
  // Use cases
  sl.registerLazySingleton(() => SignIn(sl()));
  sl.registerLazySingleton(() => SignUp(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => RequestSellerAccess(sl()));
  sl.registerLazySingleton(() => ApproveSellerRequest(sl()));
  sl.registerLazySingleton(() => RejectSellerRequest(sl()));
  sl.registerLazySingleton(() => GetSellerRequests(sl()));
  sl.registerLazySingleton(() => CompleteRegistration(sl()));
  sl.registerLazySingleton(() => CheckRegistrationCompletion(sl()));
  sl.registerLazySingleton(() => GetSellerRequestStatus(sl()));
  
  // BLoC
  sl.registerFactory(
    () => AuthBloc(
      signIn: sl(),
      signUp: sl(),
      signOut: sl(),
      getCurrentUser: sl(),
      requestSellerAccess: sl(),
      approveSellerRequest: sl(),
      rejectSellerRequest: sl(),
      getSellerRequests: sl(),
      completeRegistration: sl(),
      checkRegistrationCompletion: sl(),
      getSellerRequestStatus: sl(),
    ),
  );
}

// ============================================
// UNIVERSITY FEATURE (SHARED)
// ============================================
Future<void> _initUniversityFeature() async {
  // Use Cases
  sl.registerLazySingleton(
    () => GetUniversities(sl()),
  );
  sl.registerLazySingleton(
    () => GetSelectedUniversity(sl()),
  );
  sl.registerLazySingleton(
    () => SetSelectedUniversity(sl()),
  );
  sl.registerLazySingleton(
    () => SearchUniversities(sl()),
  );

  // Repository
  sl.registerLazySingleton<UniversityRepository>(
    () => UniversityRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<UniversityRemoteDataSource>(
    () => UniversityRemoteDataSourceImpl(
      supabaseClient: sl(),
    ),
  );
  sl.registerLazySingleton<UniversityLocalDataSource>(
    () => UniversityLocalDataSourceImpl(
      sharedPreferences: sl(),
    ),
  );

  // Cubit
  sl.registerFactory(
    () => UniversityCubit(
      getUniversities: sl(),
      getSelectedUniversity: sl(),
      setSelectedUniversity: sl(),
      searchUniversities: sl(),
    ),
  );
}

// ============================================
// MEDIA FEATURE (SHARED)
// ============================================
Future<void> _initMediaFeature() async {
  // External (UUID for unique file names)
  sl.registerLazySingleton(() => const Uuid());

  // Use Cases
  sl.registerLazySingleton(() => PickImage(sl()));
  sl.registerLazySingleton(() => PickMultipleImages(sl()));
  sl.registerLazySingleton(() => UploadImage(sl()));
  sl.registerLazySingleton(() => UploadMultipleImages(sl()));
  sl.registerLazySingleton(() => DeleteImage(sl()));

  // Repository
  sl.registerLazySingleton<MediaRepository>(
    () => MediaRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<MediaRemoteDataSource>(
    () => MediaRemoteDataSourceImpl(
      supabaseClient: sl(),
      uuid: sl(),
    ),
  );
  sl.registerLazySingleton<MediaLocalDataSource>(
    () => MediaLocalDataSourceImpl(),
  );

  // Cubit
  sl.registerFactory(
    () => MediaCubit(
      pickImage: sl(),
      pickMultipleImages: sl(),
      uploadImage: sl(),
      uploadMultipleImages: sl(),
      deleteImage: sl(),
    ),
  );
}

// ============================================
// REVIEWS FEATURE (SHARED)
// ============================================
Future<void> _initReviewsFeature() async {
  // Use Cases
  sl.registerLazySingleton(() => GetReviews(sl()));
  sl.registerLazySingleton(() => GetReviewStats(sl()));
  sl.registerLazySingleton(() => SubmitReview(sl()));
  sl.registerLazySingleton(() => UpdateReview(sl()));
  sl.registerLazySingleton(() => DeleteReview(sl()));
  sl.registerLazySingleton(() => MarkReviewHelpful(sl()));
  sl.registerLazySingleton(() => GetUserReview(sl()));

  // Repository
  sl.registerLazySingleton<ReviewRepository>(
    () => ReviewRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<ReviewRemoteDataSource>(
    () => ReviewRemoteDataSourceImpl(
      supabaseClient: sl(),
    ),
  );
  sl.registerLazySingleton<ReviewLocalDataSource>(
    () => ReviewLocalDataSourceImpl(
      sharedPreferences: sl(),
    ),
  );

  // Cubit
  sl.registerFactory(
    () => ReviewCubit(
      getReviews: sl(),
      getReviewStats: sl(),
      submitReview: sl(),
      updateReview: sl(),
      deleteReview: sl(),
      markReviewHelpful: sl(),
      getUserReview: sl(),
    ),
  );
}

// ============================================
// SEARCH FEATURE (SHARED)
// ============================================
Future<void> _initSearchFeature() async {
  // Use Cases
  sl.registerLazySingleton(() => SearchContent(sl()));
  sl.registerLazySingleton(() => GetSearchSuggestions(sl()));
  sl.registerLazySingleton(() => GetRecentSearches(sl()));
  sl.registerLazySingleton(() => SaveSearchQuery(sl()));
  sl.registerLazySingleton(() => ClearSearchHistory(sl()));
  sl.registerLazySingleton(() => GetPopularSearches(sl()));

  // Repository
  sl.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<SearchRemoteDataSource>(
    () => SearchRemoteDataSourceImpl(
      supabaseClient: sl(),
    ),
  );
  sl.registerLazySingleton<SearchLocalDataSource>(
    () => SearchLocalDataSourceImpl(
      sharedPreferences: sl(),
    ),
  );

  // Cubit
  sl.registerFactory(
    () => SearchCubit(
      searchContent: sl(),
      getSearchSuggestions: sl(),
      getRecentSearches: sl(),
      saveSearchQuery: sl(),
      clearSearchHistory: sl(),
      getPopularSearches: sl(),
    ),
  );
}

// ============================================
// NOTIFICATIONS FEATURE (SHARED)
// ============================================
Future<void> _initNotificationsFeature() async {
  // Use Cases
  sl.registerLazySingleton(() => GetNotifications(sl()));
  sl.registerLazySingleton(() => GetUnreadCount(sl()));
  sl.registerLazySingleton(() => MarkAsRead(sl()));
  sl.registerLazySingleton(() => MarkAllAsRead(sl()));
  sl.registerLazySingleton(() => DeleteNotification(sl()));
  sl.registerLazySingleton(() => DeleteAllRead(sl()));
  sl.registerLazySingleton(() => SubscribeToNotifications(sl()));

  // Repository
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(
      supabaseClient: sl(),
    ),
  );
  sl.registerLazySingleton<NotificationLocalDataSource>(
    () => NotificationLocalDataSourceImpl(
      sharedPreferences: sl(),
    ),
  );

  // Cubit
  sl.registerFactory(
    () => NotificationCubit(
      getNotifications: sl(),
      getUnreadCount: sl(),
      markAsRead: sl(),
      markAllAsRead: sl(),
      deleteNotification: sl(),
      deleteAllRead: sl(),
      subscribeToNotifications: sl(),
    ),
  );
}

// ============================================
// PRODUCTS FEATURE (STANDALONE)
// ============================================
Future<void> _initProductsFeature() async {
  // Use Cases
  sl.registerLazySingleton(() => GetProducts(sl()));
  sl.registerLazySingleton(() => GetProductById(sl()));
  sl.registerLazySingleton(() => GetMyProducts(sl()));
  sl.registerLazySingleton(() => CreateProduct(sl()));
  sl.registerLazySingleton(() => UpdateProduct(sl()));
  sl.registerLazySingleton(() => DeleteProduct(sl()));
  sl.registerLazySingleton(() => IncrementViewCount(sl()));

  // Repository
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      uploadImages: sl(), // From Media feature
    ),
  );

  // Data Sources
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(
      supabaseClient: sl(),
    ),
  );
  sl.registerLazySingleton<ProductLocalDataSource>(
    () => ProductLocalDataSourceImpl(
      sharedPreferences: sl(),
    ),
  );

  // BLoC
  sl.registerFactory(
    () => ProductBloc(
      getProducts: sl(),
      getProductById: sl(),
      getMyProducts: sl(),
      createProduct: sl(),
      updateProduct: sl(),
      deleteProduct: sl(),
      incrementViewCount: sl(),
    ),
  );
}

// ============================================
// SERVICES FEATURE (STANDALONE)
// ============================================
Future<void> _initServicesFeature() async {
  // Use Cases
  sl.registerLazySingleton(() => GetServices(sl()));
  sl.registerLazySingleton(() => GetServiceById(sl()));
  sl.registerLazySingleton(() => GetMyServices(sl()));
  sl.registerLazySingleton(() => CreateService(sl()));
  sl.registerLazySingleton(() => UpdateService(sl()));
  sl.registerLazySingleton(() => DeleteService(sl()));

  // Repository
  sl.registerLazySingleton<ServiceRepository>(
    () => ServiceRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      uploadImages: sl(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<ServiceRemoteDataSource>(
    () => ServiceRemoteDataSourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<ServiceLocalDataSource>(
    () => ServiceLocalDataSourceImpl(sharedPreferences: sl()),
  );

  // BLoC
  sl.registerFactory(
    () => ServiceBloc(
      getServices: sl(),
      getServiceById: sl(),
      getMyServices: sl(),
      createService: sl(),
      updateService: sl(),
      deleteService: sl(),
    ),
  );
}

// ============================================
// ACCOMMODATIONS FEATURE (STANDALONE)
// ============================================
Future<void> _initAccommodationsFeature() async {
  // Use Cases
  sl.registerLazySingleton(() => GetAccommodations(sl()));
  sl.registerLazySingleton(() => CreateAccommodation(sl()));

  // Repository
  sl.registerLazySingleton<AccommodationRepository>(
    () => AccommodationRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
      uploadImages: sl(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<AccommodationRemoteDataSource>(
    () => AccommodationRemoteDataSourceImpl(supabaseClient: sl()),
  );

  // BLoC
  sl.registerFactory(
    () => AccommodationBloc(
      getAccommodations: sl(),
      createAccommodation: sl(),
    ),
  );
}

// ============================================
// MESSAGES FEATURE (STANDALONE)
// ============================================
Future<void> _initMessagesFeature() async {
  sl.registerLazySingleton(() => GetConversations(sl()));
  sl.registerLazySingleton(() => GetOrCreateConversation(sl()));
  sl.registerLazySingleton(() => GetMessages(sl()));
  sl.registerLazySingleton(() => SendMessage(sl()));

  sl.registerLazySingleton<MessageRepository>(
    () => MessageRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      sharedPreferences: sl(),
    ),
  );

  sl.registerLazySingleton<MessageRemoteDataSource>(
    () => MessageRemoteDataSourceImpl(supabaseClient: sl()),
  );

  sl.registerLazySingleton<MessageLocalDataSource>(
    () => MessageLocalDataSourceImpl(sharedPreferences: sl()),
  );

  sl.registerFactory(
    () => MessageBloc(
      getConversations: sl(),
      getOrCreateConversation: sl(),
      getMessages: sl(),
      sendMessage: sl(),
      messageRepository: sl(),
      sharedPreferences: sl(),
    ),
  );
}

// ============================================
// PROFILE FEATURE (STANDALONE)
// ============================================
Future<void> _initProfileFeature() async {
  sl.registerLazySingleton(() => GetMyProfile(sl()));
  sl.registerLazySingleton(() => UpdateProfile(sl()));

  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      uploadImage: sl(),
      sharedPreferences: sl(),
    ),
  );

  sl.registerLazySingleton<ProfileLocalDataSource>(
    () => ProfileLocalDataSourceImpl(sharedPreferences: sl()),
  );

  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(supabaseClient: sl()),
  );

  sl.registerFactory(() => ProfileBloc(getMyProfile: sl(), updateProfile: sl()));
}

// ============================================
// DASHBOARD FEATURE (STANDALONE)
// ============================================
Future<void> _initDashboardFeature() async {
  sl.registerLazySingleton(() => GetDashboardStats(sl()));

  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSourceImpl(supabaseClient: sl()),
  );

  sl.registerFactory(() => DashboardCubit(getDashboardStats: sl()));
}

// ============================================
// PROMOTIONS FEATURE (STANDALONE)
// ============================================
Future<void> _initPromotionsFeature() async {
  sl.registerLazySingleton(() => GetActivePromotions(sl()));

  sl.registerLazySingleton<PromotionRepository>(
    () => PromotionRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
      uploadImage: sl(),
    ),
  );

  sl.registerLazySingleton<PromotionRemoteDataSource>(
    () => PromotionRemoteDataSourceImpl(supabaseClient: sl()),
  );

  sl.registerFactory(() => PromotionCubit(getActivePromotions: sl()));
}

