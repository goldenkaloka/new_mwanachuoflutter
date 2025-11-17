import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/promotions/domain/entities/promotion_entity.dart';
import 'package:mwanachuo/features/promotions/domain/repositories/promotion_repository.dart';

class GetActivePromotions implements UseCase<List<PromotionEntity>, NoParams> {
  final PromotionRepository repository;

  GetActivePromotions(this.repository);

  @override
  Future<Either<Failure, List<PromotionEntity>>> call(NoParams params) async {
    return await repository.getActivePromotions();
  }
}

