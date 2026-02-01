import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/models/filter_model.dart';
import 'package:mwanachuo/features/products/domain/usecases/create_product.dart';
import 'package:mwanachuo/features/products/domain/usecases/delete_product.dart';
import 'package:mwanachuo/features/products/domain/usecases/get_my_products.dart';
import 'package:mwanachuo/features/products/domain/usecases/get_product_by_id.dart';
import 'package:mwanachuo/features/products/domain/usecases/get_products.dart';
import 'package:mwanachuo/features/products/domain/usecases/increment_view_count.dart';
import 'package:mwanachuo/features/products/domain/usecases/update_product.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_event.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_state.dart';
import 'package:mwanachuo/features/products/domain/entities/product_entity.dart';

/// BLoC for managing product state
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProducts getProducts;
  final GetProductById getProductById;
  final GetMyProducts getMyProducts;
  final CreateProduct createProduct;
  final UpdateProduct updateProduct;
  final DeleteProduct deleteProduct;
  final IncrementViewCount incrementViewCount;

  ProductBloc({
    required this.getProducts,
    required this.getProductById,
    required this.getMyProducts,
    required this.createProduct,
    required this.updateProduct,
    required this.deleteProduct,
    required this.incrementViewCount,
  }) : super(ProductInitial()) {
    on<LoadProductsEvent>(_onLoadProducts);
    on<LoadProductByIdEvent>(_onLoadProductById);
    on<LoadMyProductsEvent>(_onLoadMyProducts);
    on<CreateProductEvent>(_onCreateProduct);
    on<UpdateProductEvent>(_onUpdateProduct);
    on<DeleteProductEvent>(_onDeleteProduct);
    on<IncrementViewCountEvent>(_onIncrementViewCount);
    on<LoadMoreProductsEvent>(_onLoadMoreProducts);
    on<ApplyProductFilterEvent>(_onApplyFilter);
    on<ClearProductFilterEvent>(_onClearFilter);
  }

  ProductFilter? _currentFilter;

  Future<void> _onApplyFilter(
    ApplyProductFilterEvent event,
    Emitter<ProductState> emit,
  ) async {
    _currentFilter = event.filter;
    debugPrint(
      '🔍 Applying filter: searchQuery="${event.filter.searchQuery}", category="${event.filter.category}", condition="${event.filter.condition}"',
    );
    // Reload products with new filter
    add(LoadProductsEvent(limit: 50, filter: _currentFilter));
  }

  Future<void> _onClearFilter(
    ClearProductFilterEvent event,
    Emitter<ProductState> emit,
  ) async {
    _currentFilter = null;
    // Reload products without filter
    add(const LoadProductsEvent(limit: 50));
  }

  Future<void> _onLoadProducts(
    LoadProductsEvent event,
    Emitter<ProductState> emit,
  ) async {
    // Prevent reloading if already loading
    if (state is ProductsLoading) {
      debugPrint('⏭️  Products already loading, skipping...');
      return;
    }

    final filterToUse = event.filter ?? _currentFilter;
    debugPrint(
      '📦 Loading products with filter: searchQuery="${filterToUse?.searchQuery}", category="${filterToUse?.category}"',
    );
    emit(ProductsLoading());

    final result = await getProducts(
      GetProductsParams(
        category: event.category,
        universityId: event.universityId,
        sellerId: event.sellerId,
        isFeatured: event.isFeatured,
        limit: event.limit,
        offset: event.offset,
        filter: filterToUse,
      ),
    );

    if (isClosed) return;

    result.fold(
      (failure) {
        debugPrint('❌ Products load failed: ${failure.message}');
        emit(ProductError(message: failure.message));
      },
      (products) {
        debugPrint('✅ Products loaded: ${products.length} items');
        // Shuffle the products to randomize the home feed
        // Creating a new list to avoid mutating the original fixed-length list if any
        final shuffledProducts = List<ProductEntity>.from(products)
          ..shuffle(Random());
        emit(
          ProductsLoaded(
            products: shuffledProducts,
            hasMore: products.length == (event.limit ?? 20),
            currentFilter: event.filter ?? _currentFilter,
          ),
        );
        _currentFilter = event.filter ?? _currentFilter;
      },
    );
  }

  Future<void> _onLoadProductById(
    LoadProductByIdEvent event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());

    final result = await getProductById(
      GetProductByIdParams(productId: event.productId),
    );

    result.fold(
      (failure) => emit(ProductError(message: failure.message)),
      (product) => emit(ProductLoaded(product: product)),
    );
  }

  Future<void> _onLoadMyProducts(
    LoadMyProductsEvent event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductsLoading());

    final result = await getMyProducts(
      GetMyProductsParams(
        limit: event.limit,
        offset: event.offset,
        filter: event.filter,
      ),
    );

    result.fold(
      (failure) => emit(ProductError(message: failure.message)),
      (products) => emit(
        ProductsLoaded(
          products: products,
          hasMore: products.length == (event.limit ?? 20),
        ),
      ),
    );
  }

  Future<void> _onCreateProduct(
    CreateProductEvent event,
    Emitter<ProductState> emit,
  ) async {
    debugPrint('🚀 ProductBloc: Starting product creation...');
    debugPrint('📝 Title: ${event.title}');
    debugPrint('💰 Price: ${event.price}');
    debugPrint('📷 Images count: ${event.images.length}');

    emit(ProductCreating());

    final result = await createProduct(
      CreateProductParams(
        title: event.title,
        description: event.description,
        price: event.price,
        category: event.category,
        condition: event.condition,
        images: event.images,
        location: event.location,
        metadata: event.metadata,
        oldPrice: event.oldPrice,
        isGlobal: event.isGlobal,
      ),
    );

    result.fold(
      (failure) {
        debugPrint(
          '❌ ProductBloc: Product creation failed - ${failure.message}',
        );
        emit(ProductError(message: failure.message));
      },
      (product) {
        debugPrint(
          '✅ ProductBloc: Product created successfully - ID: ${product.id}',
        );
        emit(ProductCreated(product: product));

        // Automatically reload products if we have a ProductsLoaded state
        // This ensures the new product appears in lists immediately
        final currentState = state;
        if (currentState is ProductsLoaded) {
          debugPrint('🔄 Auto-reloading products after creation...');
          add(const LoadProductsEvent(limit: 10));
        }
      },
    );
  }

  Future<void> _onUpdateProduct(
    UpdateProductEvent event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductUpdating());

    final result = await updateProduct(
      UpdateProductParams(
        productId: event.productId,
        title: event.title,
        description: event.description,
        price: event.price,
        category: event.category,
        condition: event.condition,
        newImages: event.newImages,
        existingImages: event.existingImages,
        location: event.location,
        isActive: event.isActive,
        metadata: event.metadata,
        oldPrice: event.oldPrice,
        isGlobal: event.isGlobal,
      ),
    );

    result.fold(
      (failure) => emit(ProductError(message: failure.message)),
      (product) => emit(ProductUpdated(product: product)),
    );
  }

  Future<void> _onDeleteProduct(
    DeleteProductEvent event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductDeleting());

    final result = await deleteProduct(
      DeleteProductParams(productId: event.productId),
    );

    result.fold(
      (failure) => emit(ProductError(message: failure.message)),
      (_) => emit(ProductDeleted()),
    );
  }

  Future<void> _onIncrementViewCount(
    IncrementViewCountEvent event,
    Emitter<ProductState> emit,
  ) async {
    // Don't emit loading state for view count (silent operation)
    await incrementViewCount(
      IncrementViewCountParams(productId: event.productId),
    );
  }

  Future<void> _onLoadMoreProducts(
    LoadMoreProductsEvent event,
    Emitter<ProductState> emit,
  ) async {
    if (state is! ProductsLoaded) return;

    final currentState = state as ProductsLoaded;
    emit(ProductsLoadingMore(currentProducts: currentState.products));

    final result = await getProducts(
      GetProductsParams(
        category: event.category,
        universityId: event.universityId,
        isFeatured: event.isFeatured,
        offset: event.offset,
        filter: event.filter ?? currentState.currentFilter,
      ),
    );

    result.fold((failure) => emit(ProductError(message: failure.message)), (
      products,
    ) {
      final allProducts = [...currentState.products, ...products];
      emit(
        ProductsLoaded(
          products: allProducts,
          hasMore: products.length == 20,
          currentFilter: currentState.currentFilter,
        ),
      );
    });
  }
}
