import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/network/network_info.dart';
import 'package:mwanachuo/features/shared/categories/data/datasources/category_remote_data_source.dart';
import 'package:mwanachuo/features/shared/categories/domain/entities/category_entity.dart';
import 'package:mwanachuo/features/shared/categories/domain/repositories/category_repository.dart';

/// Implementation of CategoryRepository
class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  CategoryRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<ProductCategoryEntity>>> getProductCategories() async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final categories = await remoteDataSource.getProductCategories();
      return Right(categories);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get product categories: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ProductConditionEntity>>> getProductConditions() async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final conditions = await remoteDataSource.getProductConditions();
      return Right(conditions);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get product conditions: $e'));
    }
  }
}

