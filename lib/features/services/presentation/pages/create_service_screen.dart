import 'dart:io';
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
import 'package:mwanachuo/features/services/presentation/bloc/service_bloc.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_event.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_state.dart';
import 'package:mwanachuo/features/shared/categories/presentation/cubit/category_cubit.dart';
import 'package:mwanachuo/features/shared/categories/presentation/cubit/category_state.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:mwanachuo/features/subscriptions/domain/usecases/get_seller_subscription.dart';
import 'package:mwanachuo/features/auth/domain/repositories/auth_repository.dart';

class CreateServiceScreen extends StatefulWidget {
  const CreateServiceScreen({super.key});

  @override
  State<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _contactController = TextEditingController();
  String? _selectedCategory;
  final List<File> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _checkSellerAccess();
    context.read<CategoryCubit>().loadServiceCategories();
  }

  void _checkSellerAccess() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        final userRole = authState.user.role.value;

        if (userRole == 'buyer') {
          debugPrint('❌ Buyer attempting to create service - redirecting');
          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You need to become a seller to offer services',
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
      final remainingSlots = 5 - _selectedImages.length;

      // Check if running on desktop (Windows, macOS, Linux)
      final isDesktop =
          !kIsWeb &&
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

      if (isDesktop) {
        // Use file_picker for desktop platforms
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: true,
          dialogTitle: 'Select service images (max $remainingSlots)',
        );

        if (result != null && result.files.isNotEmpty) {
          final List<File> newFiles = [];
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

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one image'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid price'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check auth and subscription status
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to create services'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading while checking subscription
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final getSubscription = sl<GetSellerSubscription>();
    final result = await getSubscription(authState.user.id);

    // Close loading
    if (mounted) Navigator.pop(context);

    bool isSubscriber = false;
    result.fold(
      (l) => isSubscriber = false,
      (s) => isSubscriber = s != null && s.isActive,
    );

    // Check if user has free listings (Student Offer)
    final int freeListings = authState.user.freeListingsCount;

    if (isSubscriber || freeListings > 0) {
      if (freeListings > 0 && !isSubscriber) {
        // Show free listing confirmation
        if (!mounted) return;
        final confirmFree = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Use Free Listing?'),
            content: Text(
              'You have $freeListings free listings remaining as a student. Would you like to use one for this service?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Use Free Listing'),
              ),
            ],
          ),
        );

        if (confirmFree == true) {
          // Show loading
          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );

          final authRepo = sl<AuthRepository>();
          final result = await authRepo.consumeFreeListing(authState.user.id);

          if (!mounted) return;
          Navigator.pop(context); // Close loading

          result.fold(
            (failure) => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Failed to consume free listing. Please try again.',
                ),
              ),
            ),
            (_) => _dispatchCreateService(price),
          );
          return;
        }
      } else {
        // Business subscriber - post directly
        _dispatchCreateService(price);
        return;
      }
    }

    // Default: 0.5% Fee Logic
    final fee = price * 0.005;
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Listing Fee'),
        content: Text(
          'You are on a standard plan. A 0.5% listing fee of ${fee.toStringAsFixed(0)} TZS will be deducted from your wallet.\n\nSubscribe to Business Plan for unlimited listings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pay & Post'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Show loading for payment
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final walletRepo = sl<WalletRepository>();
      final deductResult = await walletRepo.deductBalance(
        amount: fee,
        description: 'Service Listing Fee: ${_titleController.text.trim()}',
      );

      if (!mounted) return;
      Navigator.pop(context); // Close payment loading

      deductResult.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Insufficient wallet balance. Please top up your wallet.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        },
        (_) {
          _dispatchCreateService(price);
        },
      );
    }
  }

  void _dispatchCreateService(double price) {
    final authState = context.read<AuthBloc>().state;
    final isGlobal =
        authState is Authenticated && authState.user.userType == 'business';

    context.read<ServiceBloc>().add(
      CreateServiceEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        category: _selectedCategory!,
        priceType: 'fixed', // Default, you can add a dropdown for this
        images: _selectedImages,
        location: 'Campus', // Default, you can add a location field
        contactPhone: _contactController.text.trim(),
        availability: [], // You can add availability selector
        isGlobal: isGlobal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? Colors.white : kTextPrimary;
    final secondaryTextColor = isDarkMode
        ? Colors.grey[400]!
        : Colors.grey[600]!;
    final borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;

    return BlocConsumer<ServiceBloc, ServiceState>(
      listener: (context, state) {
        if (state is ServiceCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Service created successfully!',
                style: GoogleFonts.plusJakartaSans(),
              ),
              backgroundColor: kPrimaryColor,
            ),
          );
          Navigator.pop(context);
        } else if (state is ServiceError) {
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

                                // Service Title
                                TextFormField(
                                  controller: _titleController,
                                  decoration: InputDecoration(
                                    labelText: 'Service Title',
                                    hintText: 'e.g., Mathematics Tutoring',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide: BorderSide(
                                        color: borderColor,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide: BorderSide(
                                        color: borderColor,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a service title';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 20.0),

                                // Category Dropdown
                                BlocBuilder<CategoryCubit, CategoryState>(
                                  builder: (context, categoryState) {
                                    List<String> categories = [
                                      'Select category',
                                    ];
                                    if (categoryState is CategoriesLoaded) {
                                      final loadedNames = categoryState
                                          .categories
                                          .map((c) => c.name)
                                          .toList();
                                      categories.addAll(loadedNames);

                                      // Ensure selected category is in the list
                                      if (_selectedCategory != null &&
                                          !loadedNames.contains(
                                            _selectedCategory,
                                          ) &&
                                          _selectedCategory !=
                                              'Select category') {
                                        categories.add(_selectedCategory!);
                                      }
                                    } else if (_selectedCategory != null &&
                                        _selectedCategory !=
                                            'Select category') {
                                      // If not loaded but we somehow have a selection, add it to prevent crash
                                      categories.add(_selectedCategory!);
                                    }

                                    return DropdownButtonFormField<String>(
                                      value: _selectedCategory,
                                      decoration: InputDecoration(
                                        labelText: 'Category',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12.0,
                                          ),
                                          borderSide: BorderSide(
                                            color: borderColor,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12.0,
                                          ),
                                          borderSide: BorderSide(
                                            color: borderColor,
                                          ),
                                        ),
                                      ),
                                      items: categories.map((category) {
                                        return DropdownMenuItem(
                                          value: category == 'Select category'
                                              ? null
                                              : category,
                                          child: Text(category),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedCategory = value;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please select a category';
                                        }
                                        return null;
                                      },
                                    );
                                  },
                                ),

                                const SizedBox(height: 20.0),

                                // Description
                                TextFormField(
                                  controller: _descriptionController,
                                  maxLines: 5,
                                  decoration: InputDecoration(
                                    labelText: 'Description',
                                    hintText:
                                        'Describe your service, experience, and what makes you qualified...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide: BorderSide(
                                        color: borderColor,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide: BorderSide(
                                        color: borderColor,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a description';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 20.0),

                                // Price
                                TextFormField(
                                  controller: _priceController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Price per Hour',
                                    hintText: '0.00',
                                    prefixText: '\$ ',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide: BorderSide(
                                        color: borderColor,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide: BorderSide(
                                        color: borderColor,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a price';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 24.0),

                                // Contact Information
                                TextFormField(
                                  controller: _contactController,
                                  decoration: InputDecoration(
                                    labelText: 'Contact Information',
                                    hintText: 'Email or phone number',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide: BorderSide(
                                        color: borderColor,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide: BorderSide(
                                        color: borderColor,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter contact information';
                                    }
                                    return null;
                                  },
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
      },
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
              'List a Service',
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _handleImageUpload,
          child: Container(
            height: _selectedImages.isEmpty ? 200 : null,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: borderColor,
                width: 2.0,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(16.0),
              color: isDarkMode
                  ? kBackgroundColorDark.withValues(alpha: 0.5)
                  : Colors.white,
            ),
            child: _selectedImages.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 48.0,
                        color: secondaryTextColor,
                      ),
                      const SizedBox(height: 12.0),
                      Text(
                        'Upload Service Photos',
                        style: GoogleFonts.plusJakartaSans(
                          color: primaryTextColor,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Tap to select images (up to 5)',
                        style: GoogleFonts.plusJakartaSans(
                          color: secondaryTextColor,
                          fontSize: 14.0,
                        ),
                      ),
                    ],
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._selectedImages.asMap().entries.map((entry) {
                        final index = entry.key;
                        final image = entry.value;
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                image,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
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
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              border: Border.all(color: borderColor, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.add,
                              size: 32,
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

  Widget _buildSubmitButton(
    BuildContext context,
    Color primaryTextColor,
    ScreenSize screenSize,
  ) {
    final isLoading = context.watch<ServiceBloc>().state is ServiceLoading;

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
              height: 48.0,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: kBackgroundColorDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  elevation: 2.0,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  minimumSize: const Size(64, 40),
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
                        'List Service',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
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
