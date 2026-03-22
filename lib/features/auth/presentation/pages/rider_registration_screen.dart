import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/widgets/app_background.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_event.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';
import 'package:mwanachuo/features/auth/presentation/widgets/auth_text_field.dart';

class RiderRegistrationScreen extends StatefulWidget {
  const RiderRegistrationScreen({super.key});

  @override
  State<RiderRegistrationScreen> createState() => _RiderRegistrationScreenState();
}

class _RiderRegistrationScreenState extends State<RiderRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _plateNumberController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToPolicy = false;

  String? _selectedTransportMode;
  final List<String> _transportModes = ['Foot', 'Bicycle', 'Motorcycle', 'Bajaji', 'Car'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _studentIdController.dispose();
    _plateNumberController.dispose();
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

    final requiresPlate = _selectedTransportMode == 'Motorcycle' || 
                          _selectedTransportMode == 'Bajaji' || 
                          _selectedTransportMode == 'Car';
                          
    if (requiresPlate && _plateNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plate Number is required for your vehicle type')),
      );
      return;
    }

    context.read<AuthBloc>().add(
      RegisterRiderEvent(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        phone: _phoneController.text.trim(),
        vehicleType: _selectedTransportMode ?? 'Foot',
        vehiclePlate: requiresPlate ? _plateNumberController.text.trim() : null,
        studentIdNumber: _studentIdController.text.trim().isNotEmpty ? _studentIdController.text.trim() : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final requiresPlate = _selectedTransportMode == 'Motorcycle' || 
                          _selectedTransportMode == 'Bajaji' || 
                          _selectedTransportMode == 'Car';

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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
                            'Rider Registration',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Fill in your details to start delivering',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 30),

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

                          _buildDropdownField<String>(
                            label: 'Mode of Transport',
                            value: _selectedTransportMode,
                            items: _transportModes
                                .map(
                                  (mode) => DropdownMenuItem<String>(
                                    value: mode,
                                    child: Text(mode),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedTransportMode = value;
                                if (value == 'Foot' || value == 'Bicycle') {
                                  _plateNumberController.clear();
                                }
                              });
                            },
                            hint: 'Select your vehicle type',
                            icon: Icons.two_wheeler,
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(height: 16),
                          
                          if (requiresPlate)
                            Column(
                              children: [
                                AuthTextField(
                                  controller: _plateNumberController,
                                  label: 'Plate Number',
                                  hintText: 'e.g. MC 123 ABC',
                                  prefixIcon: Icons.numbers,
                                  isDarkMode: isDarkMode,
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),

                          AuthTextField(
                            controller: _studentIdController,
                            label: 'Student ID (Optional)',
                            hintText: 'For verified student status',
                            prefixIcon: Icons.badge_outlined,
                            isDarkMode: isDarkMode,
                            validator: (v) => null,
                          ),
                          const SizedBox(height: 16),

                          AuthTextField(
                            controller: _emailController,
                            label: 'Email',
                            hintText: 'example@email.com',
                            prefixIcon: Icons.email_outlined,
                            isDarkMode: isDarkMode,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),

                          AuthTextField(
                            controller: _phoneController,
                            label: 'Phone number',
                            hintText: '0712 345 678',
                            prefixIcon: Icons.phone_outlined,
                            isDarkMode: isDarkMode,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),

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
                                          color: kPrimaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = _openPrivacyPolicy,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: authState is AuthLoading
                                  ? null
                                  : _handleSignup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor,
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
                                      'Register Rider',
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

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
    required String hint,
    required IconData icon,
    required bool isDarkMode,
  }) {
    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.grey[300]!;
    final fillColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.grey[50]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.grey[500],
            ),
            prefixIcon: Icon(
              icon,
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.grey[600],
            ),
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null) {
              return 'Please select $label';
            }
            return null;
          },
        ),
      ],
    );
  }

  Future<void> _openPrivacyPolicy() async {
    final Uri url = Uri.parse('https://mwanachuo.com/privacy-policy');
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open privacy policy')),
        );
      }
    }
  }
}
