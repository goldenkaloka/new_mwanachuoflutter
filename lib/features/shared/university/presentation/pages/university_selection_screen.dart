import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/widgets/network_image_with_fallback.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/core/services/university_service.dart';

class UniversitySelectionScreen extends StatefulWidget {
  final String? selectedUniversity;
  final bool isFromOnboarding;

  const UniversitySelectionScreen({
    super.key,
    this.selectedUniversity,
    this.isFromOnboarding = false,
  });

  @override
  State<UniversitySelectionScreen> createState() => _UniversitySelectionScreenState();
}

class _UniversitySelectionScreenState extends State<UniversitySelectionScreen> {
  String? _selectedUniversity;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _filteredUniversities = [];

  final List<Map<String, String>> _universities = [
    {
      'name': 'University of Nairobi',
      'logo': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDrJZvKSUBKbX014yoj27QHwYw1hGpHwLWDa-d66qvo5YqtQ3uzIsUSgs8__rUyQd7hkNqFatWlOGYhw1oK_ITNZ9e9RzI5VWhHjCkm0HqVSSgrtX7rC4HNuBrGqP7ERp6_h45AnDB7XqoPO1Ooof9K2i-oLIC2umUhAhLXDTY2PvukJohgpe90md0GRL4dggiLB1P3Gq9_U_gLuCwraNbdQmkhlC80WgiBXG0R2xQ7cVLnB6gb21JoO7LTtRd12rh2-1vS7hv2DoZl',
    },
    {
      'name': 'Kenyatta University',
      'logo': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCV7Lro8VWDLsE_FhWbicwxIUdLZ6n4gfjt3C_Uue-EaXXmLx6A09sMe_aMhoVMRxxiW6OgBlHmyv5Q9_RX2F46ItRSMcDE_vyG8yMm5zxCuu8-zqhlSY09o0G1DPeX4jYxGnmJrEOUZllXbVu_Ky0NMPtI59UrwmBKAqb5C3id-G7F4Xp3830wzLHukTVd0AmdWwyD73itd9rdpRdGxSiEEOrIPXH5h--Nd6FWn5rLaA6nqCuyaWhuQw5lzsm0yQbKQRs6xECGsEd0',
    },
    {
      'name': 'Moi University',
      'logo': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBCyUxOQfDD9KvUVUbj1VEtheY6mcUEC4SDCjXxfGm0iuTcGbwkHWM6EDS4Mr45BbuFA7YykSvsFQYzcE4tCZ16sFocRLe0O1XqP2Gd5P849z-FR7D7C3SWAaPUxe2VXkFgmXmtgblAl9hWNBec50NT1T0umO4sJpEvhBGFJmJe0HXP9ia7eRwWVyghMHROdlC2FlR7iChDj80DkxLj9dTHnQQp7YVBFXkZjeQMDVxaagwd6BTZEn4BrRscyUmp3OTGCAMuOoU4P7_r',
    },
    {
      'name': 'Egerton University',
      'logo': 'https://lh3.googleusercontent.com/aida-public/AB6AXuA36WevzZJZ1cW_aU3Ala0iUEW8eWTgcCW06md27Ou7oKpI7SlOw6bM288IDeoQ3pYh2w-KPUXhFluD-194EWmd4xbRA9ED9PUW4_g4Nte0X1r5qKEPQZhfX9_VYOCuR29IwPmsC2s2OlX16lsbCQWSzeivRbV9VamX9_-gBlCkGcPZ1nVuVzvS9dO3UzWRZBtSiZ3qV9HNr1WPe2TtuQbr_t01sA0Sg50pBFlhI-vYP_JXs0wjuGy9ncc7tLmoS9toLLoXeEs62NI0',
    },
    {
      'name': 'Jomo Kenyatta University of Agriculture and Technology',
      'logo': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDTlkvMXW9Iz4iARLFSlhBNOrVcbCbYYMrTmbAiA9Y7bIFiz-_KAHiRB6RJ9gM3pBDLw4cSIdAmZV2bPydexk86KCkZFPRQNOVsE99fAETj4joZUHgZRkSYA5jNRLVkAPw1dnX5RjD897kc_TixQaLXuO_L51VUEa4lC9yi0088KyL70hpF77zozdMghbONHjb_-6405jrOoq5MXniXA5gcMhRLoy_U6LVRpIz_7tVuGfuiq8kcUerKLUEVH7O8cimfydOyuOPz6i0E',
    },
    {
      'name': 'Maseno University',
      'logo': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAI34gA1utFKxP0wnoQoMPCa7V3RQPdRRMJ7e3cmVYC2A8CUKX_D7CAQFgbVDS6jW5gdGM-uSxbbm3VrcIce08twisf8rT-9ISm_TGii0CifTQ344ZKUZf6AMFUAedL_0NPUDnQrOWoSOwdqsTWJ9psmq_0AQiuKWcWwuajaA9ktZDRqty1dkfLgKdXktA7AvYNDHJXuYdSW92sCVj6FoN1BYIwGRL4jMXhGa3UpzZ_5WVHa0Iuh4emJWcwSOvoU6bLXAqY5pMOF_WV',
    },
    {
      'name': 'Strathmore University',
      'logo': 'https://lh3.googleusercontent.com/aida-public/AB6AXuC-bkf0eZXvRbYdr6143OEVpm3NT9sboFNQc5j4PdQTq6X_LzmQMwjVIZmOPhZ4ofZuST9hP8RsVL_rlAO8zCNzI3gxjAeqyRqWO8PITwnIHJtB1sbwQTzlidb6kudzhExak8k8cGnxgeKQXwrAhDTPelDfPgVhD4rA_WkyMBzUW58bQha2bU4JFSeYNFyTATFJxV4WTdFrrbTkKUqXjeHtZ_5Hx6ZZ7d7o_pkGxSgssBg2LgloSN4n9jjn0zzfwWlWlhksX0S1wM4K',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedUniversity = widget.selectedUniversity;
    _filteredUniversities = _universities;
    _searchController.addListener(_filterUniversities);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterUniversities() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUniversities = _universities;
      } else {
        _filteredUniversities = _universities
            .where((uni) => uni['name']!.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _confirmSelection() async {
    if (_selectedUniversity != null) {
      // Save the selected university
      await UniversityService.saveSelectedUniversity(_selectedUniversity!);
      
      // Navigate back or to home (check mounted before using context)
      if (!mounted) return;
      
      if (widget.isFromOnboarding) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pop(context, _selectedUniversity);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? Colors.white : kTextPrimary;
    final secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;

    return Scaffold(
      backgroundColor: isDarkMode ? kBackgroundColorDark : kBackgroundColorLight,
      body: ResponsiveBuilder(
        builder: (context, screenSize) {
          return Column(
            children: [
              // Top App Bar
              _buildTopAppBar(context, primaryTextColor, screenSize),
              
              // Search Bar
              _buildSearchBar(
                context,
                primaryTextColor,
                secondaryTextColor,
                borderColor,
                isDarkMode,
                screenSize,
              ),

              // University List
              Expanded(
                child: _buildUniversityList(
                  context,
                  primaryTextColor,
                  borderColor,
                  isDarkMode,
                  screenSize,
                ),
              ),

              // Bottom CTA
              _buildBottomCTA(context, isDarkMode, screenSize),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context, Color primaryTextColor, ScreenSize screenSize) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        screenSize == ScreenSize.expanded ? 24.0 : 48.0,
        horizontalPadding,
        8.0,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: primaryTextColor),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Select Your University',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
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
          SizedBox(
            width: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 48.0,
              medium: 48.0,
              expanded: 48.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color borderColor,
    bool isDarkMode,
    ScreenSize screenSize,
  ) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        12.0,
        horizontalPadding,
        ResponsiveBreakpoints.responsiveValue(
          context,
          compact: 12.0,
          medium: 16.0,
          expanded: 20.0,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => _filterUniversities(),
        style: GoogleFonts.plusJakartaSans(
          color: primaryTextColor,
          fontSize: ResponsiveBreakpoints.responsiveValue(
            context,
            compact: 16.0,
            medium: 17.0,
            expanded: 18.0,
          ),
        ),
        decoration: InputDecoration(
          hintText: 'Search universities...',
          hintStyle: GoogleFonts.plusJakartaSans(
            color: secondaryTextColor,
            fontSize: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 16.0,
              medium: 17.0,
              expanded: 18.0,
            ),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: secondaryTextColor,
            size: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 24.0,
              medium: 26.0,
              expanded: 28.0,
            ),
          ),
          filled: true,
          fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9999),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9999),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9999),
            borderSide: BorderSide(color: kPrimaryColor, width: 2.0),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 20.0,
              medium: 24.0,
              expanded: 28.0,
            ),
            vertical: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 16.0,
              medium: 18.0,
              expanded: 20.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUniversityList(
    BuildContext context,
    Color primaryTextColor,
    Color borderColor,
    bool isDarkMode,
    ScreenSize screenSize,
  ) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(context);
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: ResponsiveBreakpoints.responsiveValue(
          context,
          compact: 8.0,
          medium: 12.0,
          expanded: 16.0,
        ),
      ),
      itemCount: _filteredUniversities.length,
      itemBuilder: (context, index) {
        final university = _filteredUniversities[index];
        final isSelected = _selectedUniversity == university['name'];
        
        return Padding(
          padding: EdgeInsets.only(
            bottom: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 8.0,
              medium: 10.0,
              expanded: 12.0,
            ),
          ),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedUniversity = university['name'];
              });
            },
            child: Container(
              constraints: BoxConstraints(
                minHeight: ResponsiveBreakpoints.responsiveValue(
                  context,
                  compact: 56.0,
                  medium: 64.0,
                  expanded: 72.0,
                ),
              ),
              padding: EdgeInsets.all(
                ResponsiveBreakpoints.responsiveValue(
                  context,
                  compact: 16.0,
                  medium: 18.0,
                  expanded: 20.0,
                ),
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? kPrimaryColor.withValues(alpha: isDarkMode ? 0.2 : 0.1)
                    : (isDarkMode ? kBackgroundColorDark : kBackgroundColorLight),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: isSelected ? kPrimaryColor : Colors.transparent,
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  // University Logo
                  Container(
                    width: ResponsiveBreakpoints.responsiveValue(
                      context,
                      compact: 40.0,
                      medium: 44.0,
                      expanded: 48.0,
                    ),
                    height: ResponsiveBreakpoints.responsiveValue(
                      context,
                      compact: 40.0,
                      medium: 44.0,
                      expanded: 48.0,
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kPrimaryColor.withValues(alpha: 0.3),
                    ),
                    child: ClipOval(
                      child: NetworkImageWithFallback(
                        imageUrl: university['logo']!,
                        width: ResponsiveBreakpoints.responsiveValue(
                          context,
                          compact: 40.0,
                          medium: 44.0,
                          expanded: 48.0,
                        ),
                        height: ResponsiveBreakpoints.responsiveValue(
                          context,
                          compact: 40.0,
                          medium: 44.0,
                          expanded: 48.0,
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: ResponsiveBreakpoints.responsiveValue(
                      context,
                      compact: 16.0,
                      medium: 20.0,
                      expanded: 24.0,
                    ),
                  ),
                  // University Name
                  Expanded(
                    child: Text(
                      university['name']!,
                      style: GoogleFonts.plusJakartaSans(
                        color: primaryTextColor,
                        fontSize: ResponsiveBreakpoints.responsiveValue(
                          context,
                          compact: 16.0,
                          medium: 17.0,
                          expanded: 18.0,
                        ),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: ResponsiveBreakpoints.responsiveValue(
                      context,
                      compact: 12.0,
                      medium: 16.0,
                      expanded: 20.0,
                    ),
                  ),
                  // Selection Indicator
                  Container(
                    width: ResponsiveBreakpoints.responsiveValue(
                      context,
                      compact: 24.0,
                      medium: 28.0,
                      expanded: 32.0,
                    ),
                    height: ResponsiveBreakpoints.responsiveValue(
                      context,
                      compact: 24.0,
                      medium: 28.0,
                      expanded: 32.0,
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? kPrimaryColor : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? kPrimaryColor : borderColor,
                        width: 2.0,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: kBackgroundColorDark,
                            size: ResponsiveBreakpoints.responsiveValue(
                              context,
                              compact: 16.0,
                              medium: 18.0,
                              expanded: 20.0,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomCTA(BuildContext context, bool isDarkMode, ScreenSize screenSize) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(context);
    return Container(
      padding: EdgeInsets.all(horizontalPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            (isDarkMode ? kBackgroundColorDark : kBackgroundColorLight).withValues(alpha: 0.95),
            isDarkMode ? kBackgroundColorDark : kBackgroundColorLight,
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: double.infinity,
              medium: 500.0,
              expanded: 600.0,
            ),
          ),
          child: SizedBox(
            width: ResponsiveBreakpoints.isCompact(context) ? double.infinity : null,
            height: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 56.0,
              medium: 52.0,
              expanded: 54.0,
            ),
            child: ElevatedButton(
              onPressed: _selectedUniversity != null ? _confirmSelection : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: kBackgroundColorDark,
                disabledBackgroundColor: kPrimaryColor.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: ResponsiveBreakpoints.responsiveValue(
                  context,
                  compact: 4.0,
                  medium: 5.0,
                  expanded: 6.0,
                ),
              ),
              child: Text(
                'Confirm Selection',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: ResponsiveBreakpoints.responsiveValue(
                    context,
                    compact: 16.0,
                    medium: 17.0,
                    expanded: 18.0,
                  ),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

