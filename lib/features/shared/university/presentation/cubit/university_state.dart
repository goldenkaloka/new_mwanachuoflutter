import 'package:equatable/equatable.dart';
import 'package:mwanachuo/features/shared/university/domain/entities/university_entity.dart';

/// Base class for all university states
abstract class UniversityState extends Equatable {
  const UniversityState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class UniversityInitial extends UniversityState {}

/// Loading state
class UniversityLoading extends UniversityState {}

/// Universities loaded successfully
class UniversitiesLoaded extends UniversityState {
  final List<UniversityEntity> universities;
  final UniversityEntity? selectedUniversity;

  const UniversitiesLoaded({
    required this.universities,
    this.selectedUniversity,
  });

  @override
  List<Object?> get props => [universities, selectedUniversity];
}

/// University selected successfully
class UniversitySelected extends UniversityState {
  final UniversityEntity university;

  const UniversitySelected({required this.university});

  @override
  List<Object?> get props => [university];
}

/// Error state
class UniversityError extends UniversityState {
  final String message;

  const UniversityError({required this.message});

  @override
  List<Object?> get props => [message];
}


