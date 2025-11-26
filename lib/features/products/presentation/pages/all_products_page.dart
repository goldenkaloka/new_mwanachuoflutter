import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/core/widgets/app_card.dart';
import 'package:mwanachuo/core/widgets/empty_state.dart';
import 'package:mwanachuo/core/widgets/shimmer_loading.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_bloc.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_event.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_state.dart';

class AllProductsPage extends StatelessWidget {
  const AllProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<ProductBloc>()..add(const LoadProductsEvent(limit: 50)),
      child: const _AllProductsView(),
    );
  }
}

class _AllProductsView extends StatefulWidget {
  const _AllProductsView();

  @override
  State<_AllProductsView> createState() => _AllProductsViewState();
}

class _AllProductsViewState extends State<_AllProductsView> {
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
      final state = context.read<ProductBloc>().state;
      if (state is ProductsLoaded && state.hasMore && !state.isLoadingMore) {
        context.read<ProductBloc>().add(
          LoadMoreProductsEvent(offset: state.products.length),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveBreakpoints.responsiveGridColumns(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Products',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          // Loading state - show shimmer skeleton
          if (state is ProductsLoading) {
            return ProductGridSkeleton(
              itemCount: 6,
              crossAxisCount: crossAxisCount,
            );
          }

          // Error state - use new ErrorState widget
          if (state is ProductError) {
            return ErrorState(
              title: 'Failed to Load Products',
              message: state.message,
              onRetry: () {
                context.read<ProductBloc>().add(
                  const LoadProductsEvent(limit: 20),
                );
              },
            );
          }

          // Success state
          if (state is ProductsLoaded) {
            // Empty state - use new EmptyState widget
            if (state.products.isEmpty && !state.isLoadingMore) {
              return EmptyState(
                type: EmptyStateType.noProducts,
                onAction: () => Navigator.pop(context),
                actionLabel: 'Go Back',
              );
            }

            // Products grid with pagination
            return GridView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(
                ResponsiveBreakpoints.responsiveHorizontalPadding(context),
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.75,
                crossAxisSpacing: kSpacingLg,
                mainAxisSpacing: kSpacingLg,
              ),
              itemCount: state.products.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                // Show loading indicator at the bottom
                if (index == state.products.length && state.isLoadingMore) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(kSpacingLg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
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

                if (index >= state.products.length)
                  return const SizedBox.shrink();

                // Use new ProductCard component
                final product = state.products[index];
                return ProductCard(
                  imageUrl: product.images.isNotEmpty
                      ? product.images.first
                      : '',
                  title: product.title,
                  price: 'TZS ${product.price.toStringAsFixed(2)}',
                  category: product.category,
                  rating: product.rating,
                  reviewCount: product.reviewCount,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/product-details',
                    arguments: product.id,
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
