import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/core/widgets/app_card.dart';
import 'package:mwanachuo/core/widgets/empty_state.dart';
import 'package:mwanachuo/core/widgets/shimmer_loading.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_bloc.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_event.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_state.dart';

class StudentHousingScreen extends StatelessWidget {
  const StudentHousingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AccommodationBloc>()..add(const LoadAccommodationsEvent(limit: 50)),
      child: const _HousingView(),
    );
  }
}

class _HousingView extends StatelessWidget {
  const _HousingView();

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveBreakpoints.responsiveGridColumns(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Student Housing',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: BlocBuilder<AccommodationBloc, AccommodationState>(
        builder: (context, state) {
          // Loading state - show shimmer skeleton
          if (state is AccommodationsLoading) {
            return ProductGridSkeleton(
              itemCount: 6,
              crossAxisCount: crossAxisCount,
            );
          }

          // Error state
          if (state is AccommodationError) {
            return ErrorState(
              title: 'Failed to Load Accommodations',
              message: state.message,
              onRetry: () {
                context.read<AccommodationBloc>().add(const LoadAccommodationsEvent(limit: 20));
              },
            );
          }

          // Success state
          if (state is AccommodationsLoaded) {
            // Empty state
            if (state.accommodations.isEmpty) {
              return EmptyState(
                type: EmptyStateType.noAccommodations,
                onAction: () => Navigator.pop(context),
                actionLabel: 'Go Back',
              );
            }

            // Accommodations grid
            return GridView.builder(
              padding: EdgeInsets.all(
                ResponsiveBreakpoints.responsiveHorizontalPadding(context),
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.75,
                crossAxisSpacing: kSpacingLg,
                mainAxisSpacing: kSpacingLg,
              ),
              itemCount: state.accommodations.length,
              itemBuilder: (context, index) {
                // Use new AccommodationCard component
                final accommodation = state.accommodations[index];
                return AccommodationCard(
                  imageUrl: accommodation.images.isNotEmpty ? accommodation.images.first : '',
                  title: accommodation.name,
                  price: 'Ksh ${accommodation.price.toStringAsFixed(2)}',
                  priceType: accommodation.priceType,
                  location: accommodation.location,
                  bedrooms: accommodation.bedrooms,
                  bathrooms: accommodation.bathrooms,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/accommodation-details',
                    arguments: accommodation.id,
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}


