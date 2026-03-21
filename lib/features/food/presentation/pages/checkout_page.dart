import 'package:flutter/material.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/features/food/domain/entities/restaurant.dart';
import 'package:mwanachuo/features/food/domain/entities/food_item.dart';
import 'package:intl/intl.dart';

class CheckoutPage extends StatelessWidget {
  final Restaurant restaurant;
  final List<FoodItem> cartItems;
  final double totalAmount;

  const CheckoutPage({
    super.key,
    required this.restaurant,
    required this.cartItems,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'TZS ', decimalDigits: 0);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? kBackgroundColorDark : const Color(0xFFF5F7FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: isDarkMode ? kSurfaceColorDark : Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: isDarkMode ? Colors.white : kTextPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            title: Text(
              'Checkout',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                color: isDarkMode ? Colors.white : kTextPrimary,
              ),
            ),
            centerTitle: true,
          ),
          // Escrow trust banner
          SliverToBoxAdapter(child: _buildEscrowBanner(isDarkMode)),
          // Body content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Delivery Address', isDarkMode),
                  _buildAddressCard(isDarkMode),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Order Summary', isDarkMode),
                  _buildOrderSummary(currencyFormat, isDarkMode),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Payment Method', isDarkMode),
                  _buildPaymentCard(isDarkMode),
                  const SizedBox(height: 32),
                  _buildPlaceOrderButton(context, currencyFormat, isDarkMode),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEscrowBanner(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kPrimaryColor.withValues(alpha: 0.12),
            kPrimaryColorLight.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kPrimaryColor, kPrimaryColorLight]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trust Escrow Active',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: kPrimaryColor, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Funds released only after QR delivery confirmation.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDarkMode ? Colors.white60 : kTextTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: isDarkMode ? Colors.white : kTextPrimary,
        ),
      ),
    );
  }

  Widget _buildAddressCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDarkMode ? kSurfaceColorDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.15 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.location_on_rounded, color: kPrimaryColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'University Hub',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: isDarkMode ? Colors.white : kTextPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Mlimani Campus, Block B Room 302',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: isDarkMode ? Colors.white54 : kTextTertiary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('Change', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: kPrimaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(NumberFormat format, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDarkMode ? kSurfaceColorDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.15 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ...cartItems.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text('1x', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: kPrimaryColor, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(item.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white70 : kTextPrimary)),
                ),
                Text(format.format(item.price), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : kTextPrimary)),
              ],
            ),
          )),
          const Divider(height: 24),
          _buildPriceRow('Subtotal', format.format(totalAmount), isDarkMode, false),
          const SizedBox(height: 8),
          _buildPriceRow('Delivery', format.format(restaurant.deliveryFee ?? 2000), isDarkMode, false),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: isDarkMode ? Colors.white : kTextPrimary)),
                Text(
                  format.format(totalAmount + (restaurant.deliveryFee ?? 2000)),
                  style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: kPrimaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, bool isDarkMode, bool bold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(color: isDarkMode ? Colors.white54 : kTextTertiary, fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
        Text(value, style: GoogleFonts.plusJakartaSans(color: isDarkMode ? Colors.white70 : kTextSecondary, fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
      ],
    );
  }

  Widget _buildPaymentCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDarkMode ? kSurfaceColorDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.15 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kPrimaryColor, kPrimaryColorLight]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mwanachuo Wallet', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: isDarkMode ? Colors.white : kTextPrimary)),
                Text('Instant payment', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDarkMode ? Colors.white38 : kTextTertiary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Color(0xFF22C55E), size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton(BuildContext context, NumberFormat format, bool isDarkMode) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: () => _showConfirmation(context, isDarkMode),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [kPrimaryColor, kPrimaryColorLight]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: kPrimaryColor.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            alignment: Alignment.center,
            height: 58,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Confirm & Lock ${format.format(totalAmount + (restaurant.deliveryFee ?? 2000))}',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showConfirmation(BuildContext context, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDarkMode ? kSurfaceColorDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [kPrimaryColor, kPrimaryColorLight]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: kPrimaryColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 24),
            Text('Order Placed! 🎉', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: isDarkMode ? Colors.white : kTextPrimary)),
            const SizedBox(height: 10),
            Text(
              'Your funds are safely held in escrow.\nTrack delivery in real-time.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 15, color: isDarkMode ? Colors.white54 : kTextTertiary, height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Pass a more realistic order ID or a map with more info
                  Navigator.pushNamed(context, '/food-tracking', arguments: {'orderId': 'tracking-${DateTime.now().millisecondsSinceEpoch}'});
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [kPrimaryColor, kPrimaryColorLight]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    height: 54,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text('Track Order', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
