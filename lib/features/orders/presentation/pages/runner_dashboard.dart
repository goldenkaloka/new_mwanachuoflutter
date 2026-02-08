import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:mwanachuo/features/orders/domain/entities/order.dart';

class RunnerDashboard extends StatefulWidget {
  const RunnerDashboard({super.key});

  @override
  State<RunnerDashboard> createState() => _RunnerDashboardState();
}

class _RunnerDashboardState extends State<RunnerDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refresh();
  }

  void _refresh() {
    context.read<OrdersBloc>().add(FetchAvailableJobs());
    context.read<OrdersBloc>().add(FetchRunnerActiveOrders());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Runner Dashboard',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
          indicatorColor: kPrimaryColor,
          labelColor: kPrimaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Available Jobs'),
            Tab(text: 'My Tasks'),
          ],
        ),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildAvailableJobsTab(), _buildMyTasksTab()],
      ),
    );
  }

  Widget _buildAvailableJobsTab() {
    return BlocBuilder<OrdersBloc, OrdersState>(
      builder: (context, state) {
        if (state is OrdersLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is OrdersFailure) {
          return Center(child: Text(state.message));
        }

        if (state is OrdersLoaded) {
          final jobs = state.availableJobs;
          if (jobs.isEmpty) {
            return _buildEmptyState(
              'No available jobs',
              Icons.delivery_dining_outlined,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            itemBuilder: (context, index) =>
                _buildJobCard(context, jobs[index], isAvailable: true),
          );
        }
        return const Center(child: Text('Refresh to see jobs'));
      },
    );
  }

  Widget _buildMyTasksTab() {
    return BlocBuilder<OrdersBloc, OrdersState>(
      builder: (context, state) {
        if (state is OrdersLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is OrdersFailure) {
          return Center(child: Text(state.message));
        }

        if (state is OrdersLoaded) {
          final tasks = state.activeRunnerOrders;
          if (tasks.isEmpty) {
            return _buildEmptyState(
              'No active tasks',
              Icons.assignment_outlined,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) =>
                _buildJobCard(context, tasks[index], isAvailable: false),
          );
        }
        return const Center(child: Text('Refresh to see tasks'));
      },
    );
  }

  Widget _buildJobCard(
    BuildContext context,
    Order job, {
    bool isAvailable = true,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${job.id.substring(0, 8)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusBadge(job.status),
              ],
            ),
            const Divider(height: 24),
            Text(
              'To: ${job.deliverySpotId ?? "Main Gate"}',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            if (job.meetingNotes != null)
              Text(
                'Note: ${job.meetingNotes}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleAction(context, job, isAvailable),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAvailable
                      ? kPrimaryColor
                      : _getActionColor(job.status),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _getActionText(job, isAvailable),
                  style: const TextStyle(
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

  void _handleAction(BuildContext context, Order job, bool isAvailable) {
    if (isAvailable) {
      context.read<OrdersBloc>().add(ClaimOrder(job.id));
    } else {
      if (job.status == OrderStatus.onWay) {
        context.read<OrdersBloc>().add(
          UpdateOrder(job.id, OrderStatus.delivered),
        );
      } else {
        // Maybe "Picked up" state?
        context.read<OrdersBloc>().add(UpdateOrder(job.id, OrderStatus.onWay));
      }
    }
  }

  String _getActionText(Order job, bool isAvailable) {
    if (isAvailable) return 'Claim Job';
    if (job.status == OrderStatus.onWay) return 'Mark Delivered';
    return 'Mark as Picked Up';
  }

  Color _getActionColor(OrderStatus status) {
    if (status == OrderStatus.onWay) return Colors.green;
    return Colors.teal;
  }

  Widget _buildStatusBadge(OrderStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.value.toUpperCase(),
        style: const TextStyle(
          color: Colors.orange,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ],
      ),
    );
  }
}
