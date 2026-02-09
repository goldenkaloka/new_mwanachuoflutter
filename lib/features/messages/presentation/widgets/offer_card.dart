import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/features/messages/domain/entities/message.dart';

class OfferCard extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onCounter;

  const OfferCard({
    super.key,
    required this.message,
    required this.isMe,
    this.onAccept,
    this.onDecline,
    this.onCounter,
  });

  @override
  Widget build(BuildContext context) {
    final metadata = message.metadata;
    final offerAmount = metadata['offer_amount'] as num? ?? 0;
    final originalPrice = metadata['original_price'] as num? ?? 0;
    final status = metadata['status'] as String? ?? 'pending';
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_TZ',
      symbol: 'TZS ',
      decimalDigits: 0,
    );

    final isPending = status == 'pending';
    final isAccepted = status == 'accepted';
    final isDeclined = status == 'declined';

    // Determine colors and icon based on status
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isAccepted) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Offer Accepted';
    } else if (isDeclined) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusText = 'Offer Declined';
    } else {
      statusColor = kPrimaryColor; // Orange/Gold
      statusIcon = Icons.local_offer;
      statusText = isMe ? 'You sent an offer' : 'Offer Received';
    }

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Icon(statusIcon, size: 16, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: statusColor,
                    ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Offer Price:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      currencyFormatter.format(offerAmount),
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                if (originalPrice > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Original Price:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        currencyFormatter.format(originalPrice),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey[500],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                // Actions (Only for recipient and pending status)
                if (!isMe && isPending) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onDecline,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 0),
                            minimumSize: const Size(0, 36),
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onAccept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 0),
                            minimumSize: const Size(0, 36),
                          ),
                          child: const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onCounter,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kPrimaryColor,
                        side: const BorderSide(color: kPrimaryColor),
                        minimumSize: const Size(0, 36),
                      ),
                      child: const Text('Counter Offer'),
                    ),
                  ),
                ],

                // Status message for sender or non-pending
                if (isMe && isPending)
                  Text(
                    'Waiting for seller response...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
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
