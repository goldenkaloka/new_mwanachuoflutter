import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/network/network_info.dart';
import 'package:mwanachuo/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:mwanachuo/features/auth/data/datasources/auth_remote_data_source.dart';

import 'package:mwanachuo/features/auth/domain/entities/user_entity.dart';
import 'package:mwanachuo/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, UserEntity>> signIn({
    required String email,
    required String password,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final user = await remoteDataSource.signIn(
        email: email,
        password: password,
      );
      await localDataSource.cacheUser(user);
      return Right(user);
    } on AuthenticationException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    String? businessName,
    String? tinNumber,
    String? businessCategory,
    String? programName,
    String? userType,
    String? universityId,
    String? enrolledCourseId,
    int? yearOfStudy,
    int? currentSemester,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final user = await remoteDataSource.signUp(
        email: email,
        password: password,
        name: name,
        phone: phone,
        businessName: businessName,
        tinNumber: tinNumber,
        businessCategory: businessCategory,
        programName: programName,
        userType: userType,
        universityId: universityId,
        enrolledCourseId: enrolledCourseId,
        yearOfStudy: yearOfStudy,
        currentSemester: currentSemester,
      );
      await localDataSource.cacheUser(user);
      return Right(user);
    } on AuthenticationException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      await localDataSource.clearCache();
      return const Right(null);
    } on AuthenticationException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      // 1. Try to get from cache first for immediate UI update
      final cachedUser = await localDataSource.getCachedUser();

      // If we have a cached user and we're offline, return immediately
      if (cachedUser != null && !await networkInfo.isConnected) {
        return Right(cachedUser);
      }

      if (await networkInfo.isConnected) {
        try {
          final user = await remoteDataSource.getCurrentUser();
          if (user != null) {
            await localDataSource.cacheUser(user);
            return Right(user);
          } else {
            // User validation failed on server (e.g. deleted account)
            await localDataSource.clearCache();
            return Left(ServerFailure('User no longer exists'));
          }
        } catch (e) {
          // If server check failed but we have cache, fallback to cache
          // UNLESS the error indicates the user is gone (e.g. "JSON/Single" error from empty row)
          // But determining that is hard. For standard network errors, use cache.
          if (cachedUser != null) {
            return Right(cachedUser);
          }
          return Left(ServerFailure(e.toString()));
        }
      } else {
        // Offline
        if (cachedUser != null) {
          return Right(cachedUser);
        }
        return const Left(NetworkFailure('No internet connection'));
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    try {
      final isLoggedIn = await localDataSource.isLoggedIn();
      return Right(isLoggedIn);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? profilePicture,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final user = await remoteDataSource.updateProfile(
        userId: userId,
        name: name,
        phone: phone,
        profilePicture: profilePicture,
      );
      await localDataSource.cacheUser(user);
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> completeRegistration({
    required String userId,
    required String primaryUniversityId,
    required List<String> subsidiaryUniversityIds,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.completeRegistration(
        userId: userId,
        primaryUniversityId: primaryUniversityId,
        subsidiaryUniversityIds: subsidiaryUniversityIds,
      );
      await localDataSource.setRegistrationCompleted(true);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkRegistrationCompletion() async {
    try {
      // Check local cache first for fast startup
      final isCachedCompleted = await localDataSource.isRegistrationCompleted();
      if (isCachedCompleted) {
        return const Right(true);
      }

      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure('No internet connection'));
      }

      final isCompleted = await remoteDataSource.checkRegistrationCompletion();

      // Cache the result
      if (isCompleted) {
        await localDataSource.setRegistrationCompleted(true);
      }

      return Right(isCompleted);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, UserEntity?>> watchAuthState() {
    return remoteDataSource
        .watchAuthState()
        .map<Either<Failure, UserEntity?>>((user) => Right(user))
        .handleError((error) {
          return Left<Failure, UserEntity?>(ServerFailure(error.toString()));
        });
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.resetPassword(email);
      return const Right(null);
    } on AuthenticationException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> consumeFreeListing(String userId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.consumeFreeListing(userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
