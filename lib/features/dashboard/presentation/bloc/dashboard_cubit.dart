import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/dashboard/domain/usecases/get_dashboard_stats.dart';
import 'package:mwanachuo/features/dashboard/presentation/bloc/dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final GetDashboardStats getDashboardStats;

  DashboardCubit({required this.getDashboardStats}) : super(DashboardInitial());

  Future<void> loadStats() async {
    if (isClosed) return;
    emit(DashboardLoading());

    final result = await getDashboardStats(NoParams());

    if (isClosed) return;
    result.fold(
      (failure) => emit(DashboardError(message: failure.message)),
      (stats) => emit(DashboardLoaded(stats: stats)),
    );
  }
}

