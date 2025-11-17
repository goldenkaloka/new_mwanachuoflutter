import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/dashboard/domain/entities/dashboard_stats_entity.dart';
import 'package:mwanachuo/features/dashboard/domain/repositories/dashboard_repository.dart';

class GetDashboardStats implements UseCase<DashboardStatsEntity, NoParams> {
  final DashboardRepository repository;

  GetDashboardStats(this.repository);

  @override
  Future<Either<Failure, DashboardStatsEntity>> call(NoParams params) async {
    return await repository.getDashboardStats();
  }
}

