import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/services/push_notification_service.dart';
import 'package:mwanachuo/features/auth/presentation/pages/create_account_screen.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_event.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isPasswordVisible = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _handleLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password.')),
      );
      return;
    }

    // Dispatch sign in event to BLoC
    context.read<AuthBloc>().add(SignInEvent(
      email: email,
      password: password,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // Register device token for push notifications
          PushNotificationService().registerDeviceTokenForUser(state.user.id);
          Navigator.pushReplacementNamed(context, '/home');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, authState) {
        return _buildLoginUI(context, authState);
      },
    );
  }

  Widget _buildLoginUI(BuildContext context, AuthState authState) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDarkMode ? kPrimaryColor : kBackgroundColorDark;
    final primaryTextColor = isDarkMode ? Colors.white : kTextPrimary;
    final secondaryTextColor = isDarkMode
        ? Colors.grey.shade400
        : kTextSecondary;
    final cardColor = isDarkMode
        ? const Color(0xFF1E293B)
        : Colors.white;

    return Scaffold(
      body: ResponsiveBuilder(
        builder: (context, screenSize) {
          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(
                ResponsiveBreakpoints.responsiveValue(
                  context,
                  compact: 32.0,
                  medium: 48.0,
                  expanded: 64.0,
                ),
              ),
              child: ResponsiveContainer(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: ResponsiveBreakpoints.responsiveValue(
                      context,
                      compact: 400.0,
                      medium: 480.0,
                      expanded: 520.0,
                    ),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(
                      ResponsiveBreakpoints.responsiveValue(
                        context,
                        compact: 32.0,
                        medium: 40.0,
                        expanded: 48.0,
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: kBaseRadius,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icon
                        Container(
                          height: ResponsiveBreakpoints.responsiveValue(
                            context,
                            compact: 64.0,
                            medium: 72.0,
                            expanded: 80.0,
                          ),
                          width: ResponsiveBreakpoints.responsiveValue(
                            context,
                            compact: 64.0,
                            medium: 72.0,
                            expanded: 80.0,
                          ),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.shopping_bag,
                              size: ResponsiveBreakpoints.responsiveValue(
                                context,
                                compact: 32.0,
                                medium: 36.0,
                                expanded: 40.0,
                              ),
                              color: iconColor,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: ResponsiveBreakpoints.responsiveValue(
                            context,
                            compact: 16.0,
                            medium: 20.0,
                            expanded: 24.0,
                          ),
                        ),
                        // Title
                        Text(
                          'Welcome Back!',
                          style: GoogleFonts.plusJakartaSans(
                            color: primaryTextColor,
                            fontSize: ResponsiveBreakpoints.responsiveValue(
                              context,
                              compact: 28.0,
                              medium: 32.0,
                              expanded: 36.0,
                            ),
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
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
                        // Subtitle
                        Text(
                          'Log in to your Mwanachuoshop account',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: secondaryTextColor,
                            fontSize: ResponsiveBreakpoints.responsiveValue(
                              context,
                              compact: 16.0,
                              medium: 17.0,
                              expanded: 18.0,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: ResponsiveBreakpoints.responsiveValue(
                            context,
                            compact: 24.0,
                            medium: 32.0,
                            expanded: 40.0,
                          ),
                        ),
                        // Form
                        Column(
                          children: [
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email',
                              placeholder: 'Enter your email',
                              icon: Icons.mail_outline,
                              isDarkMode: isDarkMode,
                            ),
                            SizedBox(
                              height: ResponsiveBreakpoints.responsiveValue(
                                context,
                                compact: 16.0,
                                medium: 20.0,
                                expanded: 24.0,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  placeholder: 'Enter your password',
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                  isObscure: !_isPasswordVisible,
                                  isDarkMode: isDarkMode,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: secondaryTextColor,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    debugPrint('Forgot Password clicked');
                                  },
                                  child: Text(
                                    'Forgot Password?',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: secondaryTextColor,
                                      fontSize: ResponsiveBreakpoints.responsiveValue(
                                        context,
                                        compact: 14.0,
                                        medium: 15.0,
                                        expanded: 16.0,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: ResponsiveBreakpoints.responsiveValue(
                                context,
                                compact: 8.0,
                                medium: 12.0,
                                expanded: 16.0,
                              ),
                            ),
                            // Login Button
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveBreakpoints.responsiveValue(
                                  context,
                                  compact: 16.0, // M3 standard margin for mobile
                                  medium: 0.0,
                                  expanded: 0.0,
                                ),
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: ResponsiveBreakpoints.responsiveValue(
                                      context,
                                      compact: 600.0,
                                      medium: 400.0,
                                      expanded: 450.0,
                                    ),
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: ResponsiveBreakpoints.responsiveValue(
                                      context,
                                      compact: 48.0, // M3 standard button height
                                      medium: 48.0,
                                      expanded: 52.0,
                                    ),
                                    child: ElevatedButton(
                                      onPressed: authState is AuthLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kPrimaryColor,
                                        foregroundColor: kBackgroundColorDark,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(24.0), // M3 standard
                                        ),
                                        elevation: 2.0, // M3 standard elevation
                                        padding: const EdgeInsets.symmetric(horizontal: 24.0), // M3 standard
                                        minimumSize: const Size(64, 40), // M3 minimum touch target
                                      ),
                                      child: authState is AuthLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                        'Login',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16.0, // M3 standard button text size
                                          fontWeight: FontWeight.w600, // M3 medium weight
                                          letterSpacing: 0.1, // M3 standard tracking
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
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
                        // OR Separator
                        _buildSeparator(secondaryTextColor),
                        SizedBox(
                          height: ResponsiveBreakpoints.responsiveValue(
                            context,
                            compact: 24.0,
                            medium: 32.0,
                            expanded: 40.0,
                          ),
                        ),
                        // Login with Google Button
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveBreakpoints.responsiveValue(
                              context,
                              compact: 16.0, // M3 standard margin for mobile
                              medium: 0.0,
                              expanded: 0.0,
                            ),
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: ResponsiveBreakpoints.responsiveValue(
                                  context,
                                  compact: 600.0,
                                  medium: 400.0,
                                  expanded: 450.0,
                                ),
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                height: ResponsiveBreakpoints.responsiveValue(
                                  context,
                                  compact: 48.0, // M3 standard button height
                                  medium: 48.0,
                                  expanded: 52.0,
                                ),
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    debugPrint('Login with Google clicked');
                                  },
                                  icon: Image.asset(
                                    'assets/google_logo.jpg',
                                    height: 24.0,
                                    width: 24.0,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(
                                          Icons.g_mobiledata,
                                          size: 28.0,
                                        ),
                                  ),
                                  label: Text(
                                    'Login with Google',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: primaryTextColor,
                                      fontSize: 16.0, // M3 standard button text size
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.1, // M3 standard tracking
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: cardColor,
                                    side: BorderSide(
                                      color: isDarkMode
                                          ? Colors.grey.shade700
                                          : Colors.grey.shade300,
                                      width: 1.0, // M3 standard border width
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24.0), // M3 standard
                                    ),
                                    elevation: 0.0, // M3 outlined buttons have no elevation
                                    padding: const EdgeInsets.symmetric(horizontal: 24.0), // M3 standard
                                    minimumSize: const Size(64, 40), // M3 minimum touch target
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: ResponsiveBreakpoints.responsiveValue(
                            context,
                            compact: 24.0,
                            medium: 32.0,
                            expanded: 40.0,
                          ),
                        ),
                        // Sign Up Link
                        RichText(
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: GoogleFonts.plusJakartaSans(
                              color: secondaryTextColor,
                              fontSize: ResponsiveBreakpoints.responsiveValue(
                                context,
                                compact: 14.0,
                                medium: 15.0,
                                expanded: 16.0,
                              ),
                            ),
                            children: [
                              TextSpan(
                                text: 'Sign Up',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryColor,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const CreateAccountScreen(),
                                      ),
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    required IconData icon,
    bool isPassword = false,
    bool isObscure = false,
    required bool isDarkMode,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            bottom: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 8.0,
              medium: 10.0,
              expanded: 12.0,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: isDarkMode ? Colors.grey.shade300 : kTextPrimary,
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
        TextFormField(
          controller: controller,
          obscureText: isObscure,
          keyboardType: isPassword
              ? TextInputType.text
              : TextInputType.emailAddress,
          style: GoogleFonts.plusJakartaSans(
            color: isDarkMode ? Colors.white : kTextPrimary,
            fontSize: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 16.0,
              medium: 17.0,
              expanded: 18.0,
            ),
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: GoogleFonts.plusJakartaSans(
              color: isDarkMode ? Colors.grey.shade500 : kTextSecondary,
              fontSize: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 16.0,
                medium: 17.0,
                expanded: 18.0,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 16.0,
                medium: 18.0,
                expanded: 20.0,
              ),
              horizontal: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 16.0,
                medium: 20.0,
                expanded: 24.0,
              ),
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.only(
                left: ResponsiveBreakpoints.responsiveValue(
                  context,
                  compact: 12.0,
                  medium: 16.0,
                  expanded: 20.0,
                ),
                right: ResponsiveBreakpoints.responsiveValue(
                  context,
                  compact: 8.0,
                  medium: 12.0,
                  expanded: 16.0,
                ),
              ),
              child: Icon(
                icon,
                color: isDarkMode ? Colors.grey.shade500 : kTextSecondary,
                size: ResponsiveBreakpoints.responsiveValue(
                  context,
                  compact: 24.0,
                  medium: 26.0,
                  expanded: 28.0,
                ),
              ),
            ),
            prefixIconConstraints: BoxConstraints(
              minWidth: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 40.0,
                medium: 48.0,
                expanded: 56.0,
              ),
              minHeight: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 48.0,
                medium: 52.0,
                expanded: 56.0,
              ),
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: isDarkMode
                ? const Color(0xFF334155)
                : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: kBaseRadius,
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            if (isPassword && value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSeparator(Color textColor) {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: textColor.withValues(alpha: 0.3)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 16.0,
              medium: 20.0,
              expanded: 24.0,
            ),
          ),
          child: Text(
            'OR',
            style: GoogleFonts.plusJakartaSans(
              color: textColor,
              fontSize: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 14.0,
                medium: 15.0,
                expanded: 16.0,
              ),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: textColor.withValues(alpha: 0.3)),
        ),
      ],
    );
  }
}

