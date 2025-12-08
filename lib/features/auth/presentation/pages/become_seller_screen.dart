import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/config/supabase_config.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_event.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';
import 'package:mwanachuo/features/auth/presentation/widgets/seller_request_status_card.dart';

class BecomeSellerScreen extends StatefulWidget {
  const BecomeSellerScreen({super.key});

  @override
  State<BecomeSellerScreen> createState() => _BecomeSellerScreenState();
}

class _BecomeSellerScreenState extends State<BecomeSellerScreen> {
  final TextEditingController _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _hasSubmitted = false; // Flag to prevent multiple submissions
  String? _currentRequestStatus; // Track current request status

  @override
  void initState() {
    super.initState();
    // Load request status on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthBloc>().add(const GetSellerRequestStatusEvent());
      }
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool _canSubmit() {
    // Can't submit if already submitted, loading, or has existing request
    if (_hasSubmitted) return false;
    if (_currentRequestStatus == 'pending') return false;
    if (_currentRequestStatus == 'approved') return false;
    return true;
  }

  void _submitRequest() {
    if (!_canSubmit()) return;
    
    if (_formKey.currentState!.validate()) {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return;

      setState(() {
        _hasSubmitted = true; // Prevent multiple submissions
      });

      context.read<AuthBloc>().add(
        RequestSellerAccessEvent(
          userId: userId,
          reason: _reasonController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? Colors.white : kTextPrimary;
    final secondaryTextColor = isDarkMode
        ? Colors.grey[400]!
        : Colors.grey[600]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Become a Seller',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDarkMode ? kBackgroundColorDark : Colors.white,
      ),
      backgroundColor: isDarkMode
          ? kBackgroundColorDark
          : kBackgroundColorLight,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is SellerRequestSubmitted) {
            // Clear form and update UI
            setState(() {
              _reasonController.clear();
              _currentRequestStatus = 'pending'; // Set status to pending
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Seller request submitted! We\'ll review it soon.',
                ),
                backgroundColor: kPrimaryColor,
                duration: Duration(seconds: 4),
              ),
            );
            // Reload status to show the pending status card
            context.read<AuthBloc>().add(const GetSellerRequestStatusEvent());
          } else if (state is SellerRequestStatusLoaded) {
            // Update current status to enable/disable form
            setState(() {
              _currentRequestStatus = state.status;
              // If status is null (no request) or rejected, allow submission
              if (state.status == null || state.status == 'rejected') {
                _hasSubmitted = false;
              }
            });
          } else if (state is AuthError) {
            // On error, allow resubmission
            setState(() {
              _hasSubmitted = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(
              ResponsiveBreakpoints.responsiveHorizontalPadding(context),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // Show request status if exists
                  const SellerRequestStatusCard(),

                  // Icon
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.storefront,
                        size: 50,
                        color: kPrimaryColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Start Selling Today!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'As a seller, you can:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryTextColor,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Benefits List
                  ...[
                    '📦 Post unlimited products',
                    '🔧 Offer services to students',
                    '🏠 List accommodation options',
                    '📊 Access seller dashboard',
                    '💬 Manage customer messages',
                    '⭐ Build your reputation',
                  ].map(
                    (benefit) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            benefit,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Reason Field
                  Text(
                    'Why do you want to become a seller?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryTextColor,
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _reasonController,
                    maxLines: 4,
                    enabled: _canSubmit() && state is! AuthLoading,
                    decoration: InputDecoration(
                      hintText:
                          'Tell us why you want to sell on Mwanachuoshop...',
                      filled: true,
                      fillColor: isDarkMode
                          ? const Color(0xFF334155)
                          : Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please provide a reason';
                      }
                      if (value.trim().length < 20) {
                        return 'Please provide at least 20 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // Submit Button - M3 compliant
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48.0, // M3 standard button height
                        child: ElevatedButton(
                          onPressed: (state is AuthLoading || !_canSubmit())
                              ? null
                              : _submitRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _canSubmit()
                                ? kPrimaryColor
                                : Colors.grey,
                            foregroundColor: _canSubmit()
                                ? kBackgroundColorDark
                                : Colors.white70,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ), // M3 standard
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                24.0,
                              ), // M3 standard
                            ),
                            elevation: 2.0, // M3 standard elevation
                            minimumSize: const Size(
                              64,
                              40,
                            ), // M3 minimum touch target
                          ),
                          child: state is AuthLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _currentRequestStatus == 'pending'
                                      ? 'Request Pending'
                                      : _currentRequestStatus == 'approved'
                                          ? 'Already a Seller'
                                          : 'Submit Request',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize:
                                        16.0, // M3 standard button text size
                                    fontWeight:
                                        FontWeight.w600, // M3 medium weight
                                    letterSpacing: 0.1, // M3 standard tracking
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your request will be reviewed by our team within 24-48 hours.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
