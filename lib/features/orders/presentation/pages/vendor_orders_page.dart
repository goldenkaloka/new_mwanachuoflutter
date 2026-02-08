import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:mwanachuo/features/orders/domain/entities/order.dart';

class VendorOrdersPage extends StatefulWidget {
  const VendorOrdersPage({super.key});

  @override
  State<VendorOrdersPage> createState() => _VendorOrdersPageState();
}

class _VendorOrdersPageState extends State<VendorOrdersPage> {
  @override
  void initState() {
    super.initState();
    context.read<OrdersBloc>().add(FetchVendorOrders());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kitchen Orders',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () =>
                context.read<OrdersBloc>().add(FetchVendorOrders()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocBuilder<OrdersBloc, OrdersState>(
        builder: (context, state) {
          if (state is OrdersLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is OrdersFailure) {
            return Center(child: Text(state.message));
          }

          if (state is OrdersLoaded) {
            final orders = state.vendorOrders;
            if (orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No orders for your kitchen yet',
                      style: GoogleFonts.plusJakartaSans(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) =>
                  _buildVendorOrderCard(context, orders[index]),
            );
          }
          return const Center(child: Text('Refresh to see orders'));
        },
      ),
    );
  }

  Widget _buildVendorOrderCard(BuildContext context, Order order) {
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
                  'Order #${order.id.substring(0, 8)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusBadge(order.status),
              ],
            ),
            const Divider(height: 24),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.quantity}x ${item.productName}',
                      style: GoogleFonts.plusJakartaSans(),
                    ),
                    Text(
                      '${(item.priceAtTime * item.quantity).toStringAsFixed(0)} TZS',
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Revenue',
                  style: GoogleFonts.plusJakartaSans(color: Colors.grey),
                ),
                Text(
                  '${order.totalAmount.toStringAsFixed(0)} TZS',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (order.status != OrderStatus.delivered &&
                order.status != OrderStatus.cancelled)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleStatusUpdate(context, order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getStatusColor(order.status),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _getNextStatusText(order.status),
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

  void _handleStatusUpdate(BuildContext context, Order order) {
    OrderStatus nextStatus;
    switch (order.status) {
      case OrderStatus.pending:
        nextStatus = OrderStatus.confirmed;
        break;
      case OrderStatus.confirmed:
        nextStatus = OrderStatus.cooking;
        break;
      case OrderStatus.cooking:
        nextStatus = OrderStatus.readyForPickup;
        break;
      default:
        return;
    }
    context.read<OrdersBloc>().add(UpdateOrder(order.id, nextStatus));
  }

  String _getNextStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Confirm Order';
      case OrderStatus.confirmed:
        return 'Start Cooking';
      case OrderStatus.cooking:
        return 'Mark as Ready';
      case OrderStatus.readyForPickup:
        return 'Waiting for Runner';
      default:
        return 'Completed';
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.blue;
      case OrderStatus.confirmed:
        return Colors.orange;
      case OrderStatus.cooking:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusBadge(OrderStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.value.toUpperCase(),
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
