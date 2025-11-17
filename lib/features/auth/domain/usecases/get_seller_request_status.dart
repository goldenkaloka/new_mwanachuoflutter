import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/auth/domain/repositories/auth_repository.dart';

class GetSellerRequestStatus implements UseCase<String?, NoParams> {
  final AuthRepository repository;

  GetSellerRequestStatus(this.repository);

  @override
  Future<Either<Failure, String?>> call(NoParams params) async {
    return await repository.getSellerRequestStatus();
  }
}


