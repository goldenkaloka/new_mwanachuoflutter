import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/university/domain/repositories/university_repository.dart';

/// Use case for setting the selected university
class SetSelectedUniversity implements UseCase<void, SetUniversityParams> {
  final UniversityRepository repository;

  SetSelectedUniversity(this.repository);

  @override
  Future<Either<Failure, void>> call(SetUniversityParams params) async {
    return await repository.setSelectedUniversity(params.universityId);
  }
}

class SetUniversityParams extends Equatable {
  final String universityId;

  const SetUniversityParams({required this.universityId});

  @override
  List<Object?> get props => [universityId];
}


