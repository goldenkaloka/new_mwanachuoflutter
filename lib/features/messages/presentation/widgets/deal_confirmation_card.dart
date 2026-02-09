import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/features/messages/domain/entities/message.dart';

class DealConfirmationCard extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onPayNow;
  final VoidCallback? onViewOrder;

  const DealConfirmationCard({
    super.key,
    required this.message,
    required this.isMe,
    this.onPayNow,
    this.onViewOrder,
  });

  @override
  Widget build(BuildContext context) {
    final metadata = message.metadata;
    final productTitle = metadata['product_title'] ?? 'Product';
    final agreedPrice = metadata['agreed_price'] as num? ?? 0;
    final orderId = metadata['order_id'] as String? ?? 'N/A';
    final paymentStatus = metadata['payment_status'] as String? ?? 'pending';

    final currencyFormatter = NumberFormat.currency(
      locale: 'en_TZ',
      symbol: 'TZS ',
      decimalDigits: 0,
    );

    final isPaid = paymentStatus == 'paid';

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.handshake, size: 18, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Deal Confirmed!',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormatter.format(agreedPrice),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Order ID:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '#${orderId.substring(0, 8).toUpperCase()}',
                      style: GoogleFonts.spaceMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Status:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isPaid ? Colors.green[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isPaid
                              ? Colors.green[200]!
                              : Colors.orange[200]!,
                        ),
                      ),
                      child: Text(
                        paymentStatus.replaceAll('_', ' ').toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isPaid
                              ? Colors.green[800]
                              : Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Actions
                if (!isPaid && !isMe) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onPayNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Pay Now'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onViewOrder,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('View Order Details'),
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
