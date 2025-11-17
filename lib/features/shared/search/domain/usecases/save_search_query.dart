import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/search/domain/repositories/search_repository.dart';

/// Use case for saving a search query
class SaveSearchQuery implements UseCase<void, SaveSearchQueryParams> {
  final SearchRepository repository;

  SaveSearchQuery(this.repository);

  @override
  Future<Either<Failure, void>> call(SaveSearchQueryParams params) async {
    if (params.query.trim().isEmpty) {
      return const Right(null);
    }

    return await repository.saveSearchQuery(params.query.trim());
  }
}

class SaveSearchQueryParams extends Equatable {
  final String query;

  const SaveSearchQueryParams({required this.query});

  @override
  List<Object?> get props => [query];
}

