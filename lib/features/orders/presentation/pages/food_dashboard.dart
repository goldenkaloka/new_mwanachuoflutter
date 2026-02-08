import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/config/supabase_config.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/features/orders/presentation/bloc/cart_bloc.dart';
import 'package:mwanachuo/core/widgets/app_background.dart';

class FoodDashboard extends StatefulWidget {
  const FoodDashboard({super.key});

  @override
  State<FoodDashboard> createState() => _FoodDashboardState();
}

class _FoodDashboardState extends State<FoodDashboard> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _vendors = [];

  @override
  void initState() {
    super.initState();
    _fetchVendors();
  }

  Future<void> _fetchVendors() async {
    setState(() => _isLoading = true);
    try {
      // Find sellers who have products in the 'food' category
      final response = await SupabaseConfig.client
          .from('products')
          .select(
            'seller_id, users!inner(id, full_name, avatar_url, business_name)',
          )
          .eq('category', 'food')
          .eq('is_active', true);

      // Unique vendors
      final vendorMap = <String, Map<String, dynamic>>{};
      for (var item in (response as List)) {
        final userData = item['users'];
        vendorMap[userData['id']] = userData;
      }

      setState(() {
        _vendors = vendorMap.values.toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching vendors: $e'),
            backgroundColor: Colors.red,
          ),
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
          'Campus Eats',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state.items.isEmpty) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => Navigator.pushNamed(context, '/cart'),
            backgroundColor: kPrimaryColor,
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            label: Text(
              'View Cart (${state.totalItems})',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
      body: AppBackground(
        child: Column(
          children: [
            // Search Bar Placeholder
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search for food or kitchens...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _vendors.isEmpty
                  ? const Center(child: Text('No kitchens open right now.'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _vendors.length,
                      itemBuilder: (context, index) {
                        final vendor = _vendors[index];
                        return _buildVendorCard(vendor);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorCard(Map<String, dynamic> vendor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Navigate to Vendor Details / Menu
          Navigator.pushNamed(context, '/vendor-menu', arguments: vendor);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vendor Banner Placeholder or Logo
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Center(
                child: vendor['avatar_url'] != null
                    ? CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(vendor['avatar_url']),
                      )
                    : const Icon(
                        Icons.restaurant,
                        size: 60,
                        color: kPrimaryColor,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor['business_name'] ??
                        vendor['full_name'] ??
                        'Unknown Kitchen',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      const Text('4.5 (20+ reviews)'),
                      const Spacer(),
                      const Icon(Icons.timer, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      const Text('20-30 mins'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
