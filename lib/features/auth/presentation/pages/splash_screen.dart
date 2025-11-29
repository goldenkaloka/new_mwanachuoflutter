import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/services/push_notification_service.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_event.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';
import 'package:mwanachuo/config/supabase_config.dart';
import 'package:mwanachuo/core/middleware/subscription_middleware.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasCheckedRegistration = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // Check authentication status after splash delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.read<AuthBloc>().add(const CheckAuthStatusEvent());
      }
    });
  }

  void _handleAuthState(BuildContext context, AuthState state) {
    if (_hasNavigated) return; // Prevent multiple navigations

    if (state is Authenticated) {
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
      // User is not authenticated, go to onboarding
      debugPrint('👤 No user authenticated, going to onboarding');
      Navigator.of(context).pushReplacementNamed('/onboarding');
    } else if (state is RegistrationIncomplete) {
      if (_hasNavigated) return;
      _hasNavigated = true;
      // Account created but needs university selection
      debugPrint(
        '⚠️ Registration incomplete, redirecting to university selection',
      );
      Navigator.of(
        context,
      ).pushReplacementNamed('/signup-university-selection');
    } else if (state is RegistrationCheckCompleted) {
      if (_hasNavigated) return;
      _hasNavigated = true;

      if (state.isCompleted) {
        // Registration complete with universities, go to home
        debugPrint('✅ Registration complete, going to home');
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // Registration incomplete, go to university selection
        debugPrint(
          '⚠️ Registration incomplete, redirecting to university selection',
        );
        Navigator.of(
          context,
        ).pushReplacementNamed('/signup-university-selection');
      }
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
      child: _buildSplashUI(context),
    );
  }

  Widget _buildSplashUI(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 112,
              height: 112,
              margin: const EdgeInsets.only(bottom: 24.0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: kBaseRadius,
              ),
              child: const Icon(
                Icons.shopping_bag,
                color: Colors.white,
                size: 64,
              ),
            ),
            Text(
              'Mwanachuoshop',
              style: GoogleFonts.plusJakartaSans(
                color: kBackgroundColorDark,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Your Campus Marketplace',
                style: GoogleFonts.plusJakartaSans(
                  color: kBackgroundColorDark.withValues(alpha: 0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 32.0, left: 32.0, right: 32.0),
        child: SizedBox(
          width: double.infinity,
          height: 6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: 0.4,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(
                kBackgroundColorDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
