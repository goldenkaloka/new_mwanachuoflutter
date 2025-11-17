import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/widgets/network_image_with_fallback.dart';
import 'package:mwanachuo/features/auth/presentation/pages/onboarding_data.dart';
import 'package:mwanachuo/features/auth/presentation/pages/login_page.dart';
import 'package:mwanachuo/core/utils/responsive.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  void _nextPage() {
    if (_currentPage < onboardingPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    // Navigate to login/signup page
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == onboardingPages.length - 1;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ResponsiveBuilder(
        builder: (context, screenSize) {
          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: onboardingPages.length,
                  itemBuilder: (context, index) {
                    final page = onboardingPages[index];
                    return ResponsiveContainer(
                      padding: EdgeInsets.all(
                        ResponsiveBreakpoints.responsiveValue(
                          context,
                          compact: 24.0,
                          medium: 32.0,
                          expanded: 48.0,
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight - ResponsiveBreakpoints.responsiveValue(
                                  context,
                                  compact: 48.0,
                                  medium: 64.0,
                                  expanded: 80.0,
                                ),
                              ),
                              child: IntrinsicHeight(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Image container
                                    Container(
                                      height: ResponsiveBreakpoints.responsiveValue(
                                        context,
                                        compact: constraints.maxHeight * 0.4,
                                        medium: constraints.maxHeight * 0.45,
                                        expanded: constraints.maxHeight * 0.5,
                                      ),
                                      constraints: BoxConstraints(
                                        maxHeight: ResponsiveBreakpoints.responsiveValue(
                                          context,
                                          compact: 300.0,
                                          medium: 400.0,
                                          expanded: 500.0,
                                        ),
                                      ),
                                      margin: EdgeInsets.only(
                                        bottom: ResponsiveBreakpoints.responsiveValue(
                                          context,
                                          compact: 40.0,
                                          medium: 48.0,
                                          expanded: 56.0,
                                        ),
                                      ),
                                      child: NetworkImageWithFallback(
                                        imageUrl: page.imageUrl,
                                        fit: BoxFit.cover,
                                        borderRadius: kBaseRadius,
                                      ),
                                    ),
                                    // Title
                                    Text(
                                      page.title,
                                      textAlign: TextAlign.center,
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
                                    // Body text
                                    Text(
                                      page.body,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: ResponsiveBreakpoints.responsiveValue(
                                          context,
                                          compact: 16.0,
                                          medium: 17.0,
                                          expanded: 18.0,
                                        ),
                                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              // Bottom controls
              Container(
                padding: EdgeInsets.all(
                  ResponsiveBreakpoints.responsiveValue(
                    context,
                    compact: 24.0,
                    medium: 32.0,
                    expanded: 40.0,
                  ),
                ),
                child: Column(
                  children: [
                    // Page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(onboardingPages.length, (index) {
                        return Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: ResponsiveBreakpoints.responsiveValue(
                              context,
                              compact: 4.0,
                              medium: 6.0,
                              expanded: 8.0,
                            ),
                          ),
                          width: _currentPage == index
                              ? ResponsiveBreakpoints.responsiveValue(
                                  context,
                                  compact: 24.0,
                                  medium: 28.0,
                                  expanded: 32.0,
                                )
                              : ResponsiveBreakpoints.responsiveValue(
                                  context,
                                  compact: 8.0,
                                  medium: 10.0,
                                  expanded: 12.0,
                                ),
                          height: ResponsiveBreakpoints.responsiveValue(
                            context,
                            compact: 8.0,
                            medium: 10.0,
                            expanded: 12.0,
                          ),
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? kPrimaryColor
                                : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    SizedBox(
                      height: ResponsiveBreakpoints.responsiveValue(
                        context,
                        compact: 24.0,
                        medium: 32.0,
                        expanded: 40.0,
                      ),
                    ),
                    // Action button
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: ResponsiveBreakpoints.responsiveValue(
                            context,
                            compact: double.infinity,
                            medium: 400.0,
                            expanded: 450.0,
                          ),
                        ),
                        child: SizedBox(
                          width: ResponsiveBreakpoints.isCompact(context) 
                              ? double.infinity 
                              : null,
                          height: ResponsiveBreakpoints.responsiveValue(
                            context,
                            compact: 56.0,
                            medium: 52.0,
                            expanded: 54.0,
                          ),
                          child: ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: kBackgroundColorDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  ResponsiveBreakpoints.responsiveValue(
                                    context,
                                    compact: 16.0,
                                    medium: 18.0,
                                    expanded: 20.0,
                                  ),
                                ),
                              ),
                              elevation: ResponsiveBreakpoints.responsiveValue(
                                context,
                                compact: 4.0,
                                medium: 5.0,
                                expanded: 6.0,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveBreakpoints.responsiveValue(
                                  context,
                                  compact: 24.0,
                                  medium: 32.0,
                                  expanded: 36.0,
                                ),
                              ),
                            ),
                            child: Text(
                              isLastPage ? 'Get Started' : 'Next',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: ResponsiveBreakpoints.responsiveValue(
                                  context,
                                  compact: 16.0,
                                  medium: 17.0,
                                  expanded: 18.0,
                                ),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
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
                    // Skip button
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: Text(
                        'Skip',
                        style: GoogleFonts.plusJakartaSans(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: ResponsiveBreakpoints.responsiveValue(
                            context,
                            compact: 16.0,
                            medium: 17.0,
                            expanded: 18.0,
                          ),
                          fontWeight: FontWeight.normal,
                        ),
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
                    // Login link
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: Text(
                        'Already have an account? Login',
                        style: GoogleFonts.plusJakartaSans(
                          color: kPrimaryColor,
                          fontSize: ResponsiveBreakpoints.responsiveValue(
                            context,
                            compact: 16.0,
                            medium: 17.0,
                            expanded: 18.0,
                          ),
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

