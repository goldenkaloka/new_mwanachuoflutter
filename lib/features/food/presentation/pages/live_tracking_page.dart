import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/features/food/domain/entities/food_order.dart';
import 'package:mwanachuo/features/food/domain/entities/rider.dart';
import 'package:mwanachuo/features/food/presentation/bloc/food_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LiveTrackingPage extends StatefulWidget {
  final String orderId;

  const LiveTrackingPage({super.key, required this.orderId});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  
  // Real Tracking
  final MapController _mapController = MapController();
  StreamSubscription<List<Map<String, dynamic>>>? _locationSub;
  LatLng? _riderLocation;
  List<LatLng> _routePoints = [];
  String? _eta;
  String? _trackedRiderId;
  bool _isInitFetch = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    // Fetch real tracking data
    context.read<FoodBloc>().add(LoadTracking(widget.orderId));
  }

  void _startLocationTracking(String riderId, FoodOrder order) {
    if (_trackedRiderId == riderId) return;
    _trackedRiderId = riderId;
    _locationSub?.cancel();

    _locationSub = Supabase.instance.client
        .from('rider_locations')
        .stream(primaryKey: ['rider_id'])
        .eq('rider_id', riderId)
        .listen((data) {
      if (data.isNotEmpty) {
        final loc = data.first;
        final lat = (loc['lat'] as num).toDouble();
        final lng = (loc['lng'] as num).toDouble();
        final location = LatLng(lat, lng);
        
        if (!mounted) return;
        setState(() => _riderLocation = location);

        _fetchRoute(location, order);

        // Snap the map to rider position only for the first few updates to not annoy the user
        if (_isInitFetch) {
          _isInitFetch = false;
          try {
            _mapController.move(location, _mapController.camera.zoom);
          } catch (_) {}
        }
      }
    });
  }

  Future<void> _fetchRoute(LatLng from, FoodOrder order) async {
    // If order is outForDelivery, target is delivery location. Otherwise, restaurant.
    LatLng? to;
    final isGoingToCustomer = order.status == FoodOrderStatus.pickedUp || 
                              order.status == FoodOrderStatus.outForDelivery || 
                              order.status == FoodOrderStatus.nearYou;

    if (!isGoingToCustomer && order.restaurantLat != null) {
      to = LatLng(order.restaurantLat!, order.restaurantLng!);
    } else if (order.deliveryLat != null) {
      to = LatLng(order.deliveryLat!, order.deliveryLng!);
    }
    
    if (to == null) return;

    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/${from.longitude},${from.latitude};${to.longitude},${to.latitude}?overview=full&geometries=geojson&steps=false';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final route = json['routes']?[0];
        if (route == null) return;

        final coords = route['geometry']['coordinates'] as List;
        final durationSecs = route['duration'] as num;
        final etaMins = (durationSecs / 60).ceil();

        if (!mounted) return;
        setState(() {
          _routePoints = coords.map<LatLng>((c) => LatLng(c[1] as double, c[0] as double)).toList();
          _eta = '$etaMins min';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? kBackgroundColorDark : const Color(0xFFF5F7FA),
      body: BlocConsumer<FoodBloc, FoodState>(
        listener: (context, state) {
          if (state.trackingOrder != null && state.rider != null) {
            _startLocationTracking(state.rider!.id, state.trackingOrder!);
          }
        },
        builder: (context, state) {
          Rider? rider = state.rider;
          FoodOrder? order = state.trackingOrder;
          bool isLoading = state.status == FoodStatus.loading;

          return Stack(
            children: [
              // Map Background 
              _buildMapBackground(isDarkMode, order),
              
              // Top bar
              _buildTopBar(context, isDarkMode),
              
              // ETA floating card
              _buildEtaCard(isDarkMode),

              // Bottom tracking card
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                      .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic)),
                  child: _buildTrackingCard(context, isDarkMode, rider, isLoading, state.orderStatus, state.trackingLink),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMapBackground(bool isDarkMode, FoodOrder? order) {
    LatLng? targetLocation;
    bool isGoingToCustomer = false;
    
    if (order != null) {
      isGoingToCustomer = order.status == FoodOrderStatus.pickedUp || 
                          order.status == FoodOrderStatus.outForDelivery || 
                          order.status == FoodOrderStatus.nearYou;
      
      if (!isGoingToCustomer && order.restaurantLat != null) {
        targetLocation = LatLng(order.restaurantLat!, order.restaurantLng!);
      } else if (order.deliveryLat != null) {
        targetLocation = LatLng(order.deliveryLat!, order.deliveryLng!);
      }
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _riderLocation ?? targetLocation ?? const LatLng(-6.7924, 39.2023),
        initialZoom: 15,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.mwanachuo.app',
        ),
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
        MarkerLayer(
          markers: [
            // Target Marker (Restaurant or Customer)
            if (targetLocation != null)
              Marker(
                point: targetLocation,
                width: 50,
                height: 60,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isGoingToCustomer ? Colors.deepOrange : kPrimaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Icon(
                        isGoingToCustomer ? Icons.person_pin_circle : Icons.store,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    Container(width: 2, height: 10, color: isGoingToCustomer ? Colors.deepOrange : kPrimaryColor),
                  ],
                ),
              ),
            // Rider Marker
            if (_riderLocation != null)
              Marker(
                point: _riderLocation!,
                width: 70,
                height: 70,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 50 + (_pulseController.value * 20),
                          height: 50 + (_pulseController.value * 20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kPrimaryColor.withValues(alpha: 0.2 * (1 - _pulseController.value)),
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [kPrimaryColor, kPrimaryColorLight]),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [BoxShadow(color: kPrimaryColor.withValues(alpha: 0.4), blurRadius: 10)],
                          ),
                          child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 20),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDarkMode) {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildGlassIconButton(
            icon: Icons.close_rounded,
            onTap: () => Navigator.pop(context),
            isDarkMode: isDarkMode,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.radio_button_checked, color: kPrimaryColor, size: 14),
                const SizedBox(width: 8),
                Text('Real-time Map', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: kPrimaryColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassIconButton({required IconData icon, required VoidCallback onTap, required bool isDarkMode}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDarkMode ? Colors.black : Colors.white).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Icon(icon, color: isDarkMode ? Colors.white : kTextPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildEtaCard(bool isDarkMode) {
    if (_eta == null) return const SizedBox.shrink();
    return Positioned(
      top: 120,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: (isDarkMode ? kSurfaceColorDark : Colors.white).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined, color: kPrimaryColor, size: 20),
              const SizedBox(width: 10),
              Text('Arriving in ', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: isDarkMode ? Colors.white70 : kTextSecondary)),
              Text(_eta!, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: kPrimaryColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingCard(BuildContext context, bool isDarkMode, Rider? rider, bool isLoading, String? orderStatus, String? trackingLink) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(
        color: isDarkMode ? kSurfaceColorDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 40, offset: const Offset(0, -10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: isDarkMode ? Colors.white12 : Colors.grey.shade200, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 25),
          _buildProgressSteps(isDarkMode, orderStatus),
          const SizedBox(height: 30),
          if (trackingLink != null) 
            _buildBoltTracking(trackingLink),
          if (isLoading)
            const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: kPrimaryColor)))
          else
            _buildRiderInfo(isDarkMode, rider),
          const SizedBox(height: 25),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildProgressSteps(bool isDarkMode, String? currentStatus) {
    final statusMap = {
      'pending': 0,
      'confirmed': 1,
      'riderAssigned': 1,
      'preparing': 2,
      'readyForPickup': 2,
      'pickedUp': 3,
      'outForDelivery': 3,
      'nearYou': 3,
      'delivered': 4,
    };
    
    int currentStep = statusMap[currentStatus] ?? 0;

    final steps = [
      {'icon': Icons.check_circle_rounded, 'label': 'Order'},
      {'icon': Icons.verified_rounded, 'label': 'Confirmed'},
      {'icon': Icons.restaurant_rounded, 'label': 'Preparing'},
      {'icon': Icons.delivery_dining_rounded, 'label': 'On Way'},
      {'icon': Icons.home_rounded, 'label': 'Delivered'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: steps.asMap().entries.map((e) {
        final index = e.key;
        final step = e.value;
        final isDone = index <= currentStep;
        return Expanded(
          child: Column(
            children: [
              Icon(step['icon'] as IconData, color: isDone ? kPrimaryColor : (isDarkMode ? Colors.white12 : Colors.grey.shade300), size: 22),
              const SizedBox(height: 8),
              Text(step['label'] as String, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: isDone ? kPrimaryColor : (isDarkMode ? Colors.white24 : Colors.grey.shade400))),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBoltTracking(String trackingLink) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF34D399).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.delivery_dining, color: Color(0xFF059669)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bolt Delivery Tracking', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF065F46))),
                Text('Track your delivery live on Bolt', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF065F46).withValues(alpha: 0.7))),
              ],
            ),
          ),
          TextButton(
             onPressed: () => launchUrl(Uri.parse(trackingLink)),
             child: Text('VIEW', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF059669))),
          )
        ],
      ),
    );
  }

  Widget _buildRiderInfo(bool isDarkMode, Rider? rider) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: kPrimaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            image: rider?.avatarUrl != null ? DecorationImage(image: NetworkImage(rider!.avatarUrl!), fit: BoxFit.cover) : null,
          ),
          child: rider?.avatarUrl == null ? const Icon(Icons.person_rounded, color: kPrimaryColor, size: 28) : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rider?.name ?? 'Assigning Rider...', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: isDarkMode ? Colors.white : kTextPrimary)),
              const SizedBox(height: 4),
              Text('${rider?.vehicleType ?? 'Logistics'} • ★ ${rider?.rating ?? '5.0'}', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: isDarkMode ? Colors.white38 : kTextTertiary)),
            ],
          ),
        ),
        _buildCircularAction(Icons.phone_in_talk_rounded, const Color(0xFF22C55E)),
        const SizedBox(width: 12),
        _buildCircularAction(Icons.chat_bubble_rounded, kPrimaryColor),
      ],
    );
  }

  Widget _buildCircularAction(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, '/delivery-qr-scan'),
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: Text('Scan Delivery QR', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
