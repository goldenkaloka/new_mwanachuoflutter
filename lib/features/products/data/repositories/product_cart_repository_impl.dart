import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/products/data/datasources/product_cart_remote_data_source.dart';
import 'package:mwanachuo/features/products/domain/entities/product_offer.dart';
import 'package:mwanachuo/features/products/domain/entities/product_order.dart';
import 'package:mwanachuo/features/products/domain/repositories/product_cart_repository.dart';

class ProductCartRepositoryImpl implements ProductCartRepository {
  final ProductCartRemoteDataSource remoteDataSource;

  ProductCartRepositoryImpl({required this.remoteDataSource});

  @override
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
  }) async {
    try {
      final order = await remoteDataSource.createOrder(
        sellerId: sellerId,
        items: items,
        paymentMethod: paymentMethod,
        deliveryMethod: deliveryMethod,
        deliverySpotId: deliverySpotId,
        deliveryAddress: deliveryAddress,
        deliveryPhone: deliveryPhone,
        conversationId: conversationId,
        offerId: offerId,
        agreedPrice: agreedPrice,
      );
      return Right(order);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<ProductOrder>>> getMyOrders({
    ProductOrderStatus? status,
    int? limit,
    int? offset,
  }) async {
    try {
      final orders = await remoteDataSource.getMyOrders(
        status: status,
        limit: limit,
        offset: offset,
      );
      return Right(orders);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<ProductOrder>>> getSellerOrders({
    ProductOrderStatus? status,
    int? limit,
    int? offset,
  }) async {
    try {
      final orders = await remoteDataSource.getSellerOrders(
        status: status,
        limit: limit,
        offset: offset,
      );
      return Right(orders);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, ProductOrder>> getOrderById(String orderId) async {
    try {
      final order = await remoteDataSource.getOrderById(orderId);
      return Right(order);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, ProductOrder>> updateOrderStatus({
    required String orderId,
    required ProductOrderStatus status,
    String? trackingNotes,
  }) async {
    try {
      final order = await remoteDataSource.updateOrderStatus(
        orderId: orderId,
        status: status,
        trackingNotes: trackingNotes,
      );
      return Right(order);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> cancelOrder(String orderId) async {
    try {
      await remoteDataSource.cancelOrder(orderId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> requestRefund({
    required String orderId,
    required String reason,
  }) async {
    try {
      await remoteDataSource.requestRefund(orderId: orderId, reason: reason);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  // ==================== OFFER OPERATIONS ====================

  @override
  Future<Either<Failure, ProductOffer>> createOffer({
    required String productId,
    required String sellerId,
    required String conversationId,
    required double offerAmount,
    required double originalPrice,
    String? message,
  }) async {
    try {
      final offer = await remoteDataSource.createOffer(
        productId: productId,
        sellerId: sellerId,
        conversationId: conversationId,
        offerAmount: offerAmount,
        originalPrice: originalPrice,
        message: message,
      );
      return Right(offer);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, ProductOffer>> acceptOffer(String offerId) async {
    try {
      final offer = await remoteDataSource.acceptOffer(offerId);
      return Right(offer);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, ProductOffer>> declineOffer(String offerId) async {
    try {
      final offer = await remoteDataSource.declineOffer(offerId);
      return Right(offer);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, ProductOffer>> counterOffer({
    required String offerId,
    required double counterAmount,
    String? message,
  }) async {
    try {
      final offer = await remoteDataSource.counterOffer(
        offerId: offerId,
        counterAmount: counterAmount,
        message: message,
      );
      return Right(offer);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, ProductOffer>> getOfferById(String offerId) async {
    try {
      final offer = await remoteDataSource.getOfferById(offerId);
      return Right(offer);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<ProductOffer>>> getProductOffers({
    required String productId,
    OfferStatus? status,
  }) async {
    try {
      final offers = await remoteDataSource.getProductOffers(
        productId: productId,
        status: status,
      );
      return Right(offers);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<OfferHistoryItem>>> getOfferHistory(
    String offerId,
  ) async {
    try {
      final history = await remoteDataSource.getOfferHistory(offerId);
      return Right(history);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
