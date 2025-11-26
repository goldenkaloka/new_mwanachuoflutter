import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';

/// Base class for use cases
/// 
/// A use case represents a single business logic operation
/// that can be executed with a set of parameters
abstract class UseCase<Result, Params> {
  Future<Either<Failure, Result>> call(Params params);
}

/// Base class for stream-based use cases
abstract class StreamUseCase<Result, Params> {
  Stream<Result> call(Params params);
}

/// Class to be used when a use case doesn't need any parameters
class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}
