import 'package:mwanachuo/features/products/domain/entities/product_offer.dart';

/// Product Offer Model
class ProductOfferModel extends ProductOffer {
  const ProductOfferModel({
    required super.id,
    required super.productId,
    required super.buyerId,
    required super.sellerId,
    required super.conversationId,
    required super.offerAmount,
    required super.originalPrice,
    super.message,
    required super.status,
    required super.expiresAt,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ProductOfferModel.fromJson(Map<String, dynamic> json) {
    return ProductOfferModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_id'] as String,
      conversationId: json['conversation_id'] as String,
      offerAmount: (json['offer_amount'] as num).toDouble(),
      originalPrice: (json['original_price'] as num).toDouble(),
      message: json['message'] as String?,
      status: OfferStatus.fromString(json['status'] as String? ?? 'pending'),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'conversation_id': conversationId,
      'offer_amount': offerAmount,
      'original_price': originalPrice,
      'message': message,
      'status': status.value,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Offer History Item Model
class OfferHistoryItemModel extends OfferHistoryItem {
  const OfferHistoryItemModel({
    required super.id,
    required super.offerId,
    required super.userId,
    required super.amount,
    super.message,
    required super.action,
    required super.createdAt,
  });

  factory OfferHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return OfferHistoryItemModel(
      id: json['id'] as String,
      offerId: json['offer_id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      message: json['message'] as String?,
      action: OfferAction.fromString(json['action'] as String? ?? 'offer'),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'offer_id': offerId,
      'user_id': userId,
      'amount': amount,
      'message': message,
      'action': action.value,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
