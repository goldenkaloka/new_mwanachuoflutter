import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/config/supabase_config.dart';
import 'package:mwanachuo/features/orders/presentation/bloc/cart_bloc.dart';
import 'package:mwanachuo/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:mwanachuo/features/orders/domain/entities/order.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrdersBloc, OrdersState>(
      listener: (context, state) {
        if (state is OrderPlacedSuccess) {
          context.read<CartBloc>().add(ClearCart());
          _showSuccessDialog(context, state.order);
        } else if (state is OrdersFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'My Cart',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              onPressed: () => context.read<CartBloc>().add(ClearCart()),
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear Cart',
            ),
          ],
        ),
        body: BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            if (state.items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your cart is empty',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Back to Food',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: kPrimaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.fastfood,
                                  color: kPrimaryColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '${item.priceAtTime.toStringAsFixed(0)} TZS',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: kPrimaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        context.read<CartBloc>().add(
                                          UpdateQuantity(
                                            item.productId,
                                            item.quantity - 1,
                                          ),
                                        ),
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                    color: Colors.grey,
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        context.read<CartBloc>().add(
                                          UpdateQuantity(
                                            item.productId,
                                            item.quantity + 1,
                                          ),
                                        ),
                                    icon: const Icon(Icons.add_circle_outline),
                                    color: kPrimaryColor,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Grand Total',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${state.totalPrice.toStringAsFixed(0)} TZS',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      BlocBuilder<OrdersBloc, OrdersState>(
                        builder: (context, ordersState) {
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: ordersState is OrdersLoading
                                  ? null
                                  : () => _onCheckout(context, state),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: ordersState is OrdersLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : Text(
                                      'Place Order',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onCheckout(BuildContext context, CartState cartState) {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to place an order')),
      );
      return;
    }

    final order = Order(
      id: '', // Supabase will generate
      userId: userId,
      vendorId: cartState.vendorId!,
      items: cartState.items,
      status: OrderStatus.pending,
      totalAmount: cartState.totalPrice,
      paymentStatus: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    context.read<OrdersBloc>().add(PlaceOrder(order));
  }

  void _showSuccessDialog(BuildContext context, Order order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Order Placed!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your order has been sent to the kitchen. You can track its status in your orders.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Back to food dashboard
              },
              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
              child: const Text(
                'Great!',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
