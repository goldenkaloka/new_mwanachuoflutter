import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/auth/domain/repositories/auth_repository.dart';

class CompleteRegistration implements UseCase<void, CompleteRegistrationParams> {
  final AuthRepository repository;

  CompleteRegistration(this.repository);

  @override
  Future<Either<Failure, void>> call(CompleteRegistrationParams params) async {
    return await repository.completeRegistration(
      userId: params.userId,
      primaryUniversityId: params.primaryUniversityId,
      subsidiaryUniversityIds: params.subsidiaryUniversityIds,
    );
  }
}

class CompleteRegistrationParams {
  final String userId;
  final String primaryUniversityId;
  final List<String> subsidiaryUniversityIds;

  CompleteRegistrationParams({
    required this.userId,
    required this.primaryUniversityId,
    required this.subsidiaryUniversityIds,
  });
}


