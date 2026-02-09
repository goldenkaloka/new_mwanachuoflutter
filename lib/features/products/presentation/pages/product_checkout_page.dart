import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/features/products/domain/entities/product_order.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_cart_bloc.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_orders_bloc.dart';
import 'package:mwanachuo/features/orders/domain/entities/campus_spot.dart';
import 'package:mwanachuo/features/orders/presentation/bloc/orders_bloc.dart';

class ProductCheckoutPage extends StatefulWidget {
  final String sellerId;
  final List<CartItem> items;

  const ProductCheckoutPage({
    super.key,
    required this.sellerId,
    required this.items,
  });

  @override
  State<ProductCheckoutPage> createState() => _ProductCheckoutPageState();
}

class _ProductCheckoutPageState extends State<ProductCheckoutPage> {
  DeliveryMethod _selectedDeliveryMethod = DeliveryMethod.pickup;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.zenopay;
  CampusSpot? _selectedSpot;
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load campus spots
    context.read<OrdersBloc>().add(LoadCampusSpots());
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  double get _subtotal {
    return widget.items.fold(0, (sum, item) => sum + item.subtotal);
  }

  double get _deliveryFee {
    return _selectedDeliveryMethod == DeliveryMethod.campusDelivery ? 2000 : 0;
  }

  double get _total => _subtotal + _deliveryFee;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode
        ? const Color(0xFF0A0E27)
        : const Color(0xFFF8F9FA);

