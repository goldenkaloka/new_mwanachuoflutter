import 'package:equatable/equatable.dart';

/// Enum for product order status
enum ProductOrderStatus {
  pendingPayment('pending_payment'),
  paid('paid'),
  processing('processing'),
  shipped('shipped'),
  delivered('delivered'),
  cancelled('cancelled'),
  refunded('refunded');

  final String value;
  const ProductOrderStatus(this.value);

  static ProductOrderStatus fromString(String value) {
    return ProductOrderStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ProductOrderStatus.pendingPayment,
    );
  }
}

/// Enum for payment method
enum PaymentMethod {
  zenopay('zenopay'),
  cash('cash'),
  campusDelivery('campus_delivery');

  final String value;
  const PaymentMethod(this.value);

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentMethod.cash,
    );
  }
}

/// Enum for delivery method
enum DeliveryMethod {
  pickup('pickup'),
  campusDelivery('campus_delivery'),
  meetup('meetup');

  final String value;
  const DeliveryMethod(this.value);

  static DeliveryMethod fromString(String value) {
    return DeliveryMethod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DeliveryMethod.pickup,
    );
  }
}

/// Product Order Entity
class ProductOrder extends Equatable {
  final String id;
  final String buyerId;
  final String sellerId;
  final double totalAmount;
  final double? originalPrice;
  final double? agreedPrice;
  final PaymentMethod paymentMethod;
  final String paymentStatus;
  final DeliveryMethod deliveryMethod;
  final String? deliverySpotId;
  final String? deliveryAddress;
  final String? deliveryPhone;
  final ProductOrderStatus status;
  final String? trackingNotes;
  final String? conversationId;
  final String? offerId;
  final List<ProductOrderItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductOrder({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.totalAmount,
    this.originalPrice,
    this.agreedPrice,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.deliveryMethod,
    this.deliverySpotId,
    this.deliveryAddress,
    this.deliveryPhone,
    required this.status,
    this.trackingNotes,
    this.conversationId,
    this.offerId,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Alias for status to match UI usage
  ProductOrderStatus get orderStatus => status;

  /// Check if this order was from a negotiated offer
  bool get isNegotiated => agreedPrice != null && agreedPrice != originalPrice;

  /// Get the final price (negotiated or original)
  double get finalPrice => agreedPrice ?? originalPrice ?? totalAmount;

  @override
  List<Object?> get props => [
    id,
    buyerId,
    sellerId,
    totalAmount,
    originalPrice,
    agreedPrice,
    paymentMethod,
    paymentStatus,
    deliveryMethod,
    deliverySpotId,
    deliveryAddress,
    deliveryPhone,
    status,
    trackingNotes,
    conversationId,
    offerId,
    items,
    createdAt,
    updatedAt,
  ];
}

/// Product Order Item Entity
class ProductOrderItem extends Equatable {
  final String id;
  final String orderId;
  final String productId;
  final Map<String, dynamic> productSnapshot;
  final int quantity;
  final double priceAtTime;
  final DateTime createdAt;

  const ProductOrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productSnapshot,
    required this.quantity,
    required this.priceAtTime,
    required this.createdAt,
  });

  /// Get product title from snapshot
  String get productTitle =>
      productSnapshot['title'] as String? ?? 'Unknown Product';

  /// Get product images from snapshot
  List<String> get productImages {
    final images = productSnapshot['images'];
    if (images is List) {
      return images.cast<String>();
    }
    return [];
  }

  /// Get seller name from snapshot
  String get sellerName =>
      productSnapshot['seller_name'] as String? ?? 'Unknown Seller';

  /// Calculate subtotal
  double get subtotal => priceAtTime * quantity;

  @override
  List<Object?> get props => [
    id,
    orderId,
    productId,
    productSnapshot,
    quantity,
    priceAtTime,
    createdAt,
  ];
}
