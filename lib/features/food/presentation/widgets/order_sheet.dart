import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/features/food/domain/entities/food_item.dart';
import 'package:mwanachuo/features/food/domain/entities/restaurant.dart';
import 'package:mwanachuo/features/food/domain/entities/food_additive.dart';
import 'package:mwanachuo/features/food/presentation/bloc/food_bloc.dart';

class OrderSheet extends StatefulWidget {
  final FoodItem item;
  final Restaurant restaurant;

  const OrderSheet({super.key, required this.item, required this.restaurant});

  @override
  State<OrderSheet> createState() => _OrderSheetState();
}

class _OrderSheetState extends State<OrderSheet> {
  int _quantity = 1;
  final Set<FoodAdditive> _selectedAdditives = {};
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoadingLocation = false;
  double? _selectedLat;
  double? _selectedLng;

  double get _totalPrice {
    double base = widget.item.price * _quantity;
    double additivesTotal = _selectedAdditives.fold(0, (sum, a) => sum + (a.price * _quantity));
    return base + additivesTotal;
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      final position = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        if (!mounted) return;
        setState(() {
          _selectedLat = position.latitude;
          _selectedLng = position.longitude;
          _locationController.text = "${p.street}, ${p.subLocality}, ${p.locality}";
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
      decoration: BoxDecoration(
        color: isDarkMode ? kSurfaceColorDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDarkMode ? Colors.white : kTextPrimary,
                        ),
                      ),
                      Text(
                        'from ${widget.restaurant.name}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white54 : kTextTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Quantity Selector
            Text(
              'Quantity',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : kTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildQtyBtn(Icons.remove_rounded, () {
                  if (_quantity > 1) setState(() => _quantity--);
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '$_quantity',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: kPrimaryColor,
                    ),
                  ),
                ),
                _buildQtyBtn(Icons.add_rounded, () {
                  setState(() => _quantity++);
                }),
                const Spacer(),
                Text(
                  'TZS ${_totalPrice.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: kPrimaryColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Additives
            if (widget.item.additives != null && widget.item.additives!.isNotEmpty) ...[
              Text(
                'Add-ons',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : kTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...widget.item.additives!.map((additive) {
                final isSelected = _selectedAdditives.contains(additive);
                return _buildAdditiveItem(additive, isSelected, isDarkMode);
              }),
              const SizedBox(height: 24),
            ],
            
            // Location Field
            Text(
              'Drop-off Location',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : kTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Hostel, Room Number, or Landmark',
                prefixIcon: Icon(
                  _selectedLat != null ? Icons.gps_fixed_rounded : Icons.location_on_outlined, 
                  color: _selectedLat != null ? const Color(0xFF22C55E) : kPrimaryColor
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedLat != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'PINNED',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF22C55E),
                          ),
                        ),
                      ),
                    IconButton(
                      onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                      icon: _isLoadingLocation 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.my_location_rounded, color: _selectedLat != null ? const Color(0xFF22C55E) : kPrimaryColor),
                    ),
                  ],
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: _selectedLat != null 
                    ? const BorderSide(color: Color(0xFF22C55E), width: 1.5)
                    : BorderSide.none,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Notes Field
            Text(
              'Special Instructions (Optional)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : kTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. No onions, extra spicy...',
                filled: true,
                fillColor: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (_locationController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please provide a delivery location')),
                    );
                    return;
                  }
                  
                  final bool isBolt = widget.restaurant.distanceMeters != null && widget.restaurant.distanceMeters! > 2000;
                  final String logisticsType = isBolt ? 'BOLT' : 'INTERNAL';

                  context.read<FoodBloc>().add(PlaceOrderEvent(
                    restaurantId: widget.restaurant.id,
                    items: [{
                      'food_item_id': widget.item.id,
                      'quantity': _quantity,
                      'price': widget.item.price,
                      'selected_additives': _selectedAdditives.map((a) => {
                        'id': a.id,
                        'name': a.name,
                        'price': a.price,
                      }).toList(),
                    }],
                    totalAmount: _totalPrice,
                    lat: _selectedLat ?? 0.0,
                    lng: _selectedLng ?? 0.0,
                    droppingPoint: _locationController.text,
                    notes: _notesController.text,
                    logisticsType: logisticsType,
                  ));
                  
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  'Place Order Now',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
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

  Widget _buildAdditiveItem(FoodAdditive additive, bool isSelected, bool isDarkMode) {
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedAdditives.remove(additive);
          } else {
            _selectedAdditives.add(additive);
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? kPrimaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? kPrimaryColor : (isDarkMode ? Colors.white24 : Colors.grey.shade300),
                  width: 2,
                ),
              ),
              child: isSelected 
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                additive.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: isDarkMode ? Colors.white : kTextPrimary,
                ),
              ),
            ),
            Text(
              '+ TZS ${additive.price.toStringAsFixed(0)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: kPrimaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: kPrimaryColor, size: 24),
      ),
    );
  }
}
