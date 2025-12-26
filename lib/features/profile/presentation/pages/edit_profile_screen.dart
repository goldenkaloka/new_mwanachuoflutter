import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/core/widgets/network_image_with_fallback.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:mwanachuo/features/profile/presentation/bloc/profile_event.dart';
import 'package:mwanachuo/features/profile/presentation/bloc/profile_state.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ProfileBloc>()..add(LoadMyProfileEvent()),
      child: const _EditProfileView(),
    );
  }
}

class _EditProfileView extends StatefulWidget {
  const _EditProfileView();

  @override
  State<_EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<_EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  File? _selectedImage;
  String? _currentAvatarUrl;
  String? _selectedUniversityId;
  String? _selectedUniversityName;
  bool _hasInitialized = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      // Check if running on desktop (Windows, macOS, Linux)
      final isDesktop =
          !kIsWeb &&
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

      if (isDesktop) {
        // Use file_picker for desktop platforms
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          dialogTitle: 'Select profile picture',
        );

        if (result != null && result.files.single.path != null) {
          setState(() {
            _selectedImage = File(result.files.single.path!);
          });
        }
      } else {
        // Use WeChat Assets Picker for mobile platforms
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        final List<AssetEntity>? result = await AssetPicker.pickAssets(
          context,
          pickerConfig: AssetPickerConfig(
            maxAssets: 1,
            requestType: RequestType.image,
            textDelegate: const EnglishAssetPickerTextDelegate(),
            pickerTheme: ThemeData(
              brightness: isDarkMode ? Brightness.dark : Brightness.light,
              primaryColor: kPrimaryColor,
              scaffoldBackgroundColor: isDarkMode
                  ? kBackgroundColorDark
                  : Colors.white,
              appBarTheme: AppBarTheme(
                backgroundColor: isDarkMode
                    ? kBackgroundColorDark
                    : Colors.white,
                foregroundColor: isDarkMode ? Colors.white : Colors.black,
                elevation: 0,
                iconTheme: IconThemeData(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              colorScheme: ColorScheme.fromSeed(
                seedColor: kPrimaryColor,
                brightness: isDarkMode ? Brightness.dark : Brightness.light,
              ),
            ),
            gridCount: 4,
            pageSize: 80,
            pathNameBuilder: (path) {
              if (path.name == 'Recent') return 'Camera Roll';
              if (path.name == 'Screenshots') return 'Screenshots';
              return path.name;
            },
          ),
        );

        if (result != null && result.isNotEmpty) {
          final File? file = await result.first.file;
          if (file != null && mounted) {
            setState(() {
              _selectedImage = file;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to pick image: $e',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      // Always send at least the full name, even if empty (to ensure update happens)
      final fullName = _fullNameController.text.trim();
      final phoneNumber = _phoneNumberController.text.trim();
      final bio = _bioController.text.trim();
      final location = _locationController.text.trim();

      context.read<ProfileBloc>().add(
        UpdateProfileEvent(
          fullName: fullName.isEmpty ? null : fullName,
          phoneNumber: phoneNumber.isEmpty ? null : phoneNumber,
          bio: bio.isEmpty ? null : bio,
          location: location.isEmpty ? null : location,
          avatarImage: _selectedImage,
          primaryUniversityId: _selectedUniversityId,
          universityName: _selectedUniversityName,
        ),
      );
    } else {
      // Form validation failed - show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fix the errors in the form',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? Colors.white : kTextPrimary;
    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.2)
        : const Color(0xFFDBE6E0);

    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded && !_hasInitialized) {
          // Initialize controllers with loaded data only once
          _fullNameController.text = state.profile.fullName;
          _phoneNumberController.text = state.profile.phoneNumber ?? '';
          _bioController.text = state.profile.bio ?? '';
          _locationController.text = state.profile.location ?? '';
          _currentAvatarUrl = state.profile.avatarUrl;
          _selectedUniversityId = state.profile.universityId;
          _selectedUniversityName = state.profile.universityName;
          _hasInitialized = true;
        } else if (state is ProfileUpdated) {
          // Show success message and navigate back with result
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Profile updated successfully!',
                style: GoogleFonts.plusJakartaSans(),
              ),
              backgroundColor: kPrimaryColor,
            ),
          );
          // Pass true to indicate profile was updated
          Navigator.pop(context, true);
        } else if (state is ProfileError) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: GoogleFonts.plusJakartaSans(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ProfileLoading) {
          return Scaffold(
            backgroundColor: isDarkMode
                ? kBackgroundColorDark
                : kBackgroundColorLight,
            body: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: isDarkMode
              ? kBackgroundColorDark
              : kBackgroundColorLight,
          body: ResponsiveBuilder(
            builder: (context, screenSize) {
              return Column(
                children: [
                  // Top App Bar
                  _buildTopAppBar(context, primaryTextColor, screenSize),

                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: ResponsiveContainer(
                        child: Column(
                          children: [
                            // Profile Header
                            _buildProfileHeader(
                              context,
                              primaryTextColor,
                              screenSize,
                            ),

                            // Form Fields
                            _buildFormFields(
                              context,
                              primaryTextColor,
                              borderColor,
                              isDarkMode,
                              screenSize,
                            ),

                            // Bottom spacing for sticky button
                            SizedBox(
                              height: ResponsiveBreakpoints.responsiveValue(
                                context,
                                compact: 100.0,
                                medium: 120.0,
                                expanded: 140.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Save Button (Sticky)
                  _buildSaveButton(
                    context,
                    isDarkMode,
                    screenSize,
                    state is ProfileUpdating,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTopAppBar(
    BuildContext context,
    Color primaryTextColor,
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
      ),
      child: Row(
        children: [
          SizedBox(
            width: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 48.0,
              medium: 52.0,
              expanded: 56.0,
            ),
            height: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 48.0,
              medium: 52.0,
              expanded: 56.0,
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: primaryTextColor),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
          ),
          Expanded(
            child: Text(
              'Edit Profile',
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
              medium: 52.0,
              expanded: 56.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    Color primaryTextColor,
    ScreenSize screenSize,
  ) {
    final profileSize = ResponsiveBreakpoints.responsiveValue(
      context,
      compact: 128.0,
      medium: 136.0,
      expanded: 160.0,
    );

    return Padding(
      padding: EdgeInsets.all(
        ResponsiveBreakpoints.responsiveHorizontalPadding(context),
      ),
      child: Column(
        children: [
          SizedBox(
            height: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 16.0,
              medium: 20.0,
              expanded: 24.0,
            ),
          ),
          // Profile Picture
          Container(
            width: profileSize,
            height: profileSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kPrimaryColor.withValues(alpha: 0.3),
            ),
            child: ClipOval(
              child: _selectedImage != null
                  ? Image.file(
                      _selectedImage!,
                      width: profileSize,
                      height: profileSize,
                      fit: BoxFit.cover,
                    )
                  : NetworkImageWithFallback(
                      imageUrl: _currentAvatarUrl ?? '',
                      width: profileSize,
                      height: profileSize,
                      fit: BoxFit.cover,
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
          // Change Photo Button
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ResponsiveBreakpoints.responsiveValue(
                  context,
                  compact: double.infinity,
                  medium: 480.0,
                  expanded: 480.0,
                ),
              ),
              child: SizedBox(
                width: ResponsiveBreakpoints.isCompact(context)
                    ? double.infinity
                    : null,
                height: ResponsiveBreakpoints.responsiveValue(
                  context,
                  compact: 40.0,
                  medium: 44.0,
                  expanded: 48.0,
                ),
                child: ElevatedButton(
                  onPressed: () {
                    // Handle change photo
                    _showChangePhotoOptions(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor.withValues(alpha: 0.2),
                    foregroundColor: primaryTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveBreakpoints.responsiveValue(
                        context,
                        compact: 16.0,
                        medium: 20.0,
                        expanded: 24.0,
                      ),
                    ),
                  ),
                  child: Text(
                    'Change Photo',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: ResponsiveBreakpoints.responsiveValue(
                        context,
                        compact: 14.0,
                        medium: 15.0,
                        expanded: 16.0,
                      ),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.015,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields(
    BuildContext context,
    Color primaryTextColor,
    Color borderColor,
    bool isDarkMode,
    ScreenSize screenSize,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveBreakpoints.responsiveHorizontalPadding(context),
        vertical: ResponsiveBreakpoints.responsiveValue(
          context,
          compact: 12.0,
          medium: 16.0,
          expanded: 20.0,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Full Name Field
            _buildTextField(
              context,
              label: 'Full Name',
              controller: _fullNameController,
              placeholder: 'e.g., Jane Doe',
              primaryTextColor: primaryTextColor,
              borderColor: borderColor,
              isDarkMode: isDarkMode,
              screenSize: screenSize,
            ),

            SizedBox(
              height: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 12.0,
                medium: 16.0,
                expanded: 20.0,
              ),
            ),

            // Bio Field
            _buildTextField(
              context,
              label: 'Bio',
              controller: _bioController,
              placeholder: 'Tell us about yourself',
              primaryTextColor: primaryTextColor,
              borderColor: borderColor,
              isDarkMode: isDarkMode,
              screenSize: screenSize,
              maxLines: 4,
              isRequired: false,
            ),

            SizedBox(
              height: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 12.0,
                medium: 16.0,
                expanded: 20.0,
              ),
            ),

            // Location Field
            _buildTextField(
              context,
              label: 'Location',
              controller: _locationController,
              placeholder: 'e.g., Nairobi, Kenya',
              primaryTextColor: primaryTextColor,
              borderColor: borderColor,
              isDarkMode: isDarkMode,
              screenSize: screenSize,
              isRequired: false,
            ),

            SizedBox(
              height: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 12.0,
                medium: 16.0,
                expanded: 20.0,
              ),
            ),

            // University Selection Field
            _buildUniversityField(
              context,
              primaryTextColor,
              borderColor,
              isDarkMode,
              screenSize,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUniversityField(
    BuildContext context,
    Color primaryTextColor,
    Color borderColor,
    bool isDarkMode,
    ScreenSize screenSize,
  ) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: ResponsiveBreakpoints.responsiveValue(
          context,
          compact: double.infinity,
          medium: 480.0,
          expanded: 480.0,
        ),
      ),
      child: Column(
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
              'University',
              style: GoogleFonts.plusJakartaSans(
                color: primaryTextColor,
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
          InkWell(
            onTap: () async {
              final result = await Navigator.pushNamed(
                context,
                '/university-selection',
                arguments: {'selectedUniversity': _selectedUniversityName},
              );

              if (result != null && result is String) {
                // Mapping names to IDs for database update
                final Map<String, String> universityMap = {
                  'University of Dar es Salaam':
                      '9f0462c3-5b37-409d-9030-af396e9e7b30',
                  'Sokoine University of Agriculture':
                      '0a2ab3af-4ef5-456d-bcca-38920b14d103',
                  'Muhimbili University of Health and Allied Sciences':
                      'edb05f53-f2ec-49f4-833d-e91def6bbd3b',
                  'University of Dodoma':
                      '2d4e21b0-17d7-4310-bc83-9c694c9bb74c',
                  'Ardhi University': '23530896-b8da-463f-9f79-5932d6b62f61',
                  'Nelson Mandela African Institution of Science and Technology':
                      '0a2a6c44-347f-40f9-ad48-e9493440c27d',
                  'Mzumbe University': '97ecdf6c-a7f9-4901-a4d8-cad7f4fdb2ac',
                };

                setState(() {
                  _selectedUniversityName = result;
                  _selectedUniversityId = universityMap[result];
                });
              }
            },
            child: Container(
              padding: EdgeInsets.all(
                ResponsiveBreakpoints.responsiveValue(
                  context,
                  compact: 15.0,
                  medium: 16.0,
                  expanded: 18.0,
                ),
              ),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? kBackgroundColorDark.withValues(alpha: 0.5)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedUniversityName ?? 'Select University',
                      style: GoogleFonts.plusJakartaSans(
                        color: _selectedUniversityName != null
                            ? primaryTextColor
                            : Colors.grey[600],
                        fontSize: ResponsiveBreakpoints.responsiveValue(
                          context,
                          compact: 16.0,
                          medium: 17.0,
                          expanded: 18.0,
                        ),
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required Color primaryTextColor,
    required Color borderColor,
    required bool isDarkMode,
    required ScreenSize screenSize,
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: ResponsiveBreakpoints.responsiveValue(
          context,
          compact: double.infinity,
          medium: 480.0,
          expanded: 480.0,
        ),
      ),
      child: Column(
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
                color: primaryTextColor,
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
            maxLines: maxLines,
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
              hintText: placeholder,
              hintStyle: GoogleFonts.plusJakartaSans(
                color: Colors.grey[600],
                fontSize: ResponsiveBreakpoints.responsiveValue(
                  context,
                  compact: 16.0,
                  medium: 17.0,
                  expanded: 18.0,
                ),
              ),
              filled: true,
              fillColor: isDarkMode
                  ? kBackgroundColorDark.withValues(alpha: 0.5)
                  : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide(color: kPrimaryColor, width: 2.0),
              ),
              contentPadding: EdgeInsets.all(
                ResponsiveBreakpoints.responsiveValue(
                  context,
                  compact: 15.0,
                  medium: 16.0,
                  expanded: 18.0,
                ),
              ),
            ),
            validator: isRequired
                ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter $label';
                    }
                    return null;
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(
    BuildContext context,
    bool isDarkMode,
    ScreenSize screenSize,
    bool isLoading,
  ) {
    return Container(
      padding: EdgeInsets.all(
        ResponsiveBreakpoints.responsiveHorizontalPadding(context),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            top: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 8.0,
              medium: 12.0,
              expanded: 16.0,
            ),
            bottom: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 16.0,
              medium: 20.0,
              expanded: 24.0,
            ),
          ),
          child: Padding(
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
                    medium: 480.0,
                    expanded: 480.0,
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48.0, // M3 standard button height
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              _saveChanges(context);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: kBackgroundColorDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          24.0,
                        ), // M3 standard
                      ),
                      elevation: 2.0, // M3 standard elevation
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                      ), // M3 standard
                      minimumSize: const Size(
                        64,
                        40,
                      ), // M3 minimum touch target
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Save Changes',
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
        ),
      ),
    );
  }

  void _showChangePhotoOptions(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? kBackgroundColorDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(
                'Choose from Gallery',
                style: GoogleFonts.plusJakartaSans(),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text('Take Photo', style: GoogleFonts.plusJakartaSans()),
              onTap: () async {
                Navigator.pop(context);
                // Use ImagePicker for direct camera capture
                final picker = ImagePicker();
                final pickedFile = await picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 1024,
                  maxHeight: 1024,
                  imageQuality: 85,
                );
                if (pickedFile != null && mounted) {
                  setState(() {
                    _selectedImage = File(pickedFile.path);
                  });
                }
              },
            ),
            if (_selectedImage != null || _currentAvatarUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  'Remove Photo',
                  style: GoogleFonts.plusJakartaSans(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                    // Note: You may want to add logic to delete the avatar from server
                  });
                },
              ),
            ListTile(
              title: Text(
                'Cancel',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                // Handle camera
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: Text('Cancel', style: GoogleFonts.plusJakartaSans()),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _saveChanges(BuildContext context) {
    _saveProfile();
  }
}
