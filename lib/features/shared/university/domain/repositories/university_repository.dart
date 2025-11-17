import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/shared/university/domain/entities/university_entity.dart';

/// University repository interface
/// Defines the contract for university data operations
abstract class UniversityRepository {
  /// Get all universities
  Future<Either<Failure, List<UniversityEntity>>> getUniversities();

  /// Get university by ID
  Future<Either<Failure, UniversityEntity>> getUniversityById(String id);

  /// Get the currently selected university
  Future<Either<Failure, UniversityEntity?>> getSelectedUniversity();

  /// Set the selected university
  Future<Either<Failure, void>> setSelectedUniversity(String universityId);

  /// Clear the selected university
  Future<Either<Failure, void>> clearSelectedUniversity();

  /// Search universities by name
  Future<Either<Failure, List<UniversityEntity>>> searchUniversities(
    String query,
  );
}


