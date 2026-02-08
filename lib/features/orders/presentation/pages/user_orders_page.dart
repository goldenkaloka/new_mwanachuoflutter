import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:mwanachuo/features/orders/domain/entities/order.dart';

class UserOrdersPage extends StatefulWidget {
  const UserOrdersPage({super.key});

  @override
  State<UserOrdersPage> createState() => _UserOrdersPageState();
}

class _UserOrdersPageState extends State<UserOrdersPage> {
  @override
  void initState() {
    super.initState();
    context.read<OrdersBloc>().add(FetchMyOrders());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocBuilder<OrdersBloc, OrdersState>(
        builder: (context, state) {
          if (state is OrdersLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is OrdersFailure) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (state is OrdersLoaded) {
            if (state.orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No orders yet',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.orders.length,
              itemBuilder: (context, index) {
                final order = state.orders[index];
                return _buildOrderCard(context, order);
              },
            );
          }

          return const Center(child: Text('Check your food orders!'));
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
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
                    fontSize: 16,
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
                      style: GoogleFonts.plusJakartaSans(),
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
                  'Total',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${order.totalAmount.toStringAsFixed(0)} TZS',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color color;
    switch (status) {
      case OrderStatus.pending:
        color = Colors.grey;
        break;
      case OrderStatus.confirmed:
        color = Colors.blue;
        break;
      case OrderStatus.cooking:
        color = Colors.orange;
        break;
      case OrderStatus.readyForPickup:
        color = Colors.purple;
        break;
      case OrderStatus.onWay:
        color = Colors.teal;
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.value.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
