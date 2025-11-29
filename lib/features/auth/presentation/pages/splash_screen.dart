import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:lottie/lottie.dart';
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
      // Remove native splash before navigation
      FlutterNativeSplash.remove();
      // User is not authenticated, go to onboarding
      debugPrint('👤 No user authenticated, going to onboarding');
      Navigator.of(context).pushReplacementNamed('/onboarding');
    } else if (state is RegistrationIncomplete) {
      if (_hasNavigated) return;
      _hasNavigated = true;
      // Remove native splash before navigation
      FlutterNativeSplash.remove();
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
      // Remove native splash before navigation
      FlutterNativeSplash.remove();

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
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Option 1: Use Lottie animation (if you have a Lottie file)
            // Uncomment the Lottie widget below and comment out _AnimatedSplashIcon()
            // Make sure you've downloaded a Lottie JSON file to assets/animations/
            // Lottie.asset(
            //   'assets/animations/splash_animation.json',
            //   width: 200,
            //   height: 200,
            //   fit: BoxFit.contain,
            //   repeat: true,
            //   errorBuilder: (context, error, stackTrace) {
            //     // Fallback to icon if Lottie fails to load
            //     return _AnimatedSplashIcon();
            //   },
            // ),

            // Option 2: Keep current animated icon (works without Lottie file)
            _AnimatedSplashIcon(),
            const SizedBox(height: 24.0),
            // Animated title with Nickelodeon style
            _NickelodeonAnimatedText(
              text: 'Mwanachuoshop',
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
            const SizedBox(height: 8.0),
            // Animated subtitle
            _NickelodeonAnimatedText(
              text: 'University Point of Sale',
              fontSize: 16,
              fontWeight: FontWeight.normal,
              delay: const Duration(milliseconds: 400),
            ),
          ],
        ),
      ),
    );
  }
}

// Animated icon widget
class _AnimatedSplashIcon extends StatefulWidget {
  @override
  State<_AnimatedSplashIcon> createState() => _AnimatedSplashIconState();
}

class _AnimatedSplashIconState extends State<_AnimatedSplashIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Bouncy scale animation (Nickelodeon style)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.2,
          end: 0.9,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.9,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
    ]).animate(_controller);

    // Slight rotation for playfulness
    _rotationAnimation = Tween<double>(
      begin: -0.1,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.1),
                borderRadius: kBaseRadius,
              ),
              child: Icon(
                CupertinoIcons.cart_fill,
                color: kPrimaryColor, // Green color
                size: 64,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Nickelodeon-style animated text widget (letter by letter)
class _NickelodeonAnimatedText extends StatefulWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Duration delay;

  const _NickelodeonAnimatedText({
    required this.text,
    required this.fontSize,
    required this.fontWeight,
    this.delay = Duration.zero,
  });

  @override
  State<_NickelodeonAnimatedText> createState() =>
      _NickelodeonAnimatedTextState();
}

class _NickelodeonAnimatedTextState extends State<_NickelodeonAnimatedText>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _rotationAnimations;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<Color?>> _colorAnimations;

  @override
  void initState() {
    super.initState();
    final letters = widget.text.split('');

    _controllers = List.generate(
      letters.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      ),
    );

    _scaleAnimations = _controllers.map((controller) {
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.0,
            end: 1.5,
          ).chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 40,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1.5,
            end: 0.85,
          ).chain(CurveTween(curve: Curves.easeInOut)),
          weight: 20,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.85,
            end: 1.05,
          ).chain(CurveTween(curve: Curves.easeOut)),
          weight: 20,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1.05,
            end: 1.0,
          ).chain(CurveTween(curve: Curves.easeInOut)),
          weight: 20,
        ),
      ]).animate(controller);
    }).toList();

    _rotationAnimations = _controllers.asMap().entries.map((entry) {
      final controller = entry.value;
      final index = entry.key;
      // Alternate rotation direction for playfulness
      final rotationDirection = index % 2 == 0 ? 1.0 : -1.0;
      return Tween<double>(
        begin: 0.4 * rotationDirection,
        end: 0.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.elasticOut));
    }).toList();

    _slideAnimations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0, -1.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));
    }).toList();

    // Color animations for splash effect
    _colorAnimations = _controllers.map((controller) {
      return ColorTween(
        begin: kPrimaryColor.withValues(alpha: 0.3),
        end: kPrimaryColor,
      ).animate(
        CurvedAnimation(
          parent: controller,
          curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
        ),
      );
    }).toList();

    // Start animations with staggered delay (letter by letter)
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(
        widget.delay + Duration(milliseconds: i * 50), // 50ms per letter
        () {
          if (mounted) {
            _controllers[i].forward();
          }
        },
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final letters = widget.text.split('');

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: List.generate(letters.length, (index) {
        final letter = letters[index];
        final isSpace = letter == ' ';

        if (isSpace) {
          return SizedBox(width: widget.fontSize * 0.3);
        }

        return AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                _slideAnimations[index].value.dx,
                _slideAnimations[index].value.dy * widget.fontSize,
              ),
              child: Transform.scale(
                scale: _scaleAnimations[index].value,
                child: Transform.rotate(
                  angle: _rotationAnimations[index].value,
                  child: Text(
                    letter,
                    style: GoogleFonts.plusJakartaSans(
                      color: _colorAnimations[index].value ?? kPrimaryColor,
                      fontSize: widget.fontSize,
                      fontWeight: widget.fontWeight,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