    return BlocListener<ProductOrdersBloc, ProductOrdersState>(
      listener: (context, state) {
        if (state is ProductOrderPlaced) {
          // Clear seller cart
          context.read<ProductCartBloc>().add(ClearSellerCart(widget.sellerId));

          // Show success
          _showSuccessDialog(context, state.order);
        } else if (state is ProductOrdersError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: Text(
            'Checkout',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOrderSummary(isDarkMode),
                    const SizedBox(height: 24),
                    _buildDeliverySection(isDarkMode),
                    const SizedBox(height: 24),
                    _buildPaymentSection(isDarkMode),
                  ],
                ),
              ),
            ),
            _buildBottomBar(context, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(bool isDarkMode) {
    final cardBg = isDarkMode ? const Color(0xFF1A1F3A) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
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
          Text(
            'Order Summary',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.product.title} x${item.quantity}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14),
                    ),
                  ),
                  Text(
                    'TZS ${item.subtotal.toStringAsFixed(0)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
              ),
              Text(
                'TZS ${_subtotal.toStringAsFixed(0)}',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery Fee',
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
              ),
              Text(
                _deliveryFee > 0
                    ? 'TZS ${_deliveryFee.toStringAsFixed(0)}'
                    : 'FREE',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: _deliveryFee > 0 ? null : Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySection(bool isDarkMode) {
    final cardBg = isDarkMode ? const Color(0xFF1A1F3A) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
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
          Text(
            'Delivery Method',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDeliveryOption(
            DeliveryMethod.pickup,
            Icons.store_outlined,
            'Campus Pickup',
            'Meet at a campus spot',
            'FREE',
            isDarkMode,
          ),
          const SizedBox(height: 12),
          _buildDeliveryOption(
            DeliveryMethod.campusDelivery,
            Icons.delivery_dining,
            'Campus Delivery',
            'Delivered to your dorm',
            'TZS 2,000',
            isDarkMode,
          ),
          const SizedBox(height: 12),
          _buildDeliveryOption(
            DeliveryMethod.meetup,
            Icons.handshake_outlined,
            'Meetup',
            'Custom location with seller',
            'FREE',
            isDarkMode,
          ),

          // Campus spot selector
          if (_selectedDeliveryMethod == DeliveryMethod.pickup ||
              _selectedDeliveryMethod == DeliveryMethod.campusDelivery) ...[
            const SizedBox(height: 16),
            BlocBuilder<OrdersBloc, OrdersState>(
              builder: (context, state) {
                if (state is CampusSpotsLoaded) {
                  return DropdownButtonFormField<CampusSpot>(
                    value: _selectedSpot,
                    decoration: InputDecoration(
                      labelText: 'Select Campus Spot',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: state.spots.map((spot) {
                      return DropdownMenuItem(
                        value: spot,
                        child: Text(spot.name),
                      );
                    }).toList(),
                    onChanged: (spot) {
                      setState(() => _selectedSpot = spot);
                    },
                  );
                }
                return const CircularProgressIndicator();
              },
            ),
          ],

          // Phone and address for delivery
          if (_selectedDeliveryMethod == DeliveryMethod.campusDelivery) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Delivery Address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.location_on),
              ),
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryOption(
    DeliveryMethod method,
    IconData icon,
    String title,
    String subtitle,
    String price,
    bool isDarkMode,
  ) {
    final isSelected = _selectedDeliveryMethod == method;

    return InkWell(
      onTap: () => setState(() => _selectedDeliveryMethod = method),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? kPrimaryColor
                : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? kPrimaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? kPrimaryColor : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: price == 'FREE' ? Colors.green : kPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection(bool isDarkMode) {
    final cardBg = isDarkMode ? const Color(0xFF1A1F3A) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
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
          Text(
            'Payment Method',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPaymentOption(
            PaymentMethod.zenopay,
            Icons.account_balance_wallet,
            'ZenoPay Wallet',
            'Pay instantly with your balance',
            isDarkMode,
          ),
          const SizedBox(height: 12),
          _buildPaymentOption(
            PaymentMethod.cash,
            Icons.money,
            'Cash on Delivery',
            'Pay when you receive the item',
            isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    PaymentMethod method,
    IconData icon,
    String title,
    String subtitle,
    bool isDarkMode,
  ) {
    final isSelected = _selectedPaymentMethod == method;

    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = method),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? kPrimaryColor
                : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? kPrimaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? kPrimaryColor : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: kPrimaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isDarkMode) {
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
                  'Total',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'TZS ${_total.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: BlocBuilder<ProductOrdersBloc, ProductOrdersState>(
                  builder: (context, state) {
                    if (state is ProductOrdersLoading) {
                      return const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      );
                    }
                    return Text(
                      'Place Order',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _placeOrder() {
    // Validation
    if ((_selectedDeliveryMethod == DeliveryMethod.pickup ||
            _selectedDeliveryMethod == DeliveryMethod.campusDelivery) &&
        _selectedSpot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a campus spot')),
      );
      return;
    }

    if (_selectedDeliveryMethod == DeliveryMethod.campusDelivery) {
      if (_phoneController.text.isEmpty || _addressController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please provide phone and delivery address'),
          ),
        );
        return;
      }
    }

    // Convert CartItems to ProductOrderItems
    final orderItems = widget.items.map((cartItem) {
      return ProductOrderItem(
        id: '',
        orderId: '',
        productId: cartItem.product.id,
        productSnapshot: {
          'title': cartItem.product.title,
          'images': cartItem.product.images,
          'seller_name': cartItem.product.sellerName,
          'description': cartItem.product.description,
        },
        quantity: cartItem.quantity,
        priceAtTime: cartItem.product.price,
        createdAt: DateTime.now(),
      );
    }).toList();

    context.read<ProductOrdersBloc>().add(
      PlaceProductOrder(
        sellerId: widget.sellerId,
        items: orderItems,
        paymentMethod: _selectedPaymentMethod,
        deliveryMethod: _selectedDeliveryMethod,
        deliverySpotId: _selectedSpot?.id,
        deliveryAddress: _addressController.text.isNotEmpty
            ? _addressController.text
            : null,
        deliveryPhone: _phoneController.text.isNotEmpty
            ? _phoneController.text
            : null,
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, ProductOrder order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Order Placed!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your order has been placed successfully',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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
