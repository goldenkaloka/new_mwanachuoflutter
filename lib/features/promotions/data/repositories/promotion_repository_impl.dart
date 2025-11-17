import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/constants/database_constants.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/network/network_info.dart';
import 'package:mwanachuo/features/promotions/data/datasources/promotion_remote_data_source.dart';
import 'package:mwanachuo/features/promotions/domain/entities/promotion_entity.dart';
import 'package:mwanachuo/features/promotions/domain/repositories/promotion_repository.dart';
import 'package:mwanachuo/features/shared/media/domain/usecases/upload_image.dart';

class PromotionRepositoryImpl implements PromotionRepository {
  final PromotionRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final UploadImage uploadImage;

  PromotionRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.uploadImage,
  });

  @override
  Future<Either<Failure, List<PromotionEntity>>> getActivePromotions() async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final promotions = await remoteDataSource.getActivePromotions();
      return Right(promotions);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get active promotions: $e'));
    }
  }

  @override
  Future<Either<Failure, PromotionEntity>> getPromotionById(
    String promotionId,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final promotion = await remoteDataSource.getPromotionById(promotionId);
      return Right(promotion);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get promotion: $e'));
    }
  }

  @override
  Future<Either<Failure, PromotionEntity>> createPromotion({
    required String title,
    required String subtitle,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    File? image,
    String? targetUrl,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      String? imageUrl;

      if (image != null) {
        final uploadResult = await uploadImage(
          UploadImageParams(
            imageFile: image,
            bucket: DatabaseConstants.promotionImagesBucket,
            folder: 'promotions',
          ),
        );

        imageUrl = uploadResult.fold(
          (failure) => null,
          (media) => media.url,
        );
      }

      final promotion = await remoteDataSource.createPromotion(
        title: title,
        subtitle: subtitle,
        description: description,
        startDate: startDate,
        endDate: endDate,
        imageUrl: imageUrl,
        targetUrl: targetUrl,
      );

      return Right(promotion);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to create promotion: $e'));
    }
  }
}

