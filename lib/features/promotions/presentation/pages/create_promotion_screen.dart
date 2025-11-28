import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';
import 'package:mwanachuo/features/promotions/presentation/bloc/promotion_cubit.dart';

class CreatePromotionScreen extends StatefulWidget {
  const CreatePromotionScreen({super.key});

  @override
  State<CreatePromotionScreen> createState() => _CreatePromotionScreenState();
}

class _CreatePromotionScreenState extends State<CreatePromotionScreen> {
  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  void _checkAdminAccess() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        final userRole = authState.user.role.value;

        if (userRole != 'admin') {
          debugPrint(
            '❌ Non-admin user attempting to create promotion - redirecting',
          );
          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Only administrators can create promotions',
                style: GoogleFonts.plusJakartaSans(),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    });
  }

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _termsController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  File? _selectedImage;

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? Colors.white : kTextPrimary;
    final secondaryTextColor = isDarkMode
        ? Colors.grey[400]!
        : Colors.grey[600]!;
    final borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;

    return Scaffold(
      backgroundColor: isDarkMode
          ? kBackgroundColorDark
          : kBackgroundColorLight,
      body: ResponsiveBuilder(
        builder: (context, screenSize) {
          return Column(
            children: [
              // Top App Bar
              _buildTopAppBar(
                context,
                primaryTextColor,
                secondaryTextColor,
                screenSize,
              ),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  child: ResponsiveContainer(
                    child: Padding(
                      padding: EdgeInsets.all(
                        ResponsiveBreakpoints.responsiveHorizontalPadding(
                          context,
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: ResponsiveBreakpoints.responsiveValue(
                                context,
                                compact: 24.0,
                                medium: 32.0,
                                expanded: 40.0,
                              ),
                            ),

                            // Photo Upload
                            _buildPhotoUpload(
                              primaryTextColor,
                              secondaryTextColor,
                              borderColor,
                            ),

                            const SizedBox(height: 24.0),

                            // Title
                            TextFormField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                labelText: 'Promotion Title',
                                hintText: 'e.g., Back to School Sale',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a title';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20.0),

                            // Subtitle
                            TextFormField(
                              controller: _subtitleController,
                              decoration: InputDecoration(
                                labelText: 'Subtitle',
                                hintText:
                                    'e.g., Up to 50% off on selected items',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20.0),

                            // Description
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                hintText: 'Describe your promotion...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20.0),

                            // Terms & Conditions
                            TextFormField(
                              controller: _termsController,
                              maxLines: 5,
                              decoration: InputDecoration(
                                labelText: 'Terms & Conditions (one per line)',
                                hintText:
                                    'Enter each term on a new line...\ne.g.,\nValid until stock lasts\nCannot be combined with other offers',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20.0),

                            // Date Range
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDateField(
                                    context,
                                    'Start Date',
                                    _startDate,
                                    () => _selectDate(context, true),
                                    borderColor,
                                  ),
                                ),
                                const SizedBox(width: 16.0),
                                Expanded(
                                  child: _buildDateField(
                                    context,
                                    'End Date',
                                    _endDate,
                                    () => _selectDate(context, false),
                                    borderColor,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(
                              height: ResponsiveBreakpoints.responsiveValue(
                                context,
                                compact: 120.0,
                                medium: 100.0,
                                expanded: 80.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Submit Button
              _buildSubmitButton(context, primaryTextColor, screenSize),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopAppBar(
    BuildContext context,
    Color primaryTextColor,
    Color secondaryTextColor,
    ScreenSize screenSize,
  ) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(
      context,
    );
    return Container(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        screenSize == ScreenSize.expanded ? 24.0 : 48.0,
        horizontalPadding,
        ResponsiveBreakpoints.responsiveValue(
          context,
          compact: 8.0,
          medium: 12.0,
          expanded: 16.0,
        ),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]!
                : Colors.grey[200]!,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            iconSize: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 24.0,
              medium: 26.0,
              expanded: 28.0,
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              'Create Promotion',
              style: GoogleFonts.inter(
                color: primaryTextColor,
                fontSize: ResponsiveBreakpoints.responsiveValue(
                  context,
                  compact: 18.0,
                  medium: 20.0,
                  expanded: 22.0,
                ),
                fontWeight: FontWeight.bold,
                letterSpacing: -0.015,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoUpload(
    Color primaryTextColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(
          color: borderColor,
          width: 2.0,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 48.0,
              color: secondaryTextColor,
            ),
            const SizedBox(height: 12.0),
            Text(
              'Upload Promotion Banner',
              style: GoogleFonts.plusJakartaSans(
                color: primaryTextColor,
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              'Tap to select an image',
              style: GoogleFonts.plusJakartaSans(
                color: secondaryTextColor,
                fontSize: 14.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context,
    String label,
    DateTime? date,
    VoidCallback onTap,
    Color borderColor,
  ) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: borderColor),
          ),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          date != null
              ? '${date.day}/${date.month}/${date.year}'
              : 'Select date',
          style: GoogleFonts.plusJakartaSans(fontSize: 16.0),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(
    BuildContext context,
    Color primaryTextColor,
    ScreenSize screenSize,
  ) {
    return Container(
      padding: EdgeInsets.all(
        ResponsiveBreakpoints.responsiveHorizontalPadding(context),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]!
                : Colors.grey[200]!,
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600.0),
            child: SizedBox(
              width: double.infinity,
              height: 48.0, // M3 standard button height
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    if (_startDate == null || _endDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please select both start and end dates',
                            style: GoogleFonts.plusJakartaSans(),
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    // Parse terms from text (split by newlines, filter empty)
                    final termsText = _termsController.text.trim();
                    final terms = termsText.isNotEmpty
                        ? termsText
                              .split('\n')
                              .map((t) => t.trim())
                              .where((t) => t.isNotEmpty)
                              .toList()
                        : null;

                    // Create promotion
                    await context.read<PromotionCubit>().createNewPromotion(
                      title: _titleController.text.trim(),
                      subtitle: _subtitleController.text.trim(),
                      description: _descriptionController.text.trim(),
                      startDate: _startDate!,
                      endDate: _endDate!,
                      image: _selectedImage,
                      terms: terms,
                    );

                    if (!context.mounted) return;
                    // Use the mounted check to guard the context usage
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: kBackgroundColorDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.0), // M3 standard
                  ),
                  elevation: 2.0, // M3 standard elevation
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                  ), // M3 standard
                  minimumSize: const Size(64, 40), // M3 minimum touch target
                ),
                child: Text(
                  'Create Promotion',
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
    );
  }
}
