import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/features/auth/presentation/pages/login_page.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_event.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignUp() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Dispatch sign up event to BLoC
    debugPrint('Dispatching SignUpEvent with email: $email, name: $name');
    context.read<AuthBloc>().add(
      SignUpEvent(email: email, password: password, name: name),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is RegistrationIncomplete) {
          // Account created but registration incomplete
          // User MUST select universities to continue
          debugPrint('📝 Account created - redirecting to university selection');
          Navigator.pushReplacementNamed(
            context,
            '/signup-university-selection',
          );
        } else if (state is Authenticated) {
          // This should not happen during signup - user should not be authenticated
          // until university selection is complete
          debugPrint('⚠️ User authenticated without completing registration!');
          Navigator.pushReplacementNamed(
            context,
            '/signup-university-selection',
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      builder: (context, authState) {
        return _buildSignUpUI(context, authState);
      },
    );
  }

  Widget _buildSignUpUI(BuildContext context, AuthState authState) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Account',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 18.0,
              medium: 20.0,
              expanded: 22.0,
            ),
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: ResponsiveBuilder(
        builder: (context, screenSize) {
          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(
                ResponsiveBreakpoints.responsiveValue(
                  context,
                  compact: 24.0,
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to Mwanachuoshop!',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: ResponsiveBreakpoints.responsiveValue(
                            context,
                            compact: 28.0,
                            medium: 32.0,
                            expanded: 36.0,
                          ),
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
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
                      Text(
                        'Create an account to start buying and selling on campus.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: ResponsiveBreakpoints.responsiveValue(
                            context,
                            compact: 16.0,
                            medium: 17.0,
                            expanded: 18.0,
                          ),
                          color: isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveBreakpoints.responsiveValue(
                          context,
                          compact: 32.0,
                          medium: 40.0,
                          expanded: 48.0,
                        ),
                      ),
                      // Name field
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        placeholder: 'Enter your full name',
                        icon: Icons.person_outline,
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
                      // Email field
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        placeholder: 'Enter your email',
                        icon: Icons.email_outlined,
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
                      // Password field
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        placeholder: 'Enter your password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        isObscure: _obscurePassword,
                        isDarkMode: isDarkMode,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: isDarkMode
                                ? Colors.grey.shade500
                                : kTextSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
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
                      // Confirm Password field
                      _buildTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        placeholder: 'Confirm your password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        isObscure: _obscureConfirmPassword,
                        isDarkMode: isDarkMode,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: isDarkMode
                                ? Colors.grey.shade500
                                : kTextSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveBreakpoints.responsiveValue(
                          context,
                          compact: 32.0,
                          medium: 40.0,
                          expanded: 48.0,
                        ),
                      ),
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
                                onPressed: authState is AuthLoading
                                    ? null
                                    : _handleSignUp,
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
                                        'Create Account',
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
                      SizedBox(
                        height: ResponsiveBreakpoints.responsiveValue(
                          context,
                          compact: 16.0,
                          medium: 20.0,
                          expanded: 24.0,
                        ),
                      ),
                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account? ',
                            style: GoogleFonts.plusJakartaSans(
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontSize: ResponsiveBreakpoints.responsiveValue(
                                context,
                                compact: 16.0,
                                medium: 17.0,
                                expanded: 18.0,
                              ),
                            ),
                            children: [
                              TextSpan(
                                text: 'Sign in',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryColor,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const LoginPage(),
                                      ),
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
            return null;
          },
        ),
      ],
    );
  }
}
