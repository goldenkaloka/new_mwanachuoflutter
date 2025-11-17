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

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submitRequest() {
    if (_formKey.currentState!.validate()) {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return;

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
    final secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Become a Seller',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDarkMode ? kBackgroundColorDark : Colors.white,
      ),
      backgroundColor: isDarkMode ? kBackgroundColorDark : kBackgroundColorLight,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is SellerRequestSubmitted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Seller request submitted! We\'ll review it soon.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 4),
              ),
            );
          } else if (state is AuthError) {
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
                  ].map((benefit) => Padding(
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
                      )),
                  
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
                    decoration: InputDecoration(
                      hintText: 'Tell us why you want to sell on Mwanachuoshop...',
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
                          onPressed: state is AuthLoading ? null : _submitRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: kBackgroundColorDark,
                            padding: const EdgeInsets.symmetric(horizontal: 24.0), // M3 standard
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.0), // M3 standard
                            ),
                            elevation: 2.0, // M3 standard elevation
                            minimumSize: const Size(64, 40), // M3 minimum touch target
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
                                  'Submit Request',
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
                        const Icon(Icons.info_outline, color: Colors.blue, size: 20),
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

