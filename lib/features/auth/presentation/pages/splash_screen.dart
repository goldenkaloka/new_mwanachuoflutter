import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_event.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // Check if registration is completed using BLoC
          debugPrint(
            '🔍 User authenticated, checking registration completion...',
          );
          context.read<AuthBloc>().add(
            const CheckRegistrationCompletionEvent(),
          );
        } else if (state is Unauthenticated) {
          // User is not authenticated, go to onboarding
          debugPrint('👤 No user authenticated, going to onboarding');
          Navigator.of(context).pushReplacementNamed('/onboarding');
        } else if (state is RegistrationIncomplete) {
          // Account created but needs university selection
          debugPrint(
            '⚠️ Registration incomplete, redirecting to university selection',
          );
          Navigator.of(
            context,
          ).pushReplacementNamed('/signup-university-selection');
        } else if (state is RegistrationCheckCompleted) {
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

        // AuthLoading and AuthInitial states don't navigate yet
      },
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
