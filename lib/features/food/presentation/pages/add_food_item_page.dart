import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/features/food/domain/entities/food_item.dart';
import 'package:mwanachuo/features/food/presentation/bloc/food_bloc.dart';

class AddFoodItemPage extends StatefulWidget {
  final String restaurantId;
  final FoodItem? item;

  const AddFoodItemPage({
    super.key,
    required this.restaurantId,
    this.item,
  });

  @override
  State<AddFoodItemPage> createState() => _AddFoodItemPageState();
}

class _AddFoodItemPageState extends State<AddFoodItemPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _categoryController;
  bool _isAvailable = true;
  File? _selectedImage;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _descriptionController = TextEditingController(text: widget.item?.description ?? '');
    _priceController = TextEditingController(text: widget.item?.price.toInt().toString() ?? '');
    _categoryController = TextEditingController(text: widget.item?.category ?? '');
    _isAvailable = widget.item?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final foodItem = FoodItem(
        id: widget.item?.id ?? '',
        restaurantId: widget.restaurantId,
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        category: _categoryController.text.isNotEmpty ? _categoryController.text : null,
        isAvailable: _isAvailable,
        imageUrl: widget.item?.imageUrl,
      );

      if (widget.item == null) {
        context.read<FoodBloc>().add(AddFoodItemEvent(foodItem, imageFile: _selectedImage));
      } else {
        context.read<FoodBloc>().add(UpdateFoodItemEvent(foodItem, imageFile: _selectedImage));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.item != null;

    return BlocListener<FoodBloc, FoodState>(
      listener: (context, state) {
        if (state.status == FoodStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isEditing ? 'Item updated!' : 'Item added!')),
          );
          Navigator.pop(context);
        } else if (state.status == FoodStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'An error occurred')),
          );
        }
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? kBackgroundColorDark : Colors.white,
        appBar: AppBar(
          title: Text(
            isEditing ? 'Edit Food Item' : 'Add Food Item',
            style: GoogleFonts.plusJakartaSans(
              color: isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: isDarkMode ? kSurfaceColorDark : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.white10 : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDarkMode ? Colors.white24 : Colors.grey[300]!),
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(_selectedImage!, fit: BoxFit.cover),
                            )
                          : (widget.item?.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.network(widget.item!.imageUrl!, fit: BoxFit.cover),
                                )
                              : Icon(Icons.add_a_photo_outlined, size: 40, color: isDarkMode ? Colors.white38 : Colors.grey)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Upload food photo',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white38 : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _buildTextField(
                  controller: _nameController,
                  label: 'Food Name',
                  hint: 'e.g. Double Cheese Burger',
                  isDarkMode: isDarkMode,
                  validator: (v) => v!.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Describe your food...',
                  isDarkMode: isDarkMode,
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _priceController,
                        label: 'Price (TZS)',
                        hint: 'e.g. 12000',
                        isDarkMode: isDarkMode,
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Price is required' : null,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildTextField(
                        controller: _categoryController,
                        label: 'Category',
                        hint: 'e.g. Burger',
                        isDarkMode: isDarkMode,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                SwitchListTile(
                  title: Text(
                    'Available for Order',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    'Toggle this if item is out of stock',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey),
                  ),
                  value: _isAvailable,
                  onChanged: (v) => setState(() => _isAvailable = v),
                  activeColor: kPrimaryColor,
                ),
                const SizedBox(height: 40),
                BlocBuilder<FoodBloc, FoodState>(
                  builder: (context, state) {
                    final isLoading = state.status == FoodStatus.loading;
                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          shape: roundedRectangleCircular(16),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                isEditing ? 'Update Food Item' : 'Add Food Item',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDarkMode,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white70 : Colors.black54,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: isDarkMode ? Colors.white24 : Colors.grey),
            filled: true,
            fillColor: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  // Helper for backward compatibility
  static RoundedRectangleBorder roundedRectangleCircular(double radius) {
    return RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
  }
}
