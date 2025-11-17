import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/core/widgets/app_card.dart';
import 'package:mwanachuo/core/widgets/empty_state.dart';
import 'package:mwanachuo/core/widgets/shimmer_loading.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_bloc.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_event.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_state.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ServiceBloc>()..add(const LoadServicesEvent(limit: 50)),
      child: const _ServicesView(),
    );
  }
}

class _ServicesView extends StatefulWidget {
  const _ServicesView();

  @override
  State<_ServicesView> createState() => _ServicesViewState();
}

class _ServicesViewState extends State<_ServicesView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      final state = context.read<ServiceBloc>().state;
      if (state is ServicesLoaded && 
          state.hasMore && 
          !state.isLoadingMore) {
        context.read<ServiceBloc>().add(
          LoadMoreServicesEvent(offset: state.services.length),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Services',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: BlocBuilder<ServiceBloc, ServiceState>(
        builder: (context, state) {
          // Loading state - show shimmer skeleton
          if (state is ServicesLoading) {
            return Padding(
              padding: EdgeInsets.all(
                ResponsiveBreakpoints.responsiveHorizontalPadding(context),
              ),
              child: ListView.separated(
                itemCount: 6,
                separatorBuilder: (context, index) => const SizedBox(height: kSpacingMd),
                itemBuilder: (context, index) => const ShimmerLoading(
                  height: 110,
                  width: double.infinity,
                ),
              ),
            );
          }

          // Error state
          if (state is ServiceError) {
            return ErrorState(
              title: 'Failed to Load Services',
              message: state.message,
              onRetry: () {
                context.read<ServiceBloc>().add(const LoadServicesEvent(limit: 20));
              },
            );
          }

          // Success state
          if (state is ServicesLoaded) {
            // Empty state
            if (state.services.isEmpty && !state.isLoadingMore) {
              return EmptyState(
                type: EmptyStateType.noServices,
                onAction: () => Navigator.pop(context),
                actionLabel: 'Go Back',
              );
            }

            // Services list with pagination
            return ListView.separated(
              controller: _scrollController,
              padding: EdgeInsets.all(
                ResponsiveBreakpoints.responsiveHorizontalPadding(context),
              ),
              itemCount: state.services.length + (state.isLoadingMore ? 1 : 0),
              separatorBuilder: (context, index) => const SizedBox(height: kSpacingMd),
              itemBuilder: (context, index) {
                // Show loading indicator at the bottom
                if (index == state.services.length && state.isLoadingMore) {
                  return const Padding(
                    padding: EdgeInsets.all(kSpacingLg),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            color: kPrimaryColor,
                            strokeWidth: 2,
                          ),
                          SizedBox(height: kSpacingSm),
                          Text(
                            'Loading more...',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (index >= state.services.length) return const SizedBox.shrink();

                // Use new ServiceCard component
                final service = state.services[index];
                return ServiceCard(
                  imageUrl: service.images.isNotEmpty ? service.images.first : '',
                  title: service.title,
                  price: 'Ksh ${service.price.toStringAsFixed(2)}',
                  priceType: service.priceType,
                  category: service.category,
                  providerName: service.providerName,
                  location: service.location,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/service-details',
                    arguments: service.id,
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
