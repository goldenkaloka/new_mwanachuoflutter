import 'package:equatable/equatable.dart';
import 'package:mwanachuo/features/products/domain/entities/product_entity.dart';

/// Base class for all product states
abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ProductInitial extends ProductState {}

/// Loading products
class ProductsLoading extends ProductState {}

/// Products loaded successfully
class ProductsLoaded extends ProductState {
  final List<ProductEntity> products;
  final bool hasMore;
  final bool isLoadingMore;

  const ProductsLoaded({
    required this.products,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  ProductsLoaded copyWith({
    List<ProductEntity>? products,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return ProductsLoaded(
      products: products ?? this.products,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [products, hasMore, isLoadingMore];
}

/// Loading single product
class ProductLoading extends ProductState {}

/// Single product loaded
class ProductLoaded extends ProductState {
  final ProductEntity product;

  const ProductLoaded({required this.product});

  @override
  List<Object?> get props => [product];
}

/// Creating product
class ProductCreating extends ProductState {}

/// Product created successfully
class ProductCreated extends ProductState {
  final ProductEntity product;

  const ProductCreated({required this.product});

  @override
  List<Object?> get props => [product];
}

/// Updating product
class ProductUpdating extends ProductState {}

/// Product updated successfully
class ProductUpdated extends ProductState {
  final ProductEntity product;

  const ProductUpdated({required this.product});

  @override
  List<Object?> get props => [product];
}

/// Deleting product
class ProductDeleting extends ProductState {}

/// Product deleted successfully
class ProductDeleted extends ProductState {}

/// Loading more products (pagination)
class ProductsLoadingMore extends ProductState {
  final List<ProductEntity> currentProducts;

  const ProductsLoadingMore({required this.currentProducts});

  @override
  List<Object?> get props => [currentProducts];
}

/// Error state
class ProductError extends ProductState {
  final String message;

  const ProductError({required this.message});

  @override
  List<Object?> get props => [message];
}

