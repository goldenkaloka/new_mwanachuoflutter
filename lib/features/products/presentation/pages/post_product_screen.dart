import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_bloc.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_event.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_state.dart';

class PostProductScreen extends StatefulWidget {
  const PostProductScreen({super.key});

  @override
  State<PostProductScreen> createState() => _PostProductScreenState();
}

class _PostProductScreenState extends State<PostProductScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String? _selectedCategory;
  String? _selectedCondition;
  final List<File> _selectedImages = [];

  final List<String> _categories = [
    'Select category',
    'Textbooks',
    'Electronics',
    'Furniture',
    'Notes & Supplies',
    'Other',
  ];

  final List<String> _conditions = [
    'Select condition',
    'New',
    'Used',
  ];

  @override
  void initState() {
    super.initState();
    _checkSellerAccess();
  }

  void _checkSellerAccess() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        final userRole = authState.user.role.value;
        
        if (userRole == 'buyer') {
          debugPrint('❌ Buyer attempting to post product - redirecting');
          Navigator.of(context).pop();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You need to become a seller to post products',
                style: GoogleFonts.plusJakartaSans(),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Request Access',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.pushNamed(context, '/become-seller');
                },
              ),
            ),
          );
        }
      }
    });
  }

  void _handlePostProduct() {
    // Validate all required fields
    if (_titleController.text.trim().isEmpty) {
      _showError('Please enter a product title');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showError('Please enter a product description');
      return;
    }

    if (_priceController.text.trim().isEmpty) {
      _showError('Please enter a price');
      return;
    }

    if (_selectedCategory == null || _selectedCategory == 'Select category') {
      _showError('Please select a category');
      return;
    }

    if (_selectedCondition == null || _selectedCondition == 'Select condition') {
      _showError('Please select a condition');
      return;
    }

    if (_locationController.text.trim().isEmpty) {
      _showError('Please enter a location');
      return;
    }

    if (_selectedImages.isEmpty) {
      _showError('Please add at least one image');
      return;
    }

    // Parse price
    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      _showError('Please enter a valid price');
      return;
    }

    // Dispatch create product event
    context.read<ProductBloc>().add(
          CreateProductEvent(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            price: price,
            category: _selectedCategory!,
            condition: _selectedCondition!,
            images: _selectedImages,
            location: _locationController.text.trim(),
          ),
        );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _handleImageUpload() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 5 images allowed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Calculate remaining slots
      final remainingSlots = 5 - _selectedImages.length;
      
      // Check if running on desktop (Windows, macOS, Linux)
      final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
      
      if (isDesktop) {
        // Use file_picker for desktop platforms
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: true,
          dialogTitle: 'Select product images (max $remainingSlots)',
        );
        
        if (result != null && result.files.isNotEmpty) {
          final List<File> newFiles = [];
          
          // Limit to remaining slots
          final filesToAdd = result.files.take(remainingSlots);
          
          for (var file in filesToAdd) {
            if (file.path != null) {
              newFiles.add(File(file.path!));
            }
          }
          
          if (newFiles.isNotEmpty) {
            setState(() {
              _selectedImages.addAll(newFiles);
            });
            
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${newFiles.length} image(s) added'),
                backgroundColor: kPrimaryColor,
              ),
            );
          }
        }
      } else {
        // Use WeChat Assets Picker for mobile platforms
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        
        final List<AssetEntity>? result = await AssetPicker.pickAssets(
          context,
          pickerConfig: AssetPickerConfig(
            maxAssets: remainingSlots,
            requestType: RequestType.image,
            textDelegate: const EnglishAssetPickerTextDelegate(),
            pickerTheme: ThemeData(
              brightness: isDarkMode ? Brightness.dark : Brightness.light,
              primaryColor: kPrimaryColor,
              scaffoldBackgroundColor: isDarkMode ? kBackgroundColorDark : Colors.white,
              appBarTheme: AppBarTheme(
                backgroundColor: isDarkMode ? kBackgroundColorDark : Colors.white,
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
            gridCount: 4, // 4 columns like Instagram
            pageSize: 80, // Items per page
            pathNameBuilder: (path) {
              // Customize album names
              if (path.name == 'Recent') return 'Camera Roll';
              if (path.name == 'Screenshots') return 'Screenshots';
              return path.name;
            },
            specialItemPosition: SpecialItemPosition.prepend,
            specialItemBuilder: (context, path, length) {
              // Add camera button at the top (optional)
              return GestureDetector(
                onTap: () async {
                  Navigator.of(context).pop();
                  // You can add camera functionality here if needed
                },
                child: Container(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  child: Center(
                    child: Icon(
                      Icons.camera_alt,
                      color: isDarkMode ? Colors.white : Colors.black54,
                      size: 32,
                    ),
                  ),
                ),
              );
            },
          ),
        );

        if (result != null && result.isNotEmpty) {
          // Convert AssetEntity to File
          final List<File> newFiles = [];
          for (var asset in result) {
            final File? file = await asset.file;
            if (file != null) {
              newFiles.add(file);
            }
          }

          if (newFiles.isNotEmpty) {
            setState(() {
              _selectedImages.addAll(newFiles);
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${newFiles.length} image(s) selected'),
                  backgroundColor: kPrimaryColor,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductCreating) {
          // Show loading dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (state is ProductCreated) {
          // Close loading dialog
          Navigator.of(context).pop();
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate back
          Navigator.of(context).pop();
        } else if (state is ProductError) {
          // Close loading dialog if open
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create product: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        body: ResponsiveBuilder(
          builder: (context, screenSize) {
            return Column(
              children: [
                // Header
                _buildHeader(isDarkMode, primaryTextColor, screenSize),
                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(
                      ResponsiveBreakpoints.responsiveHorizontalPadding(context),
                    ),
                    child: ResponsiveContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: ResponsiveBreakpoints.responsiveValue(
                              context,
                              compact: 16.0,
                              medium: 24.0,
                              expanded: 32.0,
                            ),
                          ),
                          // Photo Upload Section
                          _buildPhotoUploadSection(
                            isDarkMode,
                            primaryTextColor,
                            secondaryTextColor,
                            screenSize,
                          ),
                          SizedBox(
                            height: ResponsiveBreakpoints.responsiveValue(
                              context,
                              compact: 24.0,
                              medium: 32.0,
                              expanded: 40.0,
                            ),
                          ),
                          // Form Fields
                          _buildFormFields(
                            isDarkMode,
                            primaryTextColor,
                            secondaryTextColor,
                            screenSize,
                          ),
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
                // Footer Button
                _buildFooterButton(isDarkMode, primaryTextColor, screenSize),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode, Color primaryTextColor, ScreenSize screenSize) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(context);
    
    return SafeArea(
      child: Container(
        height: ResponsiveBreakpoints.responsiveValue(
          context,
          compact: 64.0,
          medium: 72.0,
          expanded: 80.0,
        ),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        decoration: BoxDecoration(
          color: isDarkMode ? kBackgroundColorDark : kBackgroundColorLight,
          border: Border(
            bottom: BorderSide(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: primaryTextColor,
                size: ResponsiveBreakpoints.responsiveValue(
                  context,
                  compact: 20.0,
                  medium: 22.0,
                  expanded: 24.0,
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            Text(
              'Post a New Product',
              style: GoogleFonts.plusJakartaSans(
                fontSize: ResponsiveBreakpoints.responsiveValue(
                  context,
                  compact: 18.0,
                  medium: 20.0,
                  expanded: 22.0,
                ),
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
            SizedBox(
              width: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 40.0,
                medium: 44.0,
                expanded: 48.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoUploadSection(
    bool isDarkMode,
    Color primaryTextColor,
    Color secondaryTextColor,
    ScreenSize screenSize,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Photos',
          style: GoogleFonts.plusJakartaSans(
            fontSize: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 16.0,
              medium: 17.0,
              expanded: 18.0,
            ),
            fontWeight: FontWeight.w600,
            color: primaryTextColor,
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
        InkWell(
          onTap: _handleImageUpload,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(
              ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 24.0,
                medium: 32.0,
                expanded: 40.0,
              ),
            ),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? kBackgroundColorDark.withValues(alpha: 0.5)
                  : Colors.white,
              border: Border.all(
                color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: kBaseRadius,
            ),
            child: _selectedImages.isEmpty
                ? Column(
                    children: [
                      Container(
                        width: ResponsiveBreakpoints.responsiveValue(
                          context,
                          compact: 48.0,
                          medium: 56.0,
                          expanded: 64.0,
                        ),
                        height: ResponsiveBreakpoints.responsiveValue(
                          context,
                          compact: 48.0,
                          medium: 56.0,
                          expanded: 64.0,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_photo_alternate,
                          size: ResponsiveBreakpoints.responsiveValue(
                            context,
                            compact: 24.0,
                            medium: 28.0,
                            expanded: 32.0,
                          ),
                          color: primaryTextColor,
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
                      Text(
                        'Tap to upload photos',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: ResponsiveBreakpoints.responsiveValue(
                            context,
                            compact: 14.0,
                            medium: 15.0,
                            expanded: 16.0,
                          ),
                          fontWeight: FontWeight.w500,
                          color: primaryTextColor,
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveBreakpoints.responsiveValue(
                          context,
                          compact: 4.0,
                          medium: 6.0,
                          expanded: 8.0,
                        ),
                      ),
                        Text(
                          'up to 5 images',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: ResponsiveBreakpoints.responsiveValue(
                              context,
                              compact: 12.0,
                              medium: 13.0,
                              expanded: 14.0,
                            ),
                            color: secondaryTextColor,
                          ),
                        ),
                    ],
                  )
                : Wrap(
                    spacing: ResponsiveBreakpoints.responsiveValue(
                      context,
                      compact: 8.0,
                      medium: 12.0,
                      expanded: 16.0,
                    ),
                    runSpacing: ResponsiveBreakpoints.responsiveValue(
                      context,
                      compact: 8.0,
                      medium: 12.0,
                      expanded: 16.0,
                    ),
                    children: [
                      ..._selectedImages.map((image) {
                        final index = _selectedImages.indexOf(image);
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: kBaseRadius,
                              child: Container(
                                width: ResponsiveBreakpoints.responsiveValue(
                                  context,
                                  compact: 80.0,
                                  medium: 100.0,
                                  expanded: 120.0,
                                ),
                                height: ResponsiveBreakpoints.responsiveValue(
                                  context,
                                  compact: 80.0,
                                  medium: 100.0,
                                  expanded: 120.0,
                                ),
                                decoration: BoxDecoration(
                                  color: kPrimaryColor.withValues(alpha: 0.2),
                                  borderRadius: kBaseRadius,
                                ),
                                child: Image.file(
                                  image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.broken_image,
                                      size: ResponsiveBreakpoints.responsiveValue(
                                        context,
                                        compact: 32.0,
                                        medium: 40.0,
                                        expanded: 48.0,
                                      ),
                                      color: primaryTextColor,
                                    );
                                  },
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedImages.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: ResponsiveBreakpoints.responsiveValue(
                                      context,
                                      compact: 16.0,
                                      medium: 18.0,
                                      expanded: 20.0,
                                    ),
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      if (_selectedImages.length < 5)
                        InkWell(
                          onTap: _handleImageUpload,
                          child: Container(
                            width: ResponsiveBreakpoints.responsiveValue(
                              context,
                              compact: 80.0,
                              medium: 100.0,
                              expanded: 120.0,
                            ),
                            height: ResponsiveBreakpoints.responsiveValue(
                              context,
                              compact: 80.0,
                              medium: 100.0,
                              expanded: 120.0,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.grey[600]!
                                    : Colors.grey[300]!,
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: kBaseRadius,
                            ),
                            child: Icon(
                              Icons.add,
                              size: ResponsiveBreakpoints.responsiveValue(
                                context,
                                compact: 32.0,
                                medium: 40.0,
                                expanded: 48.0,
                              ),
                              color: primaryTextColor,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields(
    bool isDarkMode,
    Color primaryTextColor,
    Color secondaryTextColor,
    ScreenSize screenSize,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Title
        _buildTextField(
          controller: _titleController,
          label: 'Product Title',
          placeholder: 'e.g. Graphic Calculator FX-991',
          isDarkMode: isDarkMode,
          primaryTextColor: primaryTextColor,
          secondaryTextColor: secondaryTextColor,
        ),
        SizedBox(
          height: ResponsiveBreakpoints.responsiveValue(
            context,
            compact: 16.0,
            medium: 20.0,
            expanded: 24.0,
          ),
        ),
        // Description
        _buildTextArea(
          controller: _descriptionController,
          label: 'Description',
          placeholder: 'Describe your item, its condition, etc.',
          isDarkMode: isDarkMode,
          primaryTextColor: primaryTextColor,
          secondaryTextColor: secondaryTextColor,
        ),
        SizedBox(
          height: ResponsiveBreakpoints.responsiveValue(
            context,
            compact: 16.0,
            medium: 20.0,
            expanded: 24.0,
          ),
        ),
        // Price and Category Row
        ResponsiveBuilder(
          builder: (context, screenSize) {
            if (screenSize == ScreenSize.compact) {
              return Column(
                children: [
                  _buildPriceField(
                    isDarkMode,
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                  SizedBox(
                    height: ResponsiveBreakpoints.responsiveValue(
                      context,
                      compact: 16.0,
                      medium: 20.0,
                      expanded: 24.0,
                    ),
                  ),
                  _buildCategoryDropdown(
                    isDarkMode,
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildPriceField(
                    isDarkMode,
                    primaryTextColor,
                    secondaryTextColor,
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
                Expanded(
                  child: _buildCategoryDropdown(
                    isDarkMode,
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                ),
              ],
            );
          },
        ),
        SizedBox(
          height: ResponsiveBreakpoints.responsiveValue(
            context,
            compact: 16.0,
            medium: 20.0,
            expanded: 24.0,
          ),
        ),
        // Condition and Location Row
        ResponsiveBuilder(
          builder: (context, screenSize) {
            if (screenSize == ScreenSize.compact) {
              return Column(
                children: [
                  _buildConditionDropdown(
                    isDarkMode,
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                  SizedBox(
                    height: ResponsiveBreakpoints.responsiveValue(
                      context,
                      compact: 16.0,
                      medium: 20.0,
                      expanded: 24.0,
                    ),
                  ),
                  _buildLocationField(
                    isDarkMode,
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildConditionDropdown(
                    isDarkMode,
                    primaryTextColor,
                    secondaryTextColor,
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
                Expanded(
                  child: _buildLocationField(
                    isDarkMode,
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    required bool isDarkMode,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 16.0,
              medium: 17.0,
              expanded: 18.0,
            ),
            fontWeight: FontWeight.w600,
            color: primaryTextColor,
          ),
        ),
        SizedBox(
          height: ResponsiveBreakpoints.responsiveValue(
            context,
            compact: 4.0,
            medium: 6.0,
            expanded: 8.0,
          ),
        ),
        TextFormField(
          controller: controller,
          style: GoogleFonts.plusJakartaSans(
            fontSize: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 16.0,
              medium: 17.0,
              expanded: 18.0,
            ),
            color: primaryTextColor,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 16.0,
                medium: 17.0,
                expanded: 18.0,
              ),
              color: secondaryTextColor,
            ),
            filled: true,
            fillColor: isDarkMode
                ? kBackgroundColorDark.withValues(alpha: 0.5)
                : Colors.white,
            border: OutlineInputBorder(
              borderRadius: kBaseRadius,
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: kBaseRadius,
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: kBaseRadius,
              borderSide: BorderSide(
                color: kPrimaryColor,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 16.0,
                medium: 20.0,
                expanded: 24.0,
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
      ],
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    required bool isDarkMode,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 16.0,
              medium: 17.0,
              expanded: 18.0,
            ),
            fontWeight: FontWeight.w600,
            color: primaryTextColor,
          ),
        ),
        SizedBox(
          height: ResponsiveBreakpoints.responsiveValue(
            context,
            compact: 4.0,
            medium: 6.0,
            expanded: 8.0,
          ),
        ),
        TextFormField(
          controller: controller,
          maxLines: 4,
          style: GoogleFonts.plusJakartaSans(
            fontSize: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 16.0,
              medium: 17.0,
              expanded: 18.0,
            ),
            color: primaryTextColor,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 16.0,
                medium: 17.0,
                expanded: 18.0,
              ),
              color: secondaryTextColor,
            ),
            filled: true,
            fillColor: isDarkMode
                ? kBackgroundColorDark.withValues(alpha: 0.5)
                : Colors.white,
            border: OutlineInputBorder(
              borderRadius: kBaseRadius,
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: kBaseRadius,
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: kBaseRadius,
              borderSide: BorderSide(
                color: kPrimaryColor,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 16.0,
                medium: 20.0,
                expanded: 24.0,
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
      ],
    );
  }

  Widget _buildPriceField(
    bool isDarkMode,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price',
          style: GoogleFonts.plusJakartaSans(
            fontSize: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 16.0,
              medium: 17.0,
              expanded: 18.0,
            ),
            fontWeight: FontWeight.w600,
            color: primaryTextColor,
          ),
        ),
        SizedBox(
          height: ResponsiveBreakpoints.responsiveValue(
            context,
            compact: 4.0,
            medium: 6.0,
            expanded: 8.0,
          ),
        ),
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          style: GoogleFonts.plusJakartaSans(
            fontSize: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 16.0,
              medium: 17.0,
              expanded: 18.0,
            ),
            color: primaryTextColor,
          ),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 16.0,
                medium: 17.0,
                expanded: 18.0,
              ),
              color: secondaryTextColor,
            ),
            prefixText: '\$ ',
            prefixStyle: GoogleFonts.plusJakartaSans(
              fontSize: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 16.0,
                medium: 17.0,
                expanded: 18.0,
              ),
              color: secondaryTextColor,
            ),
            filled: true,
            fillColor: isDarkMode
                ? kBackgroundColorDark.withValues(alpha: 0.5)
                : Colors.white,
            border: OutlineInputBorder(
              borderRadius: kBaseRadius,
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: kBaseRadius,
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: kBaseRadius,
              borderSide: BorderSide(
                color: kPrimaryColor,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 16.0,
                medium: 20.0,
                expanded: 24.0,
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
      ],
    );
  }

  Widget _buildCategoryDropdown(
    bool isDarkMode,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: GoogleFonts.plusJakartaSans(
            fontSize: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 16.0,
              medium: 17.0,
              expanded: 18.0,
            ),
            fontWeight: FontWeight.w600,
            color: primaryTextColor,
          ),
        ),
        SizedBox(
          height: ResponsiveBreakpoints.responsiveValue(
            context,
            compact: 4.0,
            medium: 6.0,
            expanded: 8.0,
          ),
        ),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategory,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDarkMode
                ? kBackgroundColorDark.withValues(alpha: 0.5)
                : Colors.white,
            border: OutlineInputBorder(
              borderRadius: kBaseRadius,
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: kBaseRadius,
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: kBaseRadius,
              borderSide: BorderSide(
                color: kPrimaryColor,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 16.0,
                medium: 20.0,
                expanded: 24.0,
              ),
              vertical: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 16.0,
                medium: 18.0,
                expanded: 20.0,
              ),
            ),
          ),
          dropdownColor: isDarkMode
              ? kBackgroundColorDark
              : Colors.white,
          style: GoogleFonts.plusJakartaSans(
            fontSize: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 16.0,
              medium: 17.0,
              expanded: 18.0,
            ),
            color: primaryTextColor,
          ),
          icon: Icon(
            Icons.expand_more,
            color: secondaryTextColor,
          ),
          hint: Text(
            'Select category',
            style: GoogleFonts.plusJakartaSans(
              fontSize: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 16.0,
                medium: 17.0,
                expanded: 18.0,
              ),
              color: secondaryTextColor,
            ),
          ),
          items: _categories.map((category) {
            return DropdownMenuItem<String>(
              value: category == 'Select category' ? null : category,
              child: Text(
                category,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: ResponsiveBreakpoints.responsiveValue(
                    context,
                    compact: 16.0,
                    medium: 17.0,
                    expanded: 18.0,
                  ),
                  color: category == 'Select category'
                      ? secondaryTextColor
                      : primaryTextColor,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildConditionDropdown(
    bool isDarkMode,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Condition',
          style: GoogleFonts.plusJakartaSans(
            fontSize: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 16.0,
              medium: 17.0,
              expanded: 18.0,
            ),
            fontWeight: FontWeight.w600,
            color: primaryTextColor,
          ),
        ),
        SizedBox(
          height: ResponsiveBreakpoints.responsiveValue(
            context,
            compact: 4.0,
            medium: 6.0,
            expanded: 8.0,
          ),
        ),
        DropdownButtonFormField<String>(
          initialValue: _selectedCondition,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDarkMode
                ? kBackgroundColorDark.withValues(alpha: 0.5)
                : Colors.white,
            border: OutlineInputBorder(
              borderRadius: kBaseRadius,
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: kBaseRadius,
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: kBaseRadius,
              borderSide: BorderSide(
                color: kPrimaryColor,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 16.0,
                medium: 20.0,
                expanded: 24.0,
              ),
              vertical: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 16.0,
                medium: 18.0,
                expanded: 20.0,
              ),
            ),
          ),
          dropdownColor: isDarkMode
              ? kBackgroundColorDark
              : Colors.white,
          style: GoogleFonts.plusJakartaSans(
            fontSize: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 16.0,
              medium: 17.0,
              expanded: 18.0,
            ),
            color: primaryTextColor,
          ),
          icon: Icon(
            Icons.expand_more,
            color: secondaryTextColor,
          ),
          hint: Text(
            'Select condition',
            style: GoogleFonts.plusJakartaSans(
              fontSize: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 16.0,
                medium: 17.0,
                expanded: 18.0,
              ),
              color: secondaryTextColor,
            ),
          ),
          items: _conditions.map((condition) {
            return DropdownMenuItem<String>(
              value: condition == 'Select condition' ? null : condition,
              child: Text(
                condition,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: ResponsiveBreakpoints.responsiveValue(
                    context,
                    compact: 16.0,
                    medium: 17.0,
                    expanded: 18.0,
                  ),
                  color: condition == 'Select condition'
                      ? secondaryTextColor
                      : primaryTextColor,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCondition = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLocationField(
    bool isDarkMode,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: GoogleFonts.plusJakartaSans(
            fontSize: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 16.0,
              medium: 17.0,
              expanded: 18.0,
            ),
            fontWeight: FontWeight.w600,
            color: primaryTextColor,
          ),
        ),
        SizedBox(
          height: ResponsiveBreakpoints.responsiveValue(
            context,
            compact: 4.0,
            medium: 6.0,
            expanded: 8.0,
          ),
        ),
        TextFormField(
          controller: _locationController,
          style: GoogleFonts.plusJakartaSans(
            fontSize: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 16.0,
              medium: 17.0,
              expanded: 18.0,
            ),
            color: primaryTextColor,
          ),
          decoration: InputDecoration(
            hintText: 'e.g. Campus Building 3',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 16.0,
                medium: 17.0,
                expanded: 18.0,
              ),
              color: secondaryTextColor,
            ),
            filled: true,
            fillColor: isDarkMode
                ? kBackgroundColorDark.withValues(alpha: 0.5)
                : Colors.white,
            border: OutlineInputBorder(
              borderRadius: kBaseRadius,
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: kBaseRadius,
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: kBaseRadius,
              borderSide: BorderSide(
                color: kPrimaryColor,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveBreakpoints.responsiveValue(
                context,
                compact: 16.0,
                medium: 20.0,
                expanded: 24.0,
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
      ],
    );
  }

  Widget _buildFooterButton(
    bool isDarkMode,
    Color primaryTextColor,
    ScreenSize screenSize,
  ) {
    final horizontalPadding = ResponsiveBreakpoints.responsiveHorizontalPadding(context);
    
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 16.0,
              medium: 20.0,
              expanded: 24.0,
            ),
            horizontalPadding,
            ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 24.0,
              medium: 28.0,
              expanded: 32.0,
            ),
          ),
          decoration: BoxDecoration(
            color: (isDarkMode ? kBackgroundColorDark : kBackgroundColorLight)
                .withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(
                color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          child: Center(
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
                  onPressed: _handlePostProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: kBackgroundColorDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    elevation: ResponsiveBreakpoints.responsiveValue(
                      context,
                      compact: 8.0,
                      medium: 6.0,
                      expanded: 6.0,
                    ),
                    shadowColor: kPrimaryColor.withValues(alpha: 0.3),
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
                    'Post Product',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: ResponsiveBreakpoints.responsiveValue(
                        context,
                        compact: 18.0,
                        medium: 17.0,
                        expanded: 18.0,
                      ),
                      fontWeight: FontWeight.bold,
                      color: kBackgroundColorDark,
                      letterSpacing: 0.5,
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
}


