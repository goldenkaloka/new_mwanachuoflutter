import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_cart_bloc.dart';

class ProductCartPage extends StatelessWidget {
  const ProductCartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode
        ? const Color(0xFF0A0E27)
        : const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Shopping Cart',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          BlocBuilder<ProductCartBloc, ProductCartState>(
            builder: (context, state) {
              if (state.itemsBySeller.isEmpty) return const SizedBox.shrink();

              return IconButton(
                onPressed: () => _showClearCartDialog(context),
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Clear Cart',
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<ProductCartBloc, ProductCartState>(
        builder: (context, state) {
          if (state.itemsBySeller.isEmpty) {
            return _buildEmptyCart(context, isDarkMode);
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.sellerIds.length,
                  itemBuilder: (context, index) {
                    final sellerId = state.sellerIds[index];
                    final items = state.getItemsForSeller(sellerId);
                    final subtotal = state.getSubtotalForSeller(sellerId);

                    return _buildSellerSection(
                      context,
                      sellerId,
                      items,
                      subtotal,
                      isDarkMode,
                    );
                  },
                ),
              ),
              _buildBottomSummary(context, state, isDarkMode),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kPrimaryColor.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: kPrimaryColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF11221F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add products to get started',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'Continue Shopping',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerSection(
    BuildContext context,
    String sellerId,
    List<CartItem> items,
    double subtotal,
    bool isDarkMode,
  ) {
    final cardBg = isDarkMode ? const Color(0xFF1A1F3A) : Colors.white;
    final sellerName = items.first.product.sellerName;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seller header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: kPrimaryColor,
                  child: Text(
                    sellerName[0].toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sellerName,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${items.length} item${items.length > 1 ? 's' : ''}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'TZS ${subtotal.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: kPrimaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Items
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
            itemBuilder: (context, index) {
              return _buildCartItem(context, items[index], isDarkMode);
            },
          ),

          // Checkout button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/product-checkout',
                    arguments: {'sellerId': sellerId, 'items': items},
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Checkout from $sellerName',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItem item, bool isDarkMode) {
    final product = item.product;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: product.images.isNotEmpty ? product.images.first : '',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'TZS ${product.price.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: kPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Quantity controls
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          _buildQuantityButton(context, Icons.remove, () {
                            context.read<ProductCartBloc>().add(
                              UpdateCartQuantity(
                                productId: product.id,
                                quantity: item.quantity - 1,
                              ),
                            );
                          }),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '${item.quantity}',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          _buildQuantityButton(context, Icons.add, () {
                            context.read<ProductCartBloc>().add(
                              UpdateCartQuantity(
                                productId: product.id,
                                quantity: item.quantity + 1,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        context.read<ProductCartBloc>().add(
                          RemoveFromCart(product.id),
                        );
                      },
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.red,
                      tooltip: 'Remove',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 18),
      ),
    );
  }

  Widget _buildBottomSummary(
    BuildContext context,
    ProductCartState state,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Items',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${state.totalItems}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Grand Total',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'TZS ${state.totalAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Checkout each seller separately',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Clear Cart?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to remove all items from your cart?',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<ProductCartBloc>().add(ClearCart());
              Navigator.pop(dialogContext);
            },
            child: Text(
              'Clear',
              style: GoogleFonts.plusJakartaSans(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
