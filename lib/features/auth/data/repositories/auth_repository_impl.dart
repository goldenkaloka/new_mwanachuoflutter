import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/network/network_info.dart';
import 'package:mwanachuo/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:mwanachuo/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mwanachuo/features/auth/domain/entities/seller_request_entity.dart';
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

      // If we have a cached user, we can return it as a "preliminary" result
      // But we should also verify/refresh with remote if possible.
      // For the sake of this repository's simple interface (non-stream),
      // we'll return cache immediately if available to speed up startup.
      if (cachedUser != null) {
        // We return cache but fire-and-forget a remote sync to update local cache
        // Note: This won't update the UI until the user pulls-to-refresh or navigates,
        // unless we use a Stream. For startup, this is a huge win.
        remoteDataSource
            .getCurrentUser()
            .then((user) async {
              if (user != null) {
                await localDataSource.cacheUser(user);
              }
            })
            .catchError((_) {
              // Ignore background errors
            });
        return Right(cachedUser);
      }

      // 2. No cache, or we want a fresh remote fetch forced (handled by caller if needed)
      final user = await remoteDataSource.getCurrentUser();
      if (user != null) {
        await localDataSource.cacheUser(user);
      }
      return Right(user);
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
  Future<Either<Failure, void>> requestSellerAccess({
    required String userId,
    required String reason,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.requestSellerAccess(
        userId: userId,
        reason: reason,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> approveSellerRequest({
    required String requestId,
    required String adminId,
    String? notes,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.approveSellerRequest(
        requestId: requestId,
        adminId: adminId,
        notes: notes,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectSellerRequest({
    required String requestId,
    required String adminId,
    String? notes,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.rejectSellerRequest(
        requestId: requestId,
        adminId: adminId,
        notes: notes,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
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
  Future<Either<Failure, String?>> getSellerRequestStatus() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final status = await remoteDataSource.getSellerRequestStatus();
      return Right(status);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SellerRequestEntity>>> getSellerRequests({
    String? status,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final requests = await remoteDataSource.getSellerRequests(status: status);
      return Right(requests);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SellerRequestEntity>> getSellerRequestById(
    String requestId,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final request = await remoteDataSource.getSellerRequestById(requestId);
      return Right(request);
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
}
