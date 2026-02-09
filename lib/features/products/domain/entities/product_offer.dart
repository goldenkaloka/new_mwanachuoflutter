import 'package:equatable/equatable.dart';

/// Enum for offer status
enum OfferStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  countered('countered'),
  expired('expired');

  final String value;
  const OfferStatus(this.value);

  static OfferStatus fromString(String value) {
    return OfferStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OfferStatus.pending,
    );
  }
}

/// Enum for offer action type
enum OfferAction {
  offer('offer'),
  counter('counter'),
  accept('accept'),
  decline('decline');

  final String value;
  const OfferAction(this.value);

  static OfferAction fromString(String value) {
    return OfferAction.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OfferAction.offer,
    );
  }
}

/// Product Offer Entity
class ProductOffer extends Equatable {
  final String id;
  final String productId;
  final String buyerId;
  final String sellerId;
  final String conversationId;
  final double offerAmount;
  final double originalPrice;
  final String? message;
  final OfferStatus status;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductOffer({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.sellerId,
    required this.conversationId,
    required this.offerAmount,
    required this.originalPrice,
    this.message,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if offer is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if offer is still pending
  bool get isPending => status == OfferStatus.pending && !isExpired;

  /// Check if offer can be acted upon
  bool get isActionable => isPending;

  /// Calculate discount percentage
  double get discountPercentage {
    if (originalPrice == 0) return 0;
    return ((originalPrice - offerAmount) / originalPrice) * 100;
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    buyerId,
    sellerId,
    conversationId,
    offerAmount,
    originalPrice,
    message,
    status,
    expiresAt,
    createdAt,
    updatedAt,
  ];
}

/// Offer History Item Entity
class OfferHistoryItem extends Equatable {
  final String id;
  final String offerId;
  final String userId;
  final double amount;
  final String? message;
  final OfferAction action;
  final DateTime createdAt;

  const OfferHistoryItem({
    required this.id,
    required this.offerId,
    required this.userId,
    required this.amount,
    this.message,
    required this.action,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    offerId,
    userId,
    amount,
    message,
    action,
    createdAt,
  ];
}
