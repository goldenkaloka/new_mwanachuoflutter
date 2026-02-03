import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:mwanachuo/core/services/push_notification_service.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_event.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';
import 'package:mwanachuo/config/supabase_config.dart';
import 'package:mwanachuo/core/middleware/subscription_middleware.dart';

/// Lightweight initial route handler that immediately checks auth
/// and navigates without showing a splash screen
class InitialRouteHandler extends StatefulWidget {
  const InitialRouteHandler({super.key});

  @override
  State<InitialRouteHandler> createState() => _InitialRouteHandlerState();
}

class _InitialRouteHandlerState extends State<InitialRouteHandler> {
  bool _hasCheckedRegistration = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // Immediately check authentication status (no delay)
    // Remove splash screen as soon as the first frame is rendered
    // to show either the loading spinner or the target page immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FlutterNativeSplash.remove();
        context.read<AuthBloc>().add(const CheckAuthStatusEvent());
      }
    });
  }

  void _handleAuthState(BuildContext context, AuthState state) {
    if (_hasNavigated) return; // Prevent multiple navigations

    if (state is Authenticated) {
      // Ensure splash is removed if we're authenticated
      FlutterNativeSplash.remove();

      // Register device token for push notifications
      PushNotificationService().registerDeviceTokenForUser(state.user.id);

      // Pre-check subscription status in background for seamless flow
      _preCheckSubscription(state.user.id);

      // Check if registration is completed using BLoC (only once)
      if (!_hasCheckedRegistration) {
        _hasCheckedRegistration = true;
        debugPrint(
          '🔍 User authenticated, checking registration completion...',
        );
        context.read<AuthBloc>().add(const CheckRegistrationCompletionEvent());
      }
    } else if (state is Unauthenticated) {
      if (_hasNavigated) return;
      _hasNavigated = true;
      // Remove native splash before navigation
      FlutterNativeSplash.remove();
      // User is not authenticated, go to onboarding
      debugPrint('👤 No user authenticated, going to onboarding');
      Navigator.of(context).pushReplacementNamed('/onboarding');
    } else if (state is RegistrationCheckCompleted) {
      if (_hasNavigated) return;
      _hasNavigated = true;
      // Remove native splash before navigation
      FlutterNativeSplash.remove();

      // Registration is always complete now, go to home
      debugPrint('✅ Registration complete, going to home');
      // Restore Authenticated state so the rest of the app can access user data
      context.read<AuthBloc>().add(const CheckAuthStatusEvent());
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (state is AuthError) {
      if (_hasNavigated) return;
      _hasNavigated = true;
      // Remove native splash before navigation
      FlutterNativeSplash.remove();
      // On error during startup (e.g. invalid refresh token), logout/onboarding
      debugPrint('❌ Auth error during startup: ${state.message}');
      Navigator.of(context).pushReplacementNamed('/onboarding');
    }
  }

  Future<void> _preCheckSubscription(String userId) async {
    // Pre-check subscription in background to cache result
    try {
      final userData = await SupabaseConfig.client
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();

      final role = userData['role'] as String?;
      final isSeller = role == 'seller' || role == 'admin';

      if (isSeller) {
        // Pre-check and cache subscription status
        SubscriptionMiddleware.canAccessMessages(sellerId: userId);
      }
    } catch (e) {
      // Ignore errors - will check when needed
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check initial state immediately (handles hot restart)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasNavigated) return;
      final currentState = context.read<AuthBloc>().state;
      _handleAuthState(context, currentState);
    });

    return BlocListener<AuthBloc, AuthState>(
      listener: _handleAuthState,
      // Show a minimal loading indicator while checking auth
      child: const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
