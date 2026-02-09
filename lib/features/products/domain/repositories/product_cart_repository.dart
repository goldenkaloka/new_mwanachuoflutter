import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/products/domain/entities/product_order.dart';
import 'package:mwanachuo/features/products/domain/entities/product_offer.dart';

/// Abstract repository for product cart and orders
abstract class ProductCartRepository {
  // ==================== ORDER OPERATIONS ====================

  /// Create a new product order
  Future<Either<Failure, ProductOrder>> createOrder({
    required String sellerId,
    required List<ProductOrderItem> items,
    required PaymentMethod paymentMethod,
    required DeliveryMethod deliveryMethod,
    String? deliverySpotId,
    String? deliveryAddress,
    String? deliveryPhone,
    String? conversationId,
    String? offerId,
    double? agreedPrice,
  });

  /// Get buyer's orders
  Future<Either<Failure, List<ProductOrder>>> getMyOrders({
    ProductOrderStatus? status,
    int? limit,
    int? offset,
  });

  /// Get seller's orders
  Future<Either<Failure, List<ProductOrder>>> getSellerOrders({
    ProductOrderStatus? status,
    int? limit,
    int? offset,
  });

  /// Get order by ID
  Future<Either<Failure, ProductOrder>> getOrderById(String orderId);

  /// Update order status
  Future<Either<Failure, ProductOrder>> updateOrderStatus({
    required String orderId,
    required ProductOrderStatus status,
    String? trackingNotes,
  });

  /// Cancel order
  Future<Either<Failure, void>> cancelOrder(String orderId);

  /// Request refund
  Future<Either<Failure, void>> requestRefund({
    required String orderId,
    required String reason,
  });

  // ==================== OFFER OPERATIONS ====================

  /// Create a new offer
  Future<Either<Failure, ProductOffer>> createOffer({
    required String productId,
    required String sellerId,
    required String conversationId,
    required double offerAmount,
    required double originalPrice,
    String? message,
  });

  /// Accept an offer
  Future<Either<Failure, ProductOffer>> acceptOffer(String offerId);

  /// Decline an offer
  Future<Either<Failure, ProductOffer>> declineOffer(String offerId);

  /// Counter an offer
  Future<Either<Failure, ProductOffer>> counterOffer({
    required String offerId,
    required double counterAmount,
    String? message,
  });

  /// Get offer by ID
  Future<Either<Failure, ProductOffer>> getOfferById(String offerId);

  /// Get offers for a product
  Future<Either<Failure, List<ProductOffer>>> getProductOffers({
    required String productId,
    OfferStatus? status,
  });

  /// Get offer history
  Future<Either<Failure, List<OfferHistoryItem>>> getOfferHistory(
    String offerId,
  );
}
