import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/features/food/presentation/bloc/food_bloc.dart';
import 'package:mwanachuo/features/food/presentation/pages/rider_active_delivery_screen.dart';
import 'package:mwanachuo/features/food/presentation/pages/rider_jobs_screen.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<FoodBloc>();
    bloc.add(LoadRiderProfileEvent());
    bloc.add(LoadRiderActiveJobEvent());
    bloc.add(StreamRiderJobsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? kBackgroundColorDark : const Color(0xFFF8F9FA),
      body: BlocConsumer<FoodBloc, FoodState>(
        listener: (context, state) {
          if (state.deliverySuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🎉 Delivery confirmed! Great work!'),
                backgroundColor: Colors.green,
              ),
            );
          }
          if (state.status == FoodStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, state, isDarkMode),
              SliverToBoxAdapter(child: _buildBody(context, state, isDarkMode)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, FoodState state, bool isDarkMode) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: kPrimaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kPrimaryColor, Color(0xFF00695C)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${state.riderProfile?.name.split(' ').first ?? 'Rider'} 👋',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.riderProfile?.vehicleType ?? 'Delivery Rider',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      _buildOnlineToggle(context, state),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildStatusBar(state),
                ],
              ),
            ),
          ),
        ),
      ),
      title: Text(
        'Rider Dashboard',
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RiderJobsScreen()),
              ),
            ),
            if (state.pendingJobs.isNotEmpty)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text(
                    '${state.pendingJobs.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildOnlineToggle(BuildContext context, FoodState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: state.isRiderOnline ? const Color(0xFF69F0AE) : Colors.white54,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            state.isRiderOnline ? 'Online' : 'Offline',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          CupertinoSwitch(
            value: state.isRiderOnline,
            activeTrackColor: const Color(0xFF69F0AE),
            onChanged: (value) {
              context.read<FoodBloc>().add(ToggleRiderOnlineEvent(value));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(FoodState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem('Pending Jobs', '${state.pendingJobs.length}', Icons.pending_actions),
          _buildStatDivider(),
          _buildStatItem('Rating', '${state.riderProfile?.rating.toStringAsFixed(1) ?? "5.0"} ⭐', Icons.star),
          _buildStatDivider(),
          _buildStatItem('Status', state.isRiderOnline ? '🟢 Active' : '🔴 Away', Icons.circle_outlined),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildStatDivider() => Container(width: 1, height: 30, color: Colors.white24);

  Widget _buildBody(BuildContext context, FoodState state, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active delivery card
          if (state.activeJob != null) ...[
            _buildSectionTitle('Active Delivery', isDarkMode),
            const SizedBox(height: 12),
            _buildActiveJobCard(context, state, isDarkMode),
            const SizedBox(height: 24),
          ],

          // Pending jobs
          if (state.pendingJobs.isNotEmpty) ...[
            _buildSectionTitle('Incoming Jobs (${state.pendingJobs.length})', isDarkMode),
            const SizedBox(height: 12),
            _buildPendingJobsBanner(context, state, isDarkMode),
            const SizedBox(height: 24),
          ],

          // Empty state when idle
          if (state.activeJob == null && state.pendingJobs.isEmpty)
            _buildIdleState(state, isDarkMode),

          const SizedBox(height: 24),
          _buildQuickStats(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildActiveJobCard(BuildContext context, FoodState state, bool isDarkMode) {
    final job = state.activeJob!;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RiderActiveDeliveryScreen(order: job)),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kPrimaryColor, Color(0xFF00695C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Delivery',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 12),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    job.status.name.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'TZS ${NumberFormat('#,###').format(job.totalAmount)}',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              job.droppingPoint ?? 'Tap to navigate',
              style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map_outlined, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Open Navigation',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingJobsBanner(BuildContext context, FoodState state, bool isDarkMode) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RiderJobsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.delivery_dining, color: Colors.orange, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${state.pendingJobs.length} new delivery request${state.pendingJobs.length > 1 ? 's' : ''}!',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                  ),
                  Text(
                    'Tap to view and accept',
                    style: GoogleFonts.plusJakartaSans(color: Colors.orange.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildIdleState(FoodState state, bool isDarkMode) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(
            state.isRiderOnline ? Icons.moped_outlined : Icons.power_settings_new,
            size: 80,
            color: state.isRiderOnline ? kPrimaryColor : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            state.isRiderOnline
                ? 'Looking for deliveries nearby...'
                : 'You are currently offline',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.isRiderOnline
                ? 'New orders will appear here automatically'
                : 'Toggle the switch above to go online',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDarkMode ? Colors.white38 : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(bool isDarkMode) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Today', '0 deliveries', Icons.today, Colors.blue, isDarkMode)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Earnings', 'TZS 0', Icons.payments_outlined, Colors.green, isDarkMode)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? kSurfaceColorDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: isDarkMode ? Colors.white : Colors.black87)),
              Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
