import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mwanachuo/core/widgets/app_background.dart';
import 'package:mwanachuo/features/auth/presentation/pages/business_registration_screen.dart';
import 'package:mwanachuo/features/auth/presentation/pages/student_registration_screen.dart';

class RegistrationTypeScreen extends StatelessWidget {
  const RegistrationTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Join Mwanachuo',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose how you want to use the platform',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: Column(
                    children: [
                      _buildTypeCard(
                        context,
                        title: 'University Student',
                        description:
                            'Connect with students, buy & sell products, find accommodation, and more.',
                        icon: Icons.school_outlined,
                        color: const Color(0xFF00897B),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const StudentRegistrationScreen(),
                            ),
                          );
                        },
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 20),
                      _buildTypeCard(
                        context,
                        title: 'Business / Seller',
                        description:
                            'List your products, reach students, and grow your business on campus.',
                        icon: Icons.storefront_outlined,
                        color: const Color(0xFFE65100),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const BusinessRegistrationScreen(),
                            ),
                          );
                        },
                        isDarkMode: isDarkMode,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.arrow_forward_ios,
              color: isDarkMode ? Colors.white54 : Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
