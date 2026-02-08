import 'package:dartz/dartz.dart' hide Order;
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/orders/data/datasources/orders_remote_data_source.dart';
import 'package:mwanachuo/features/orders/data/models/order_model.dart';
import 'package:mwanachuo/features/orders/domain/entities/order.dart';
import 'package:mwanachuo/features/orders/domain/entities/campus_spot.dart';
import 'package:mwanachuo/features/orders/domain/repositories/orders_repository.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersRemoteDataSource remoteDataSource;

  OrdersRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Order>>> getOrders() async {
    try {
      final result = await remoteDataSource.getOrders();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Order>> getOrder(String orderId) async {
    try {
      final result = await remoteDataSource.getOrder(orderId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Order>>> getVendorOrders() async {
    try {
      final result = await remoteDataSource.getVendorOrders();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Order>>> getRunnerOrders() async {
    try {
      final result = await remoteDataSource.getRunnerOrders();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Order>>> getAvailableRunnerJobs() async {
    try {
      final result = await remoteDataSource.getAvailableRunnerJobs();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Order>> createOrder(Order order) async {
    try {
      final orderModel = OrderModel(
        id: order.id,
        userId: order.userId,
        vendorId: order.vendorId,
        runnerId: order.runnerId,
        items: order.items,
        status: order.status,
        totalAmount: order.totalAmount,
        paymentStatus: order.paymentStatus,
        deliverySpotId: order.deliverySpotId,
        meetingNotes: order.meetingNotes,
        createdAt: order.createdAt,
        updatedAt: order.updatedAt,
      );
      final result = await remoteDataSource.createOrder(orderModel);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async {
    try {
      await remoteDataSource.updateOrderStatus(orderId, status.value);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> claimOrder(String orderId) async {
    try {
      await remoteDataSource.claimOrder(orderId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CampusSpot>>> getCampusSpots(
    String? universityId,
  ) async {
    try {
      final result = await remoteDataSource.getCampusSpots(universityId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
