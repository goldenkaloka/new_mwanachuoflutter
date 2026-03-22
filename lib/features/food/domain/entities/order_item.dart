import 'package:equatable/equatable.dart';

class OrderItem extends Equatable {
  final String id;
  final String orderId;
  final String foodItemId;
  final String foodName;
  final int quantity;
  final double unitPrice;
  final List<dynamic> selectedAdditives;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.foodItemId,
    required this.foodName,
    required this.quantity,
    required this.unitPrice,
    required this.selectedAdditives,
  });

  @override
  List<Object?> get props => [id, orderId, foodItemId, foodName, quantity, unitPrice, selectedAdditives];
}
