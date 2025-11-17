import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/profile/domain/entities/user_profile_entity.dart';
import 'package:mwanachuo/features/profile/domain/repositories/profile_repository.dart';

class GetMyProfile implements UseCase<UserProfileEntity, NoParams> {
  final ProfileRepository repository;

  GetMyProfile(this.repository);

  @override
  Future<Either<Failure, UserProfileEntity>> call(NoParams params) async {
    return await repository.getMyProfile();
  }
}

