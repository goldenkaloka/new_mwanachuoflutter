import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/core/widgets/app_background.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_event.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';
import 'package:mwanachuo/features/auth/presentation/widgets/auth_text_field.dart';

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  State<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _programNameController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToPolicy = false;

  // Dropdown selections
  String? _selectedUniversityId;
  String? _selectedCourseId;
  int? _selectedYear;
  int? _selectedSemester;

  // Dropdown data
  List<Map<String, dynamic>> _universities = [];
  List<Map<String, dynamic>> _courses = [];
  final List<int> _years = [1, 2, 3, 4, 5, 6, 7];
  final List<int> _semesters = [1, 2];

  bool _isLoadingUniversities = false;
  bool _isLoadingCourses = false;

  @override
  void initState() {
    super.initState();
    _loadUniversities();
  }

  Future<void> _loadUniversities() async {
    setState(() => _isLoadingUniversities = true);
    try {
      final supabaseClient = sl<supabase.SupabaseClient>();
      final response = await supabaseClient
          .from('universities')
          .select('id, name')
          .order('name');

      setState(() {
        _universities = List<Map<String, dynamic>>.from(response);
        _isLoadingUniversities = false;
      });
    } catch (e) {
      setState(() => _isLoadingUniversities = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load universities: $e')),
        );
      }
    }
  }

  Future<void> _loadCourses(String universityId) async {
    debugPrint('🔍 Loading courses for university: $universityId');
    setState(() {
      _isLoadingCourses = true;
      _courses = [];
      _selectedCourseId = null;
    });

    try {
      final supabaseClient = sl<supabase.SupabaseClient>();
      final response = await supabaseClient
          .from('courses')
          .select('id, name')
          .eq('university_id', universityId)
          .order('name');

      debugPrint('📚 Loaded ${response.length} courses');
      debugPrint('Courses: $response');

      setState(() {
        _courses = List<Map<String, dynamic>>.from(response);
        _isLoadingCourses = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading courses: $e');
      setState(() => _isLoadingCourses = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load courses: $e')));
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _programNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

    context.read<AuthBloc>().add(
      SignUpEvent(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name:
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        phone: _phoneController.text.trim(),
        programName: _programNameController.text.trim(),
        userType: 'student',
        universityId: _selectedUniversityId,
        enrolledCourseId: _selectedCourseId,
        yearOfStudy: _selectedYear,
        currentSemester: _selectedSemester,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // Navigate directly to home after successful registration
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
                            'Student Registration',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Fill in your details to join',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Name Row
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

                          // University Dropdown
                          _buildSearchableDropdown(
                            label: 'University',
                            value: _selectedUniversityId,
                            items: _universities,
                            onChanged: (value) {
                              debugPrint('🏫 University selected: $value');
                              setState(() {
                                _selectedUniversityId = value;
                                _loadCourses(value);
                              });
                            },
                            hint: 'Select your university',
                            icon: Icons.school,
                            isDarkMode: isDarkMode,
                            isLoading: _isLoadingUniversities,
                          ),
                          const SizedBox(height: 16),

                          // Course Dropdown
                          _buildSearchableDropdown(
                            label: 'Course / Program',
                            value: _selectedCourseId,
                            items: _courses,
                            onChanged: (value) {
                              setState(() => _selectedCourseId = value);
                            },
                            hint: _selectedUniversityId == null
                                ? 'Select university first'
                                : 'Select your course',
                            icon: Icons.book,
                            isDarkMode: isDarkMode,
                            isLoading: _isLoadingCourses,
                            isDisabled: _selectedUniversityId == null,
                          ),
                          const SizedBox(height: 16),

                          // Year and Semester Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdownField<int>(
                                  label: 'Year of Study',
                                  value: _selectedYear,
                                  items: _years
                                      .map(
                                        (year) => DropdownMenuItem<int>(
                                          value: year,
                                          child: Text('Year $year'),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() => _selectedYear = value);
                                  },
                                  hint: 'Select year',
                                  icon: Icons.calendar_today,
                                  isDarkMode: isDarkMode,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDropdownField<int>(
                                  label: 'Semester',
                                  value: _selectedSemester,
                                  items: _semesters
                                      .map(
                                        (sem) => DropdownMenuItem<int>(
                                          value: sem,
                                          child: Text('Semester $sem'),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() => _selectedSemester = value);
                                  },
                                  hint: 'Select',
                                  icon: Icons.event_note,
                                  isDarkMode: isDarkMode,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Email
                          AuthTextField(
                            controller: _emailController,
                            label: 'Email',
                            hintText: 'example@email.com',
                            prefixIcon: Icons.email_outlined,
                            isDarkMode: isDarkMode,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),

                          // Phone
                          AuthTextField(
                            controller: _phoneController,
                            label: 'Phone number',
                            hintText: '0712 345 678',
                            prefixIcon: Icons.phone_outlined,
                            isDarkMode: isDarkMode,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),

                          // Password
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

                          // Confirm Password
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

                          // Privacy Policy Checkbox
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
                                          color: Color(0xFF00897B),
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

                          // Signup Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: authState is AuthLoading
                                  ? null
                                  : _handleSignup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00897B),
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
                                      'Register Student',
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
    bool isLoading = false,
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
          onChanged: isLoading ? null : onChanged,
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
            suffixIcon: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
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

  Widget _buildSearchableDropdown({
    required String label,
    required String? value,
    required List<Map<String, dynamic>> items,
    required void Function(String) onChanged,
    required String hint,
    required IconData icon,
    required bool isDarkMode,
    bool isLoading = false,
    bool isDisabled = false,
  }) {
    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.grey[300]!;
    final fillColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.grey[50]!;

    // Find selected name
    String? selectedName;
    if (value != null) {
      try {
        final selectedItem = items.firstWhere(
          (item) => (item['id'] as String) == value,
        );
        selectedName = selectedItem['name'] as String;
      } catch (_) {}
    }

    return FormField<String>(
      initialValue: value,
      validator: (val) {
        if (val == null || val.isEmpty) {
          return 'Please select $label';
        }
        return null;
      },
      builder: (FormFieldState<String> state) {
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
            InkWell(
              onTap: (isLoading || isDisabled)
                  ? null
                  : () => _showSearchableSelectionSheet(
                      label: label,
                      items: items,
                      onSelect: (newValue) {
                        state.didChange(newValue);
                        onChanged(newValue);
                      },
                      isDarkMode: isDarkMode,
                    ),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: fillColor,
                  border: Border.all(
                    color: state.hasError ? Colors.redAccent : borderColor,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selectedName ?? hint,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: selectedName != null
                              ? FontWeight.w500
                              : FontWeight.normal,
                          color: selectedName != null
                              ? (isDarkMode ? Colors.white : Colors.black87)
                              : (isDarkMode
                                    ? Colors.grey[500]
                                    : Colors.grey[600]),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                      ),
                  ],
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Text(
                  state.errorText!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.redAccent,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showSearchableSelectionSheet({
    required String label,
    required List<Map<String, dynamic>> items,
    required void Function(String) onSelect,
    required bool isDarkMode,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _SearchableSelectionSheetContent(
          label: label,
          items: items,
          onSelect: onSelect,
          isDarkMode: isDarkMode,
        );
      },
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

class _SearchableSelectionSheetContent extends StatefulWidget {
  final String label;
  final List<Map<String, dynamic>> items;
  final void Function(String) onSelect;
  final bool isDarkMode;

  const _SearchableSelectionSheetContent({
    required this.label,
    required this.items,
    required this.onSelect,
    required this.isDarkMode,
  });

  @override
  State<_SearchableSelectionSheetContent> createState() =>
      _SearchableSelectionSheetContentState();
}

class _SearchableSelectionSheetContentState
    extends State<_SearchableSelectionSheetContent> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items.where((item) {
        final name = (item['name'] as String).toLowerCase();
        return name.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.isDarkMode ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title and Close
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select ${widget.label}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.plusJakartaSans(
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Search ${widget.label}...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: widget.isDarkMode
                        ? Colors.grey[500]
                        : Colors.grey[400],
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: widget.isDarkMode
                        ? Colors.grey[500]
                        : Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: widget.isDarkMode
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            // List
            Expanded(
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Text(
                        'No results found',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return ListTile(
                          title: Text(
                            item['name'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              color: widget.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () {
                            widget.onSelect(item['id'] as String);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
