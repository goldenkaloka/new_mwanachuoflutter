import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/features/food/domain/entities/rider.dart';
import 'package:mwanachuo/features/food/presentation/bloc/food_bloc.dart';

class LiveTrackingPage extends StatefulWidget {
  final String orderId;

  const LiveTrackingPage({super.key, required this.orderId});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;

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

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? kBackgroundColorDark : const Color(0xFFF5F7FA),
      body: BlocBuilder<FoodBloc, FoodState>(
        builder: (context, state) {
          Rider? rider;
          bool isLoading = state.status == FoodStatus.loading;

          if (state.status == FoodStatus.loaded && state.rider != null) {
            rider = state.rider;
          }

          return Stack(
            children: [
              // Map Background with animated pulse
              _buildMapBackground(isDarkMode, rider),
              
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

  Widget _buildMapBackground(bool isDarkMode, Rider? rider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode
              ? [const Color(0xFF0A2E1F), kBackgroundColorDark]
              : [const Color(0xFFE8F5E9), const Color(0xFFF5F7FA)],
        ),
      ),
      child: Stack(
        children: [
          // Simulated Grid
          ...List.generate(10, (index) => Positioned(
            top: index * 100.0,
            left: 0,
            right: 0,
            child: Container(height: 0.5, color: isDarkMode ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.04)),
          )),
          
          // Animated rider dot
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80 + (_pulseController.value * 40),
                      height: 80 + (_pulseController.value * 40),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kPrimaryColor.withValues(alpha: 0.1 * (1 - _pulseController.value)),
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [kPrimaryColor, kPrimaryColorLight]),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: kPrimaryColor.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 24),
                    ),
                  ],
                );
              },
            ),
          ),
          
          // Attribution
          Positioned(
            bottom: 300,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (isDarkMode ? Colors.black : Colors.white).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Mwanachuo Logistics • Live Tracking',
                  style: GoogleFonts.plusJakartaSans(fontSize: 10, color: isDarkMode ? Colors.white54 : kTextTertiary),
                ),
              ),
            ),
          ),
        ],
      ),
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
                Text('Real-time', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: kPrimaryColor)),
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
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined, color: kPrimaryColor, size: 20),
              const SizedBox(width: 10),
              Text('Arriving in ', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: isDarkMode ? Colors.white70 : kTextSecondary)),
              Text('15 - 20 min', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: kPrimaryColor)),
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
      'preparing': 2,
      'picked_up': 3,
      'on_way': 3, // Alias for picked_up
      'delivered': 4,
    };
    
    int currentStep = statusMap[currentStatus?.toLowerCase()] ?? 0;

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
