import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/features/food/domain/entities/food_order.dart';
import 'package:mwanachuo/features/food/domain/entities/order_item.dart';
import 'package:mwanachuo/features/food/presentation/bloc/food_bloc.dart';
import 'package:intl/intl.dart';

class RestaurantAdminDashboard extends StatefulWidget {
  const RestaurantAdminDashboard({super.key});

  @override
  State<RestaurantAdminDashboard> createState() => _RestaurantAdminDashboardState();
}

class _RestaurantAdminDashboardState extends State<RestaurantAdminDashboard> {
  @override
  void initState() {
    super.initState();
    final restaurant = context.read<FoodBloc>().state.userRestaurant;
    if (restaurant != null) {
      context.read<FoodBloc>().add(LoadRestaurantOrders(restaurant.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? kBackgroundColorDark : Colors.white,
      appBar: AppBar(
        title: Text(
          'Restaurant Manager', 
          style: GoogleFonts.plusJakartaSans(
            color: isDarkMode ? Colors.white : Colors.black, 
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDarkMode ? kSurfaceColorDark : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: isDarkMode ? Colors.white : Colors.black), 
            onPressed: () {
              final restaurant = context.read<FoodBloc>().state.userRestaurant;
              if (restaurant != null) {
                context.read<FoodBloc>().add(LoadRestaurantOrders(restaurant.id));
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<FoodBloc, FoodState>(
        builder: (context, state) {
          if (state.status == FoodStatus.loading && state.restaurantOrders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              if (state.userRestaurant != null) {
                context.read<FoodBloc>().add(LoadRestaurantOrders(state.userRestaurant!.id));
              }
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildStatsGrid(state, isDarkMode),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Live Orders', '${state.restaurantOrders.length} active', isDarkMode),
                  const SizedBox(height: 16),
                  if (state.restaurantOrders.isEmpty)
                    _buildEmptyOrders(isDarkMode)
                  else
                    _buildOrderList(state.restaurantOrders, isDarkMode),
                  const SizedBox(height: 32),
                  _buildQuickActions(context, isDarkMode),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyOrders(bool isDarkMode) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.shopping_bag_outlined, size: 64, color: isDarkMode ? Colors.white24 : Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No orders yet',
            style: GoogleFonts.plusJakartaSans(
              color: isDarkMode ? Colors.white38 : Colors.grey[500],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(FoodState state, bool isDarkMode) {
    final totalIncome = state.restaurantOrders
        .where((o) => o.status == FoodOrderStatus.completed)
        .fold(0.0, (sum, o) => sum + o.totalAmount);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Income', 'TZS ${NumberFormat('#,###').format(totalIncome)}', Icons.payments_outlined, kSuccessColor),
        _buildStatCard('All Orders', state.restaurantOrders.length.toString(), Icons.shopping_bag_outlined, kInfoColor),
        _buildStatCard('Active', state.restaurantOrders.where((o) => o.status != FoodOrderStatus.completed && o.status != FoodOrderStatus.cancelled && o.status != FoodOrderStatus.rejected).length.toString(), Icons.pending_actions, kWarningColor),
        _buildStatCard('Status', state.userRestaurant?.isActive ?? false ? 'Open' : 'Closed', Icons.access_time, kPrimaryColor),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                child: Text(
                  value, 
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold, 
                    color: color,
                  ),
                ),
              ),
              Text(
                label, 
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, 
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title, 
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isDarkMode ? Colors.white38 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderList(List<FoodOrder> orders, bool isDarkMode) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      itemBuilder: (context, index) => _buildOrderItem(orders[index], isDarkMode),
    );
  }

  Widget _buildOrderItem(FoodOrder order, bool isDarkMode) {
    final statusColor = _getStatusColor(order.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? kSurfaceColorDark : Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: kPrimaryColor.withValues(alpha: 0.1), 
                child: Text('#${order.id.substring(0, 3)}', style: const TextStyle(color: kPrimaryColor, fontSize: 10)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.studentName ?? 'Customer', 
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm, dd MMM').format(order.createdAt),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, 
                        color: isDarkMode ? Colors.white38 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  order.status.name.toUpperCase(), 
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10, 
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...order.items?.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${item.quantity}x ${item.foodName}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
                Text(
                  'TZS ${NumberFormat('#,###').format(item.subtotal)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )).toList() ?? [],
          const SizedBox(height: 8),
          Text(
            'Total: TZS ${NumberFormat('#,###').format(order.totalAmount)}',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: kPrimaryColor,
            ),
          ),
          if (order.droppingPoint != null || (order.deliveryLat != null && order.deliveryLng != null))
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kPrimaryColor.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: kPrimaryColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.droppingPoint ?? 'GPS Coordinates',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : kTextPrimary,
                            ),
                          ),
                          if (order.deliveryLat != null)
                            Text(
                              '${order.deliveryLat?.toStringAsFixed(4)}, ${order.deliveryLng?.toStringAsFixed(4)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: isDarkMode ? Colors.white38 : kTextTertiary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        if (order.deliveryLat != null && order.deliveryLng != null) {
                           // This would normally open a map or navigation
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('Opening navigation to ${order.deliveryLat}, ${order.deliveryLng}')),
                           );
                        }
                      },
                      icon: const Icon(Icons.map_rounded, size: 16),
                      label: const Text('Map', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: kPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (order.rejectionReason != null)
             Padding(
               padding: const EdgeInsets.only(top: 8),
               child: Text(
                 'Reason: ${order.rejectionReason}',
                 style: const TextStyle(color: Colors.red, fontSize: 12, fontStyle: FontStyle.italic),
               ),
             ),
          const SizedBox(height: 16),
          _buildActionButtons(order, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildActionButtons(FoodOrder order, bool isDarkMode) {
    if (order.status == FoodOrderStatus.completed || order.status == FoodOrderStatus.cancelled || order.status == FoodOrderStatus.rejected) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (order.status == FoodOrderStatus.pending) ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateStatus(order, FoodOrderStatus.confirmed),
              style: ElevatedButton.styleFrom(
                backgroundColor: kSuccessColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Accept'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showRejectDialog(order),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Reject'),
            ),
          ),
        ],
        if (order.status == FoodOrderStatus.confirmed)
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateStatus(order, FoodOrderStatus.preparing),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Start Processing'),
            ),
          ),
        if (order.status == FoodOrderStatus.preparing)
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateStatus(order, FoodOrderStatus.pickedUp),
              style: ElevatedButton.styleFrom(
                backgroundColor: kInfoColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Out for Delivery'),
            ),
          ),
        if (order.status == FoodOrderStatus.pickedUp || order.status == FoodOrderStatus.nearYou || order.status == FoodOrderStatus.readyForPickup)
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateStatus(order, FoodOrderStatus.completed),
              style: ElevatedButton.styleFrom(
                backgroundColor: kSuccessColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Mark Completed'),
            ),
          ),
      ],
    );
  }

  void _updateStatus(FoodOrder order, FoodOrderStatus status, {String? reason}) {
    context.read<FoodBloc>().add(UpdateOrderStatusEvent(
      orderId: order.id,
      status: status,
      rejectionReason: reason,
      restaurantId: order.restaurantId,
    ));

    // Automatically dispatch nearby rider if food is being prepared or ready
    if (status == FoodOrderStatus.preparing || status == FoodOrderStatus.readyForPickup) {
      if (order.deliveryLat != null && order.deliveryLng != null) {
        context.read<FoodBloc>().add(DispatchRiderEvent(order));
      }
    }
  }

  Future<void> _showRejectDialog(FoodOrder order) async {
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter reason for rejection',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _updateStatus(order, FoodOrderStatus.rejected, reason: controller.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Reject Order'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(FoodOrderStatus status) {
    switch (status) {
      case FoodOrderStatus.pending: return kInfoColor;
      case FoodOrderStatus.confirmed: return kSuccessColor;
      case FoodOrderStatus.riderAssigned: return Colors.teal;
      case FoodOrderStatus.preparing: return kWarningColor;
      case FoodOrderStatus.readyForPickup: return kPrimaryColor;
      case FoodOrderStatus.pickedUp: return Colors.orange;
      case FoodOrderStatus.outForDelivery: return Colors.deepOrange;
      case FoodOrderStatus.nearYou: return Colors.blue;
      case FoodOrderStatus.delivered: return Colors.indigo;
      case FoodOrderStatus.completed: return kSuccessColor;
      case FoodOrderStatus.cancelled:
      case FoodOrderStatus.rejected: return Colors.red;
    }
  }

  Widget _buildQuickActions(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Management', 
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20, 
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionTile(context, Icons.restaurant_menu, 'Manage Menu', 'Update prices and items', () {
          Navigator.pushNamed(context, '/restaurant-menu-manage');
        }, isDarkMode),
        _buildActionTile(context, Icons.history, 'Order History', 'View past transactions', () {}, isDarkMode),
      ],
    );
  }

  Widget _buildActionTile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap, bool isDarkMode) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white10 : Colors.grey[100], 
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: kPrimaryColor),
      ),
      title: Text(
        title, 
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle, 
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12, 
          color: isDarkMode ? Colors.white38 : Colors.grey[600],
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}

extension OrderItemExtension on OrderItem {
  double get subtotal => quantity * unitPrice;
}
