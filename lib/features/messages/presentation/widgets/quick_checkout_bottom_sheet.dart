import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/features/products/domain/entities/product_order.dart';

class QuickCheckoutBottomSheet extends StatefulWidget {
  final String productTitle;
  final String? productImage;
  final double price;
  final String sellerName;
  final Function(
    PaymentMethod paymentMethod,
    DeliveryMethod deliveryMethod,
    String? deliveryAddress,
    String? deliveryPhone,
  )
  onConfirm;

  const QuickCheckoutBottomSheet({
    super.key,
    required this.productTitle,
    this.productImage,
    required this.price,
    required this.sellerName,
    required this.onConfirm,
  });

  @override
  State<QuickCheckoutBottomSheet> createState() =>
      _QuickCheckoutBottomSheetState();
}

class _QuickCheckoutBottomSheetState extends State<QuickCheckoutBottomSheet> {
  PaymentMethod _selectedPayment = PaymentMethod.cash;
  DeliveryMethod _selectedDelivery = DeliveryMethod.pickup;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final currencyFormatter = NumberFormat.currency(
    locale: 'en_TZ',
    symbol: 'TZS ',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Quick Checkout',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 16),

              // Product Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    if (widget.productImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.productImage!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.shopping_bag),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.productTitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Seller: ${widget.sellerName}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currencyFormatter.format(widget.price),
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: kPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Delivery Method
              Text(
                'Delivery Method',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: DeliveryMethod.values.map((method) {
                  final isSelected = _selectedDelivery == method;
                  String label = '';
                  IconData icon;

                  switch (method) {
                    case DeliveryMethod.pickup:
                      label = 'Pickup';
                      icon = Icons.storefront;
                      break;
                    case DeliveryMethod.campusDelivery:
                      label = 'Campus Delivery';
                      icon = Icons.local_shipping;
                      break;
                    case DeliveryMethod.meetup:
                      label = 'Meetup';
                      icon = Icons.people_outline;
                      break;
                  }

                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 16,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                        const SizedBox(width: 8),
                        Text(label),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedDelivery = method);
                    },
                    selectedColor: kPrimaryColor,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),

              if (_selectedDelivery == DeliveryMethod.campusDelivery) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Delivery Address / Hostel',
                    hintText: 'e.g. Hall 7, Room 302',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Required for delivery'
                      : null,
                ),
              ],

              const SizedBox(height: 20),

              // Payment Method
              Text(
                'Payment Method',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: PaymentMethod.values.map((method) {
                  final isSelected = _selectedPayment == method;
                  String label = '';
                  String description = '';
                  IconData icon;

                  switch (method) {
                    case PaymentMethod.zenopay:
                      label = 'ZenoPay Wallet';
                      description = 'Fast and secure in-app payments';
                      icon = Icons.account_balance_wallet;
                      break;
                    case PaymentMethod.cash:
                      label = 'Cash on Delivery';
                      description = 'Pay when you receive the item';
                      icon = Icons.money;
                      break;
                    case PaymentMethod.campusDelivery:
                      label = 'M-Pesa / Tigo Pesa';
                      description = 'Direct mobile money transfer to seller';
                      icon = Icons.phone_android;
                      break;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? kPrimaryColor.withValues(alpha: 0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? kPrimaryColor : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: RadioListTile<PaymentMethod>(
                      value: method,
                      groupValue: _selectedPayment,
                      activeColor: kPrimaryColor,
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedPayment = val);
                      },
                      title: Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        description,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12),
                      ),
                      secondary: Icon(
                        icon,
                        color: isSelected ? kPrimaryColor : Colors.grey,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      widget.onConfirm(
                        _selectedPayment,
                        _selectedDelivery,
                        _addressController.text.isEmpty
                            ? null
                            : _addressController.text,
                        _phoneController.text.isEmpty
                            ? null
                            : _phoneController.text,
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Confirm Purchase',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
