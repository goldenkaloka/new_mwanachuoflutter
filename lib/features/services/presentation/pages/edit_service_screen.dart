import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/core/widgets/network_image_with_fallback.dart';
import 'package:mwanachuo/features/services/domain/entities/service_entity.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_bloc.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_event.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_state.dart';

class EditServiceScreen extends StatelessWidget {
  final ServiceEntity service;

  const EditServiceScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ServiceBloc>(),
      child: _EditServiceView(service: service),
    );
  }
}

class _EditServiceView extends StatefulWidget {
  final ServiceEntity service;

  const _EditServiceView({required this.service});

  @override
  State<_EditServiceView> createState() => _EditServiceViewState();
}

class _EditServiceViewState extends State<_EditServiceView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();

  String? _selectedCategory;
  String? _selectedPriceType;
  List<String> _existingImages = [];
  final List<File> _newImages = [];
  List<String> _availability = [];
  bool _isActive = true;

  final List<String> _categories = [
    'Tutoring',
    'Photography',
    'Event Planning',
    'Graphic Design',
    'Web Development',
    'Writing & Editing',
    'Music Lessons',
    'Fitness Training',
    'Other',
  ];

  final List<String> _priceTypes = [
    'hourly',
    'fixed',
    'per_session',
  ];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.service.title;
    _descriptionController.text = widget.service.description;
    _priceController.text = widget.service.price.toString();
    _locationController.text = widget.service.location;
    _contactPhoneController.text = widget.service.contactPhone;
    _contactEmailController.text = widget.service.contactEmail ?? '';
    _selectedCategory = widget.service.category;
    _selectedPriceType = widget.service.priceType;
    _existingImages = List<String>.from(widget.service.images);
    _availability = List<String>.from(widget.service.availability);
    _isActive = widget.service.isActive;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleImageUpload() async {
    if (_existingImages.length + _newImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 5 images allowed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final remainingSlots = 5 - (_existingImages.length + _newImages.length);
      final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

      if (isDesktop) {
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
              _newImages.addAll(newFiles);
            });
          }
        }
      } else {
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
            ),
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
              _newImages.addAll(newFiles);
            });
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

  void _removeExistingImage(int index) {
    setState(() {
      _existingImages.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_existingImages.isEmpty && _newImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid price'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<ServiceBloc>().add(
      UpdateServiceEvent(
        serviceId: widget.service.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        category: _selectedCategory,
        priceType: _selectedPriceType,
        newImages: _newImages.isNotEmpty ? _newImages : null,
        existingImages: _existingImages,
        location: _locationController.text.trim(),
        contactPhone: _contactPhoneController.text.trim(),
        contactEmail: _contactEmailController.text.trim().isNotEmpty
            ? _contactEmailController.text.trim()
            : null,
        availability: _availability,
        isActive: _isActive,
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Service',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDarkMode ? kBackgroundColorDark : Colors.white,
      ),
      backgroundColor: isDarkMode
          ? kBackgroundColorDark
          : kBackgroundColorLight,
      body: BlocListener<ServiceBloc, ServiceState>(
        listener: (context, state) {
          if (state is ServiceUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Service updated successfully!'),
                backgroundColor: kPrimaryColor,
              ),
            );
            Navigator.pop(context, true);
          } else if (state is ServiceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<ServiceBloc, ServiceState>(
          builder: (context, state) {
            final isLoading = state is ServiceUpdating;

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Images Section
                        Text(
                          'Images',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildImagesSection(isDarkMode),
                        const SizedBox(height: 24),

                        // Title
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Service Title *',
                            hintText: 'e.g., Mathematics Tutoring',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter service title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Category and Price Type Row
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedCategory,
                                decoration: InputDecoration(
                                  labelText: 'Category *',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: _categories
                                    .map(
                                      (category) => DropdownMenuItem(
                                        value: category,
                                        child: Text(category),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCategory = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select category';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedPriceType,
                                decoration: InputDecoration(
                                  labelText: 'Price Type *',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: _priceTypes
                                    .map(
                                      (type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(type),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPriceType = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select price type';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Price
                        TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(
                            labelText: 'Price *',
                            hintText: 'e.g., 5000',
                            prefixText: 'TZS ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter price';
                            }
                            if (double.tryParse(value.trim()) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Description
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description *',
                            hintText: 'Describe your service...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          maxLines: 5,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter description';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Location
                        TextFormField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            labelText: 'Location *',
                            hintText: 'e.g., Campus Area',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.location_on),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter location';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Contact Phone
                        TextFormField(
                          controller: _contactPhoneController,
                          decoration: InputDecoration(
                            labelText: 'Contact Phone *',
                            hintText: 'e.g., +255700000000',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Contact Email
                        TextFormField(
                          controller: _contactEmailController,
                          decoration: InputDecoration(
                            labelText: 'Contact Email (Optional)',
                            hintText: 'e.g., example@email.com',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        // Active Status
                        SwitchListTile(
                          title: Text(
                            'Active Listing',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                          ),
                          subtitle: Text(
                            'Toggle to activate/deactivate this listing',
                            style: TextStyle(color: secondaryTextColor),
                          ),
                          value: _isActive,
                          activeThumbColor: kPrimaryColor,
                          onChanged: (value) {
                            setState(() {
                              _isActive = value;
                            });
                          },
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Update Service',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                if (isLoading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: CircularProgressIndicator(color: kPrimaryColor),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildImagesSection(bool isDarkMode) {
    final allImagesCount = _existingImages.length + _newImages.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (allImagesCount > 0)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _existingImages.length + _newImages.length,
              itemBuilder: (context, index) {
                if (index < _existingImages.length) {
                  return _buildExistingImageCard(_existingImages[index], index);
                } else {
                  return _buildNewImageCard(
                    _newImages[index - _existingImages.length],
                    index - _existingImages.length,
                  );
                }
              },
            ),
          ),
        if (allImagesCount > 0) const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _handleImageUpload,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Add More Images'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: kPrimaryColor),
            foregroundColor: kPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildExistingImageCard(String imageUrl, int index) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: NetworkImageWithFallback(
              imageUrl: imageUrl,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeExistingImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewImageCard(File imageFile, int index) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              imageFile,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeNewImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

