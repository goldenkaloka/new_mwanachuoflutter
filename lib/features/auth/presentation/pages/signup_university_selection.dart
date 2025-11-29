import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/services/university_service.dart';
import 'package:mwanachuo/config/supabase_config.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_event.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';

class SignupUniversitySelectionScreen extends StatefulWidget {
  const SignupUniversitySelectionScreen({super.key});

  @override
  State<SignupUniversitySelectionScreen> createState() =>
      _SignupUniversitySelectionScreenState();
}

class _SignupUniversitySelectionScreenState
    extends State<SignupUniversitySelectionScreen> {
  final List<Map<String, String>> _universities = [];
  String? _primaryUniversityId;
  final Set<String> _subsidiaryUniversityIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUniversities();
  }

  Future<void> _loadUniversities() async {
    try {
      final response = await SupabaseConfig.client
          .from('universities')
          .select('id, name, location, logo_url')
          .order('name');

      setState(() {
        _universities.clear();
        for (var university in response) {
          _universities.add({
            'id': university['id'] as String,
            'name': university['name'] as String,
            'location': university['location'] as String? ?? '',
            'logo_url': university['logo_url'] as String? ?? '',
          });
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading universities: $e')),
        );
      }
    }
  }

  Future<void> _confirmSelection() async {
    if (_primaryUniversityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a primary university'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User not authenticated',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Dispatch event to BLoC
    context.read<AuthBloc>().add(CompleteRegistrationEvent(
      userId: userId,
      primaryUniversityId: _primaryUniversityId!,
      subsidiaryUniversityIds: _subsidiaryUniversityIds.toList(),
    ));
  }

  void _toggleSubsidiaryUniversity(String universityId) {
    if (universityId == _primaryUniversityId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primary university cannot be a subsidiary'),
        ),
      );
      return;
    }

    setState(() {
      if (_subsidiaryUniversityIds.contains(universityId)) {
        _subsidiaryUniversityIds.remove(universityId);
      } else {
        if (_subsidiaryUniversityIds.length >= 4) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can select up to 4 subsidiary universities'),
            ),
          );
        } else {
          _subsidiaryUniversityIds.add(universityId);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? Colors.white : kTextPrimary;
    final secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is RegistrationCompleted) {
          // Capture context for success message
          final messenger = ScaffoldMessenger.of(context);
          
          // Save primary university to local storage
          final primaryUniversity = _universities.firstWhere(
            (u) => u['id'] == _primaryUniversityId,
          );
          await UniversityService.saveSelectedUniversity(primaryUniversity['name']!);

          if (!mounted) return;

          // Show success message
          messenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Registration completed! ${_subsidiaryUniversityIds.length} subsidiary universities selected.',
                      style: GoogleFonts.plusJakartaSans(),
                    ),
                  ),
                ],
              ),
              backgroundColor: kPrimaryColor,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Note: After this, AuthBloc will emit Authenticated with updated user
        } else if (state is Authenticated) {
          // User is now fully authenticated with universities
          // Navigate to home
          debugPrint('✅ User fully authenticated with universities');
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed('/home');
        } else if (state is AuthError) {
          // Show error with option to retry or cancel
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                'Registration Error',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
              content: Text(
                'Failed to complete registration: ${state.message}\n\nYou must select universities to use the app.',
                style: GoogleFonts.plusJakartaSans(),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Cancel registration and sign out
                    context.read<AuthBloc>().add(const SignOutEvent());
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: Text(
                    'Cancel & Sign Out',
                    style: GoogleFonts.plusJakartaSans(color: Colors.red),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Try again
                    _confirmSelection();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                  ),
                  child: Text(
                    'Try Again',
                    style: GoogleFonts.plusJakartaSans(color: kBackgroundColorDark),
                  ),
                ),
              ],
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Your Universities',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDarkMode ? kBackgroundColorDark : Colors.white,
      ),
      backgroundColor: isDarkMode ? kBackgroundColorDark : kBackgroundColorLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select your primary university and up to 4 subsidiary universities',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: kPrimaryColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tap once for primary, tap checkbox for subsidiary',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: primaryTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _universities.length,
                    itemBuilder: (context, index) {
                      final university = _universities[index];
                      final universityId = university['id']!;
                      final isPrimary = universityId == _primaryUniversityId;
                      final isSubsidiary = _subsidiaryUniversityIds.contains(universityId);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isDarkMode ? Colors.grey[900] : Colors.white,
                        child: ListTile(
                          onTap: () {
                            setState(() {
                              _primaryUniversityId = universityId;
                              // Remove from subsidiaries if it was there
                              _subsidiaryUniversityIds.remove(universityId);
                            });
                          },
                          leading: CircleAvatar(
                            backgroundColor: isPrimary
                                ? kPrimaryColor
                                : isDarkMode
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                            child: Icon(
                              isPrimary ? Icons.check : Icons.school,
                              color: isPrimary
                                  ? kBackgroundColorDark
                                  : isDarkMode
                                      ? Colors.white
                                      : Colors.grey[600],
                            ),
                          ),
                          title: Text(
                            university['name']!,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
                              color: primaryTextColor,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                university['location']!,
                                style: GoogleFonts.plusJakartaSans(
                                  color: secondaryTextColor,
                                  fontSize: 12,
                                ),
                              ),
                              if (isPrimary)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: kPrimaryColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'PRIMARY',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: kBackgroundColorDark,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: !isPrimary
                              ? Checkbox(
                                  value: isSubsidiary,
                                  onChanged: (value) {
                                    _toggleSubsidiaryUniversity(universityId);
                                  },
                                  fillColor: WidgetStateProperty.resolveWith(
                                    (states) => states.contains(WidgetState.selected)
                                        ? kPrimaryColor
                                        : (isDarkMode
                                            ? Colors.grey[700]
                                            : Colors.grey[400]),
                                  ),
                                  checkColor: kBackgroundColorDark,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_subsidiaryUniversityIds.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Selected: 1 primary + ${_subsidiaryUniversityIds.length} subsidiary',
                            style: GoogleFonts.plusJakartaSans(
                              color: secondaryTextColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      // M3 compliant button
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600.0),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48.0, // M3 standard button height
                            child: ElevatedButton(
                              onPressed: _primaryUniversityId != null
                                  ? _confirmSelection
                                  : null,
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
                              child: Text(
                                'Continue',
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
                    ],
                  ),
                ),
              ],
            ),
        );
      },
    );
  }
}

