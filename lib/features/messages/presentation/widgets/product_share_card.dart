import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/features/messages/domain/entities/message.dart';

class ProductShareCard extends StatelessWidget {
  final Message message;
  final bool showActions;
  final VoidCallback? onViewProduct;
  final VoidCallback? onMakeOffer;
  final VoidCallback? onAddToCart;

  const ProductShareCard({
    super.key,
    required this.message,
    required this.showActions,
    this.onViewProduct,
    this.onMakeOffer,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final metadata = message.metadata;
    final title = metadata['product_title'] ?? 'Product';
    final price = metadata['product_price']?.toString() ?? '0';
    final imageUrl = metadata['product_image'] as String?;
    // final productId = metadata['product_id'] as String?;

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'TZS $price',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: kPrimaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                // Actions
                if (showActions) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onMakeOffer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: kPrimaryColor,
                        elevation: 0,
                        side: const BorderSide(color: kPrimaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Make Offer'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onAddToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Add to Cart'),
                    ),
                  ),
                ] else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onViewProduct,
                      child: const Text('View Product'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
