import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/auth/domain/repositories/auth_repository.dart';

class CheckRegistrationCompletion implements UseCase<bool, NoParams> {
  final AuthRepository repository;

  CheckRegistrationCompletion(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await repository.checkRegistrationCompletion();
  }
}


