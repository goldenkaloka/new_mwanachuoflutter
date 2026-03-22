import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';
import 'package:mwanachuo/features/food/presentation/bloc/food_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';

class RestaurantRegistrationPage extends StatefulWidget {
  const RestaurantRegistrationPage({super.key});

  @override
  State<RestaurantRegistrationPage> createState() => _RestaurantRegistrationPageState();
}

class _RestaurantRegistrationPageState extends State<RestaurantRegistrationPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedCategory = 'Fast Food';
  bool _isAdmin = false;
  String? _selectedSellerId;
  double? _selectedLat;
  double? _selectedLng;
  bool _isFetchingLocation = false;
  int _currentStep = 0;
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;


  final List<Map<String, dynamic>> _categoryData = [
    {'icon': Icons.local_fire_department_rounded, 'label': 'Fast Food', 'color': const Color(0xFFEF4444)},
    {'icon': Icons.emoji_food_beverage_rounded, 'label': 'Local', 'color': const Color(0xFFF59E0B)},
    {'icon': Icons.coffee_rounded, 'label': 'Cafe', 'color': const Color(0xFF8B5CF6)},
    {'icon': Icons.eco_rounded, 'label': 'Healthy', 'color': const Color(0xFF22C55E)},
    {'icon': Icons.cake_rounded, 'label': 'Bakery', 'color': const Color(0xFFEC4899)},
  ];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _checkPermissions() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final user = authState.user;
      setState(() {
        _isAdmin = user.isAdmin;
      });

      if (_isAdmin) {
        context.read<FoodBloc>().add(LoadSellersEvent());
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<FoodBloc, FoodState>(
      listener: (context, state) {
        if (state.status == FoodStatus.success && state.registrationSuccess) {
          _showSuccessSheet(context);
        } else if (state.status == FoodStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Registration failed')),
          );
        }
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? kBackgroundColorDark : const Color(0xFFF5F7FA),
        body: FadeTransition(
          opacity: _fadeAnim,
          child: _isAdmin
              ? _buildRegistrationFlow(isDarkMode)
              : _buildAccessDenied(isDarkMode),
        ),
      ),
    );
  }

  Widget _buildAccessDenied(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_person_rounded, size: 64, color: Colors.red),
            ),
            const SizedBox(height: 32),
            Text(
              'Access Denied',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Only administrators can register new restaurants to ensure student safety and platform health.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                minimumSize: const Size(200, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Go Back', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [kPrimaryColor, kPrimaryColorLight]),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: kPrimaryColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              Text('Submitted!', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'Your restaurant is under review.\nYou\'ll be notified once approved.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 15, color: kTextTertiary, height: 1.5),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text('Done', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ========================
  // REGISTRATION FLOW
  // ========================
  Widget _buildRegistrationFlow(bool isDarkMode) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(isDarkMode),
          _buildStepIndicator(isDarkMode),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _currentStep == 0
                  ? _buildStep1(isDarkMode)
                  : _buildStep2(isDarkMode),
            ),
          ),
          _buildBottomButton(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_currentStep > 0) {
                setState(() => _currentStep--);
              } else {
                Navigator.pop(context);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDarkMode ? kSurfaceColorDark : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDarkMode ? Colors.white10 : Colors.grey.shade200),
              ),
              child: Icon(Icons.arrow_back_rounded, color: isDarkMode ? Colors.white : kTextPrimary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Register Restaurant',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDarkMode ? Colors.white : kTextPrimary,
                  ),
                ),
                Text(
                  'Step ${_currentStep + 1} of 2',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: isDarkMode ? Colors.white54 : kTextTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: List.generate(2, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              margin: EdgeInsets.only(right: index < 1 ? 8 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: isActive
                    ? const LinearGradient(colors: [kPrimaryColor, kPrimaryColorLight])
                    : null,
                color: isActive ? null : (isDarkMode ? Colors.white10 : Colors.grey.shade200),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1(bool isDarkMode) {
    return SingleChildScrollView(
      key: const ValueKey('step1'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Restaurant Basics', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: isDarkMode ? Colors.white70 : kTextSecondary)),
            const SizedBox(height: 20),
            _buildPremiumField(
              controller: _nameController,
              label: 'Restaurant Name',
              hint: 'e.g. Campus Grill',
              icon: Icons.store_rounded,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 20),
            Text('Assign Owner (Business User)', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white54 : kTextTertiary)),
            const SizedBox(height: 12),
            BlocBuilder<FoodBloc, FoodState>(
              builder: (context, state) {
                if (state.status == FoodStatus.loading && state.sellers.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? kSurfaceColorDark : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isDarkMode ? Colors.white10 : Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSellerId,
                      hint: Text('Select a business user', style: GoogleFonts.plusJakartaSans(color: isDarkMode ? Colors.white24 : kTextDisabled, fontSize: 14)),
                      dropdownColor: isDarkMode ? kSurfaceColorDark : Colors.white,
                      items: state.sellers.map((seller) {
                        return DropdownMenuItem<String>(
                          value: seller['id'] as String,
                          child: Text(
                            '${seller['full_name']} (${seller['email']})',
                            style: GoogleFonts.plusJakartaSans(color: isDarkMode ? Colors.white : kTextPrimary, fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedSellerId = val),
                      validator: (val) => val == null ? 'Please select an owner' : null,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text('Restaurant Photo', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white54 : kTextTertiary)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDarkMode ? kSurfaceColorDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDarkMode ? Colors.white10 : Colors.grey.shade200),
                  image: _imageFile != null
                      ? DecorationImage(
                          image: FileImage(File(_imageFile!.path)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _imageFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_rounded, size: 40, color: kPrimaryColor.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'Tap to upload restaurant image',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: isDarkMode ? Colors.white38 : kTextTertiary,
                            ),
                          ),
                        ],
                      )
                    : Container(
                        alignment: Alignment.bottomRight,
                        padding: const EdgeInsets.all(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            // Category grid
            Text('Category', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white54 : kTextTertiary)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _categoryData.map((cat) {
                final isSelected = _selectedCategory == cat['label'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat['label'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(colors: [kPrimaryColor, kPrimaryColorLight])
                          : null,
                      color: isSelected ? null : (isDarkMode ? kSurfaceColorDark : Colors.white),
                      borderRadius: BorderRadius.circular(14),
                      border: isSelected ? null : Border.all(color: isDarkMode ? Colors.white10 : Colors.grey.shade200),
                      boxShadow: isSelected
                          ? [BoxShadow(color: kPrimaryColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat['icon'] as IconData, size: 18,
                            color: isSelected ? Colors.white : (cat['color'] as Color)),
                        const SizedBox(width: 8),
                        Text(
                          cat['label'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : (isDarkMode ? Colors.white70 : kTextPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _buildPremiumField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'What makes your food special?',
              icon: Icons.description_rounded,
              isDarkMode: isDarkMode,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2(bool isDarkMode) {
    return SingleChildScrollView(
      key: const ValueKey('step2'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contact & Location', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: isDarkMode ? Colors.white70 : kTextSecondary)),
          const SizedBox(height: 20),
          _buildPremiumField(
            controller: _phoneController,
            label: 'Contact Phone',
            hint: '+255 123 456 789',
            icon: Icons.phone_rounded,
            isDarkMode: isDarkMode,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildPremiumField(
            controller: _addressController,
            label: 'Physical Address',
            hint: 'Building, Floor, Unit...',
            icon: Icons.location_on_rounded,
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 24),
          // Map Selection / Location Picker
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? kSurfaceColorDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDarkMode ? Colors.white10 : Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_searching_rounded, color: kPrimaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Exact Coordinates', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(
                            _selectedLat != null 
                              ? '${_selectedLat!.toStringAsFixed(6)}, ${_selectedLng!.toStringAsFixed(6)}'
                              : 'No coordinates selected',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTextTertiary),
                          ),
                        ],
                      ),
                    ),
                    if (_isFetchingLocation)
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    else
                      TextButton(
                        onPressed: _getCurrentLocation,
                        child: Text(_selectedLat == null ? 'Get Current' : 'Refresh'),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDarkMode ? Colors.white10 : Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_rounded, size: 32, color: isDarkMode ? Colors.white24 : Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text(
                          'Location marked on grid',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: isDarkMode ? Colors.white38 : kTextDisabled,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDarkMode,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? kSurfaceColorDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.1 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: GoogleFonts.plusJakartaSans(
          color: isDarkMode ? Colors.white : kTextPrimary,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kPrimaryColor, size: 20),
          ),
          labelStyle: GoogleFonts.plusJakartaSans(color: isDarkMode ? Colors.white54 : kTextTertiary, fontSize: 14),
          hintStyle: GoogleFonts.plusJakartaSans(color: isDarkMode ? Colors.white24 : kTextDisabled, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _buildBottomButton(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            if (_currentStep == 0) {
              if (_nameController.text.isNotEmpty) {
                setState(() => _currentStep = 1);
              }
            } else {
              _handleSubmit();
            }
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 0,
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kPrimaryColor, kPrimaryColorLight]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryColor.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              alignment: Alignment.center,
              height: 56,
              child: BlocBuilder<FoodBloc, FoodState>(
                builder: (context, state) {
                  if (state.status == FoodStatus.loading) {
                    return const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    );
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _currentStep == 0 ? Icons.arrow_forward_rounded : Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _currentStep == 0 ? 'Continue' : 'Submit Registration',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Permission denied.';
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLat = position.latitude;
        _selectedLng = position.longitude;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  void _handleSubmit() {
    context.read<FoodBloc>().add(
          RegisterRestaurantEvent(
            name: _nameController.text,
            description: _descriptionController.text,
            address: _addressController.text,
            phone: _phoneController.text,
            category: _selectedCategory,
            imageFile: _imageFile != null ? File(_imageFile!.path) : null,
            ownerId: _selectedSellerId,
            lat: _selectedLat,
            lng: _selectedLng,
          ),
        );
  }
}
