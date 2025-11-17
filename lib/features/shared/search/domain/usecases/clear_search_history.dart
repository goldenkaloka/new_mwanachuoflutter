import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/search/domain/repositories/search_repository.dart';

/// Use case for clearing search history
class ClearSearchHistory implements UseCase<void, NoParams> {
  final SearchRepository repository;

  ClearSearchHistory(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.clearSearchHistory();
  }
}

