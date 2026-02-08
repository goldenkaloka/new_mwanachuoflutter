import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/config/supabase_config.dart';
import 'package:mwanachuo/core/widgets/app_background.dart';

class AdminCreateBusinessUserPage extends StatefulWidget {
  const AdminCreateBusinessUserPage({super.key});

  @override
  State<AdminCreateBusinessUserPage> createState() =>
      _AdminCreateBusinessUserPageState();
}

class _AdminCreateBusinessUserPageState
    extends State<AdminCreateBusinessUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessCategoryController = TextEditingController();
  final _tinNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await SupabaseConfig.client.functions.invoke(
        'create-business-user',
        body: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'businessName': _businessNameController.text.trim(),
          'businessCategory': _businessCategoryController.text.trim(),
          'tinNumber': _tinNumberController.text.trim(),
        },
      );

      if (response.status == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Business user created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception('Failed to create user: ${response.data}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Register Business User',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
      ),
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _businessNameController,
                  label: 'Business Name',
                  icon: Icons.store,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _businessCategoryController,
                  label: 'Category',
                  icon: Icons.category,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _tinNumberController,
                  label: 'TIN Number',
                  icon: Icons.numbers,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock,
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Create Account',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
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
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).cardColor,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }
}
