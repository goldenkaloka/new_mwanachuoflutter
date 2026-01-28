import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/widgets/app_background.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_event.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';
import 'package:mwanachuo/features/auth/presentation/widgets/auth_text_field.dart';

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  State<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _registrationNumberController =
      TextEditingController();
  final TextEditingController _programNameController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToPolicy = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _registrationNumberController.dispose();
    _programNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignup() {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToPolicy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the privacy policy')),
      );
      return;
    }

    context.read<AuthBloc>().add(
      SignUpEvent(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name:
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        phone: _phoneController.text.trim(),
        registrationNumber: _registrationNumberController.text.trim(),
        programName: _programNameController.text.trim(),
        userType: 'student',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated || state is RegistrationIncomplete) {
          // Navigate to university selection after successful registration
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/signup-university-selection',
            (route) => false,
          );
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
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.arrow_back,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Student Registration',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Fill in your details to join',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Name Row
                          Row(
                            children: [
                              Expanded(
                                child: AuthTextField(
                                  controller: _firstNameController,
                                  label: 'First Name',
                                  hintText: 'John',
                                  prefixIcon: Icons.person_outline,
                                  isDarkMode: isDarkMode,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AuthTextField(
                                  controller: _lastNameController,
                                  label: 'Last Name',
                                  hintText: 'Doe',
                                  prefixIcon: Icons.person_outline,
                                  isDarkMode: isDarkMode,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Registration Number
                          AuthTextField(
                            controller: _registrationNumberController,
                            label: 'Registration Number',
                            hintText: 'e.g. T/UDOM/2021/1234',
                            prefixIcon: Icons.badge_outlined,
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(height: 16),

                          // Program Name
                          AuthTextField(
                            controller: _programNameController,
                            label: 'Course / Program',
                            hintText: 'BSc. Computer Science',
                            prefixIcon: Icons.school_outlined,
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(height: 16),

                          // Email
                          AuthTextField(
                            controller: _emailController,
                            label: 'Email',
                            hintText: 'example@email.com',
                            prefixIcon: Icons.email_outlined,
                            isDarkMode: isDarkMode,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),

                          // Phone
                          AuthTextField(
                            controller: _phoneController,
                            label: 'Phone number',
                            hintText: '0712 345 678',
                            prefixIcon: Icons.phone_outlined,
                            isDarkMode: isDarkMode,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),

                          // Password
                          AuthTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hintText: '••••••••',
                            prefixIcon: Icons.lock_outline,
                            isDarkMode: isDarkMode,
                            isPassword: true,
                            obscureText: !_isPasswordVisible,
                            onToggleObscure: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password
                          AuthTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirm Password',
                            hintText: '••••••••',
                            prefixIcon: Icons.lock_outline,
                            isDarkMode: isDarkMode,
                            isPassword: true,
                            obscureText: !_isConfirmPasswordVisible,
                            onToggleObscure: () {
                              setState(() {
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible;
                              });
                            },
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Privacy Policy Checkbox
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _agreeToPolicy,
                                  onChanged: (value) {
                                    setState(() {
                                      _agreeToPolicy = value ?? false;
                                    });
                                  },
                                  activeColor: kPrimaryColor,
                                  side: BorderSide(
                                    color: isDarkMode
                                        ? Colors.white.withValues(alpha: 0.3)
                                        : Colors.grey[400]!,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    text: 'I agree to the ',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: isDarkMode
                                          ? Colors.white.withValues(alpha: 0.6)
                                          : Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: const TextStyle(
                                          color: Color(0xFF00897B),
                                          fontWeight: FontWeight.bold,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            // TODO: Open Privacy Policy
                                          },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          // Signup Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: authState is AuthLoading
                                  ? null
                                  : _handleSignup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00897B),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: authState is AuthLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      'Register Student',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
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
}
