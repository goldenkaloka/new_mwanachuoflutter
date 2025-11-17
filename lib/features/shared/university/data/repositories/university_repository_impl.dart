import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/network/network_info.dart';
import 'package:mwanachuo/features/shared/university/data/datasources/university_local_data_source.dart';
import 'package:mwanachuo/features/shared/university/data/datasources/university_remote_data_source.dart';
import 'package:mwanachuo/features/shared/university/domain/entities/university_entity.dart';
import 'package:mwanachuo/features/shared/university/domain/repositories/university_repository.dart';

/// Implementation of UniversityRepository
class UniversityRepositoryImpl implements UniversityRepository {
  final UniversityRemoteDataSource remoteDataSource;
  final UniversityLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  UniversityRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<UniversityEntity>>> getUniversities() async {
    if (await networkInfo.isConnected) {
      try {
        final universities = await remoteDataSource.getUniversities();
        // Cache universities
        await localDataSource.cacheUniversities(universities);
        return Right(universities);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      // Return cached universities if offline
      try {
        final cachedUniversities =
            await localDataSource.getCachedUniversities();
        return Right(cachedUniversities);
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }
    }
  }

  @override
  Future<Either<Failure, UniversityEntity>> getUniversityById(
    String id,
  ) async {
    // Try cache first
    try {
      final cachedUniversity =
          await localDataSource.getCachedUniversityById(id);
      if (cachedUniversity != null) {
        return Right(cachedUniversity);
      }
    } catch (_) {}

    // If not in cache and online, fetch from remote
    if (await networkInfo.isConnected) {
      try {
        final university = await remoteDataSource.getUniversityById(id);
        return Right(university);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, UniversityEntity?>> getSelectedUniversity() async {
    try {
      final universityId = await localDataSource.getSelectedUniversityId();
      if (universityId == null) {
        return const Right(null);
      }

      // Get university details
      final result = await getUniversityById(universityId);
      return result.fold(
        (failure) => Left(failure),
        (university) => Right(university),
      );
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> setSelectedUniversity(
    String universityId,
  ) async {
    try {
      await localDataSource.saveSelectedUniversityId(universityId);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> clearSelectedUniversity() async {
    try {
      await localDataSource.clearSelectedUniversityId();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<UniversityEntity>>> searchUniversities(
    String query,
  ) async {
    if (query.isEmpty) {
      return getUniversities();
    }

    if (await networkInfo.isConnected) {
      try {
        final universities = await remoteDataSource.searchUniversities(query);
        return Right(universities);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      // Search in cache if offline
      try {
        final cachedUniversities =
            await localDataSource.getCachedUniversities();
        final filteredUniversities = cachedUniversities.where((u) {
          final lowerQuery = query.toLowerCase();
          return u.name.toLowerCase().contains(lowerQuery) ||
              u.shortName.toLowerCase().contains(lowerQuery) ||
              u.location.toLowerCase().contains(lowerQuery);
        }).toList();
        return Right(filteredUniversities);
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }
    }
  }
}


