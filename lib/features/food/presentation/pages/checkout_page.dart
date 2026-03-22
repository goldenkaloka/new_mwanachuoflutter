import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/features/food/domain/entities/restaurant.dart';
import 'package:mwanachuo/features/food/domain/entities/food_item.dart';
import 'package:mwanachuo/features/food/presentation/bloc/food_bloc.dart';

import 'package:geolocator/geolocator.dart';

class CheckoutPage extends StatefulWidget {
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
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  double? _selectedLat;
  double? _selectedLng;
  String? _selectedAddress;
  bool _isLocationLoading = false;

  @override
  void initState() {
    super.initState();
    // Default to university if not set
    _selectedLat = context.read<FoodBloc>().state.userLat;
    _selectedLng = context.read<FoodBloc>().state.userLng;
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocationLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled.')),
          );
        }
        setState(() => _isLocationLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied.')),
            );
          }
          setState(() => _isLocationLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are permanently denied.')),
          );
        }
        setState(() => _isLocationLoading = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLat = position.latitude;
        _selectedLng = position.longitude;
        _selectedAddress = "Custom Drop-off Point Set";
        _isLocationLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      setState(() => _isLocationLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'TZS ', decimalDigits: 0);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<FoodBloc, FoodState>(
      listener: (context, state) {
        if (state.orderSuccess) {
          _showConfirmation(context, isDarkMode, state.lastOrderId);
        } else if (state.status == FoodStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Order failed'), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: isDarkMode ? kBackgroundColorDark : const Color(0xFFF5F7FA),
          body: Stack(
            children: [
              CustomScrollView(
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
                          _buildPlaceOrderButton(context, state, currencyFormat, isDarkMode, state.status == FoodStatus.loading),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (state.status == FoodStatus.loading)
                Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator(color: kPrimaryColor)),
                ),
            ],
          ),
        );
      },
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
      child: InkWell(
        onTap: _isLocationLoading ? null : _getCurrentLocation,
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: _isLocationLoading 
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.location_on_rounded, color: kPrimaryColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedAddress ?? 'Set Drop-off Point',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: isDarkMode ? Colors.white : kTextPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedLat != null && _selectedLng != null 
                        ? '${_selectedLat!.toStringAsFixed(4)}, ${_selectedLng!.toStringAsFixed(4)}'
                        : 'Tap to pick your current location',
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
              child: Text(
                _selectedLat != null ? 'Change' : 'Pick', 
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: kPrimaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(NumberFormat format, bool isDarkMode) {
    // Granular delivery fee: Base 1500 + 700 per km
    final double distanceKm = (widget.restaurant.distanceMeters ?? 0) / 1000;
    final double baseFee = 1500;
    final double distanceFee = (distanceKm * 700).clamp(0, 10000); // Cap distance fee at 10k
    final double finalDeliveryFee = baseFee + distanceFee;
    final bool isBolt = distanceKm > 2.5;

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
          ...widget.cartItems.map((item) => Padding(
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
          _buildPriceRow('Subtotal', format.format(widget.totalAmount), isDarkMode, false),
          const SizedBox(height: 8),
          _buildPriceRow(isBolt ? 'Bolt Delivery' : 'Delivery', format.format(finalDeliveryFee), isDarkMode, false),
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
                  format.format(widget.totalAmount + finalDeliveryFee),
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

  Widget _buildPlaceOrderButton(BuildContext context, FoodState state, NumberFormat format, bool isDarkMode, bool isLoading) {
    final bool isBolt = widget.restaurant.distanceMeters != null && widget.restaurant.distanceMeters! > 2000;
    final String logisticsType = isBolt ? 'BOLT' : 'INTERNAL';
    
    // Delivery fee from state summary
    final double distanceKm = (widget.restaurant.distanceMeters ?? 0) / 1000;
    final double finalDeliveryFee = 1500 + (distanceKm * 700).clamp(0, 10000);

    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: (isLoading || _selectedLat == null) ? null : () {
          context.read<FoodBloc>().add(PlaceOrderEvent(
            restaurantId: widget.restaurant.id,
            items: widget.cartItems.map((e) => {
              'food_item_id': e.id,
              'name': e.name,
              'price': e.price,
              'quantity': 1,
            }).toList(),
            totalAmount: widget.totalAmount + finalDeliveryFee,
            lat: _selectedLat!, 
            lng: _selectedLng!,
            logisticsType: logisticsType,
          ));
        },
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
                  'Confirm & Lock ${format.format(widget.totalAmount + finalDeliveryFee)}',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showConfirmation(BuildContext context, bool isDarkMode, String? orderId) {
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
                  if (orderId != null) {
                    Navigator.pushNamed(context, '/food-tracking', arguments: {'orderId': orderId});
                  }
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
