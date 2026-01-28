import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/services/push_notification_service.dart';
import 'package:mwanachuo/features/auth/presentation/pages/registration_type_screen.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_event.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';
import 'package:mwanachuo/config/supabase_config.dart';
import 'package:mwanachuo/core/middleware/subscription_middleware.dart';
import 'package:mwanachuo/core/widgets/app_background.dart';
import 'package:mwanachuo/features/auth/presentation/widgets/auth_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    context.read<AuthBloc>().add(SignInEvent(email: email, password: password));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          PushNotificationService().registerDeviceTokenForUser(state.user.id);
          _preCheckSubscription(state.user.id);
          Navigator.pushReplacementNamed(context, '/home');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
      builder: (context, authState) {
        return Scaffold(
          body: AppBackground(
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),
                          // Title
                          Text(
                            'Log In',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Email Field
                          AuthTextField(
                            controller: _emailController,
                            label: 'Email',
                            hintText: 'Email',
                            prefixIcon: Icons.person_outline,
                            isDarkMode: isDarkMode,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          AuthTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hintText: 'Password',
                            prefixIcon: Icons.lock_outline,
                            isPassword: true,
                            obscureText: !_isPasswordVisible,
                            isDarkMode: isDarkMode,
                            onToggleObscure: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Remember Me & Forgot Password
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (value) {
                                        setState(() {
                                          _rememberMe = value ?? false;
                                        });
                                      },
                                      activeColor: const Color(0xFF00897B),
                                      side: BorderSide(
                                        color: isDarkMode
                                            ? Colors.grey[600]!
                                            : Colors.grey[400]!,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Remember me',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  // TODO: Implement forgot password
                                },
                                child: Text(
                                  'Forgot Password',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.redAccent,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: authState is AuthLoading
                                  ? null
                                  : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFF00897B,
                                ), // Deep Teal
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                                disabledBackgroundColor: const Color(
                                  0xFF00897B,
                                ).withValues(alpha: 0.5),
                              ),
                              child: authState is AuthLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      'Log in',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // OR Divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.grey[700],
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  'Or Sign in with',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: isDarkMode
                                      ? Colors.grey[700]
                                      : Colors.grey[300],
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Social Login Icons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildSocialButton(
                                Icons.facebook,
                                () {},
                                isDarkMode,
                              ),
                              const SizedBox(width: 16),
                              _buildSocialButton(
                                Icons.g_mobiledata,
                                () {},
                                isDarkMode,
                              ),
                              const SizedBox(width: 16),
                              _buildSocialButton(
                                Icons.apple,
                                () {},
                                isDarkMode,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Sign Up Link
                          Center(
                            child: RichText(
                              text: TextSpan(
                                text: "Don't have an account? ",
                                style: GoogleFonts.plusJakartaSans(
                                  color: isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[700],
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Sign up',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(
                                        0xFF00897B,
                                      ), // Deep Teal
                                      fontWeight: FontWeight.bold,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const RegistrationTypeScreen(),
                                          ),
                                        );
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSocialButton(
    IconData icon,
    VoidCallback onTap,
    bool isDarkMode,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
          ),
        ),
        child: Icon(
          icon,
          size: 28,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Future<void> _preCheckSubscription(String userId) async {
    try {
      final userData = await SupabaseConfig.client
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();

      final role = userData['role'] as String?;
      final isSeller = role == 'seller' || role == 'admin';

      if (isSeller) {
        SubscriptionMiddleware.canAccessMessages(sellerId: userId);
      }
    } catch (e) {
      // Ignore errors - will check when needed
    }
  }
}
