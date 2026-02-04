import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/features/promotions/domain/entities/promotion_entity.dart';
import 'package:mwanachuo/features/promotions/presentation/bloc/promotion_cubit.dart';
import 'package:mwanachuo/features/promotions/presentation/bloc/promotion_state.dart';
import 'package:mwanachuo/features/promotions/presentation/widgets/promotion_card.dart';

class SingleRandomPromotion extends StatefulWidget {
  const SingleRandomPromotion({super.key});

  @override
  State<SingleRandomPromotion> createState() => _SingleRandomPromotionState();
}

class _SingleRandomPromotionState extends State<SingleRandomPromotion> {
  PromotionEntity? _randomPromotion;
  int _randomIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PromotionCubit, PromotionState>(
      builder: (context, state) {
        if (state is PromotionInitial) {
          context.read<PromotionCubit>().loadActivePromotions();
          return _buildLoading();
        }

        if (state is PromotionsLoading) {
          return _buildLoading();
        }

        if (state is PromotionsLoaded) {
          if (state.promotions.isEmpty) {
            return const SizedBox.shrink();
          }

          if (_randomPromotion == null) {
            final random = Random();
            _randomIndex = random.nextInt(state.promotions.length);
            _randomPromotion = state.promotions[_randomIndex];
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: PromotionCard(
              promotion: _randomPromotion!,
              index: _randomIndex,
              isActive: true,
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoading() {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
