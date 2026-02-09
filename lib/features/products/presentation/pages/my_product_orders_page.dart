import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/features/products/domain/entities/product_order.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_orders_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;

class MyProductOrdersPage extends StatefulWidget {
  const MyProductOrdersPage({super.key});

  @override
  State<MyProductOrdersPage> createState() => _MyProductOrdersPageState();
}

class _MyProductOrdersPageState extends State<MyProductOrdersPage> {
  ProductOrderStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    context.read<ProductOrdersBloc>().add(
      FetchMyProductOrders(status: _selectedStatus),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode
        ? const Color(0xFF0A0E27)
        : const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'My Orders',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildStatusFilter(isDarkMode),
          Expanded(
            child: BlocBuilder<ProductOrdersBloc, ProductOrdersState>(
              builder: (context, state) {
                if (state is ProductOrdersLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ProductOrdersError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          style: GoogleFonts.plusJakartaSans(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadOrders,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is ProductOrdersLoaded) {
                  if (state.orders.isEmpty) {
                    return _buildEmptyState(isDarkMode);
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _loadOrders(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.orders.length,
                      itemBuilder: (context, index) {
                        return _buildOrderCard(state.orders[index], isDarkMode);
                      },
                    ),
                  );
                }

                return _buildEmptyState(isDarkMode);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(bool isDarkMode) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('All', null, isDarkMode),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Pending',
            ProductOrderStatus.pendingPayment,
            isDarkMode,
          ),
          const SizedBox(width: 8),
          _buildFilterChip('Paid', ProductOrderStatus.paid, isDarkMode),
          const SizedBox(width: 8),
          _buildFilterChip('Shipped', ProductOrderStatus.shipped, isDarkMode),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Delivered',
            ProductOrderStatus.delivered,
            isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    ProductOrderStatus? status,
    bool isDarkMode,
  ) {
    final isSelected = _selectedStatus == status;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedStatus = selected ? status : null);
        _loadOrders();
      },
      backgroundColor: isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
      selectedColor: kPrimaryColor.withValues(alpha: 0.2),
      labelStyle: GoogleFonts.plusJakartaSans(
        color: isSelected
            ? kPrimaryColor
            : (isDarkMode ? Colors.white : Colors.black87),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? kPrimaryColor : Colors.grey.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kPrimaryColor.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: kPrimaryColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No orders yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF11221F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your order history will appear here',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(ProductOrder order, bool isDarkMode) {
    final cardBg = isDarkMode ? const Color(0xFF1A1F3A) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(order.orderStatus).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id.substring(0, 8)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        timeago.format(order.createdAt),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.orderStatus),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusLabel(order.orderStatus),
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Items
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...order.items
                    .take(2)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl:
                                    (item.productSnapshot['images'] as List?)
                                        ?.first ??
                                    '',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Container(color: Colors.grey[300]),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productSnapshot['title'] ?? 'Product',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Qty: ${item.quantity}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'TZS ${(item.priceAtTime * item.quantity).toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                if (order.items.length > 2)
                  Text(
                    '+${order.items.length - 2} more items',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: kPrimaryColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'TZS ${order.totalAmount.toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.payment, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _getPaymentMethodLabel(order.paymentMethod),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.local_shipping,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getDeliveryMethodLabel(order.deliveryMethod),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ProductOrderStatus status) {
    switch (status) {
      case ProductOrderStatus.pendingPayment:
        return Colors.orange;
      case ProductOrderStatus.paid:
        return Colors.blue;
      case ProductOrderStatus.processing:
        return Colors.purple;
      case ProductOrderStatus.shipped:
        return Colors.indigo;
      case ProductOrderStatus.delivered:
        return Colors.green;
      case ProductOrderStatus.cancelled:
        return Colors.red;
      case ProductOrderStatus.refunded:
        return Colors.grey;
    }
  }

  String _getStatusLabel(ProductOrderStatus status) {
    switch (status) {
      case ProductOrderStatus.pendingPayment:
        return 'Pending Payment';
      case ProductOrderStatus.paid:
        return 'Paid';
      case ProductOrderStatus.processing:
        return 'Processing';
      case ProductOrderStatus.shipped:
        return 'Shipped';
      case ProductOrderStatus.delivered:
        return 'Delivered';
      case ProductOrderStatus.cancelled:
        return 'Cancelled';
      case ProductOrderStatus.refunded:
        return 'Refunded';
    }
  }

  String _getPaymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.zenopay:
        return 'ZenoPay';
      case PaymentMethod.cash:
        return 'Cash on Delivery';
      case PaymentMethod.campusDelivery:
        return 'Campus Delivery';
    }
  }

  String _getDeliveryMethodLabel(DeliveryMethod method) {
    switch (method) {
      case DeliveryMethod.pickup:
        return 'Pickup';
      case DeliveryMethod.campusDelivery:
        return 'Campus Delivery';
      case DeliveryMethod.meetup:
        return 'Meetup';
    }
  }
}
