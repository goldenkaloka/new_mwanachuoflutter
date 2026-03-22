import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/features/food/domain/entities/food_order.dart';
import 'package:mwanachuo/features/food/presentation/bloc/food_bloc.dart';

class RiderActiveDeliveryScreen extends StatefulWidget {
  final FoodOrder order;
  const RiderActiveDeliveryScreen({super.key, required this.order});

  @override
  State<RiderActiveDeliveryScreen> createState() => _RiderActiveDeliveryScreenState();
}

class _RiderActiveDeliveryScreenState extends State<RiderActiveDeliveryScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _locationSub;
  LatLng? _riderLocation;
  List<LatLng> _routePoints = [];
  String? _eta;
  bool _isPhaseB = false; // false = ride to restaurant, true = ride to customer

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
    _determinePhase();
  }

  void _determinePhase() {
    final status = widget.order.status;
    setState(() {
      _isPhaseB = status == FoodOrderStatus.pickedUp ||
          status == FoodOrderStatus.outForDelivery ||
          status == FoodOrderStatus.nearYou;
    });
  }

  void _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return;

    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((pos) {
      final location = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() => _riderLocation = location);

      // Update Supabase with rider location
      if (mounted) {
        context.read<FoodBloc>().add(UpdateRiderLocationEvent(lat: pos.latitude, lng: pos.longitude));
      }

      // Fetch route to target
      _fetchRoute(location);

      // Snap the map to rider position
      try {
        _mapController.move(location, _mapController.camera.zoom);
      } catch (_) {}
    });
  }

  Future<void> _fetchRoute(LatLng from) async {
    LatLng? to;
    if (!_isPhaseB && widget.order.restaurantLat != null && widget.order.restaurantLng != null) {
      to = LatLng(widget.order.restaurantLat!, widget.order.restaurantLng!);
    } else if (_isPhaseB && widget.order.deliveryLat != null && widget.order.deliveryLng != null) {
      to = LatLng(widget.order.deliveryLat!, widget.order.deliveryLng!);
    }
    if (to == null) return;

    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/${from.longitude},${from.latitude};${to.longitude},${to.latitude}?overview=full&geometries=geojson&steps=false';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final route = data['routes']?[0];
        if (route == null) return;

        final coords = route['geometry']['coordinates'] as List;
        final durationSecs = route['duration'] as num;
        final etaMins = (durationSecs / 60).ceil();

        setState(() {
          _routePoints = coords.map<LatLng>((c) => LatLng(c[1] as double, c[0] as double)).toList();
          _eta = '$etaMins min';
        });
      }
    } catch (e) {
      // Route fetch failed silently - map still shows markers
    }
  }

  LatLng get _targetLocation {
    if (!_isPhaseB) {
      if (widget.order.restaurantLat != null) return LatLng(widget.order.restaurantLat!, widget.order.restaurantLng!);
    } else {
      if (widget.order.deliveryLat != null) return LatLng(widget.order.deliveryLat!, widget.order.deliveryLng!);
    }
    return const LatLng(-6.7924, 39.2023); // Default: campus center
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<FoodBloc, FoodState>(
      listener: (context, state) {
        if (state.deliverySuccess) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🎉 Delivery completed!'), backgroundColor: Colors.green),
          );
        }
        if (state.status == FoodStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Error'), backgroundColor: Colors.red),
          );
        }
        // Update current order status from active job
        if (state.activeJob != null) {
          _determinePhase();
        }
      },
      builder: (context, state) {
        final activeOrder = state.activeJob ?? widget.order;

        return Scaffold(
          body: Stack(
            children: [
              // Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _riderLocation ?? _targetLocation,
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.mwanachuo.app',
                  ),
                  // Route polyline
                  if (_routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 5,
                          color: kPrimaryColor,
                        ),
                      ],
                    ),
                  // Markers
                  MarkerLayer(
                    markers: [
                      if (_riderLocation != null)
                        Marker(
                          point: _riderLocation!,
                          width: 50,
                          height: 50,
                          child: Container(
                            decoration: BoxDecoration(
                              color: kPrimaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [BoxShadow(color: kPrimaryColor.withValues(alpha: 0.4), blurRadius: 10)],
                            ),
                            child: const Icon(Icons.delivery_dining, color: Colors.white, size: 24),
                          ),
                        ),
                      // Target marker
                      Marker(
                        point: _targetLocation,
                        width: 50,
                        height: 60,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isPhaseB ? Colors.deepOrange : kPrimaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: Icon(
                                _isPhaseB ? Icons.person_pin_circle : Icons.store,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            Container(width: 2, height: 10, color: _isPhaseB ? Colors.deepOrange : kPrimaryColor),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Top bar with back button and ETA
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                          ),
                          child: const Icon(Icons.arrow_back),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_eta != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: kPrimaryColor.withValues(alpha: 0.3), blurRadius: 10)],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.timer_outlined, color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'ETA: $_eta',
                                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Bottom action sheet
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildActionSheet(context, activeOrder, isDarkMode),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionSheet(BuildContext context, FoodOrder order, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? kSurfaceColorDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),

          // Phase indicator
          Row(
            children: [
              _buildPhaseChip('1', !_isPhaseB ? 'Go to restaurant' : '✓ At restaurant', !_isPhaseB, isDarkMode),
              Expanded(child: Container(height: 2, color: _isPhaseB ? kPrimaryColor : Colors.grey[300])),
              _buildPhaseChip('2', _isPhaseB ? 'Deliver to customer' : 'Deliver to customer', _isPhaseB, isDarkMode),
            ],
          ),
          const SizedBox(height: 16),

          // Order info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white10 : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order Total', style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 11)),
                    Text(
                      'TZS ${NumberFormat('#,###').format(order.totalAmount)}',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: isDarkMode ? Colors.white : Colors.black87),
                    ),
                  ],
                ),
                if (order.deliveryOtp != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Delivery OTP', style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 11)),
                      Text(
                        '••••••',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: kPrimaryColor),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action button based on status
          _buildStatusButton(context, order),
        ],
      ),
    );
  }

  Widget _buildPhaseChip(String num, String label, bool isActive, bool isDarkMode) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? kPrimaryColor : Colors.grey[300],
          ),
          child: Center(
            child: Text(num, style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 10, color: isActive ? kPrimaryColor : Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatusButton(BuildContext context, FoodOrder order) {
    switch (order.status) {
      case FoodOrderStatus.riderAssigned:
      case FoodOrderStatus.confirmed:
        return _actionButton(
          'Arrived at Restaurant',
          Icons.store_outlined,
          kPrimaryColor,
          () => context.read<FoodBloc>().add(UpdateOrderStatusAsRiderEvent(
            orderId: order.id,
            status: FoodOrderStatus.pickedUp,
          )),
        );

      case FoodOrderStatus.preparing:
      case FoodOrderStatus.readyForPickup:
        return _actionButton(
          'Confirm Food Picked Up',
          Icons.takeout_dining_outlined,
          Colors.orange,
          () {
            setState(() => _isPhaseB = true);
            context.read<FoodBloc>().add(UpdateOrderStatusAsRiderEvent(
              orderId: order.id,
              status: FoodOrderStatus.outForDelivery,
            ));
          },
        );

      case FoodOrderStatus.pickedUp:
      case FoodOrderStatus.outForDelivery:
      case FoodOrderStatus.nearYou:
        return _actionButton(
          'Enter Delivery OTP',
          Icons.lock_open_outlined,
          Colors.green,
          () => _showOtpDialog(context, order),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }

  void _showOtpDialog(BuildContext context, FoodOrder order) {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Confirm Delivery', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ask the customer for their 6-digit OTP code to confirm delivery',
              style: GoogleFonts.plusJakartaSans(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: InputDecoration(
                hintText: '000000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (otpController.text.length == 6) {
                Navigator.pop(dialogContext);
                context.read<FoodBloc>().add(MarkDeliveredEvent(
                  orderId: order.id,
                  otp: otpController.text,
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
