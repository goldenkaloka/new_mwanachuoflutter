import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/config/supabase_config.dart';
import 'package:mwanachuo/core/widgets/app_background.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/features/orders/domain/entities/order.dart';
import 'package:mwanachuo/features/orders/presentation/bloc/cart_bloc.dart';
import 'package:mwanachuo/features/products/data/models/product_model.dart';

class VendorMenuPage extends StatefulWidget {
  final Map<String, dynamic> vendor;
  const VendorMenuPage({super.key, required this.vendor});

  @override
  State<VendorMenuPage> createState() => _VendorMenuPageState();
}

class _VendorMenuPageState extends State<VendorMenuPage> {
  bool _isLoading = false;
  List<ProductModel> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final response = await SupabaseConfig.client
          .from('products')
          .select('*, users(full_name, avatar_url, phone_number)')
          .eq('seller_id', widget.vendor['id'])
          .eq('category', 'food')
          .eq('is_active', true);

      setState(() {
        _products = (response as List).map((json) {
          return ProductModel.fromJson({
            ...json,
            'seller_name': json['users']['full_name'],
            'seller_phone': json['users']['phone_number'],
            'seller_avatar': json['users']['avatar_url'],
          });
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching menu: $e'),
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
      body: AppBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.vendor['business_name'] ??
                      widget.vendor['full_name'] ??
                      'Kitchen',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [const Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
                background: widget.vendor['avatar_url'] != null
                    ? Image.network(
                        widget.vendor['avatar_url'],
                        fit: BoxFit.cover,
                      )
                    : Container(color: kPrimaryColor),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Menu',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_products.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text('No items on the menu today.')),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = _products[index];
                  return _buildProductItem(product);
                }, childCount: _products.length),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(ProductModel product) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: product.images.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(product.images.first),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: Colors.grey[200],
              ),
              child: product.images.isEmpty ? const Icon(Icons.fastfood) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    product.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tsh ${product.price.toStringAsFixed(0)}',
                    style: GoogleFonts.plusJakartaSans(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                context.read<CartBloc>().add(
                  AddToCart(
                    OrderItem(
                      id: '', // Temporary ID
                      productId: product.id,
                      productName: product.title,
                      quantity: 1,
                      priceAtTime: product.price,
                    ),
                    widget.vendor['id'],
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.title} added to cart'),
                    duration: const Duration(seconds: 1),
                    action: SnackBarAction(
                      label: 'View Cart',
                      onPressed: () => Navigator.pushNamed(context, '/cart'),
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.add_circle,
                color: kPrimaryColor,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
