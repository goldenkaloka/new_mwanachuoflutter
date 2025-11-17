import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/features/products/domain/usecases/create_product.dart';
import 'package:mwanachuo/features/products/domain/usecases/delete_product.dart';
import 'package:mwanachuo/features/products/domain/usecases/get_my_products.dart';
import 'package:mwanachuo/features/products/domain/usecases/get_product_by_id.dart';
import 'package:mwanachuo/features/products/domain/usecases/get_products.dart';
import 'package:mwanachuo/features/products/domain/usecases/increment_view_count.dart';
import 'package:mwanachuo/features/products/domain/usecases/update_product.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_event.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_state.dart';

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
    
    debugPrint('📦 Loading products...');
    emit(ProductsLoading());

    final result = await getProducts(
      GetProductsParams(
        category: event.category,
        universityId: event.universityId,
        sellerId: event.sellerId,
        isFeatured: event.isFeatured,
        limit: event.limit,
        offset: event.offset,
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
        emit(ProductsLoaded(
          products: products,
          hasMore: products.length == (event.limit ?? 20),
        ));
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
      ),
    );

    result.fold(
      (failure) => emit(ProductError(message: failure.message)),
      (products) => emit(ProductsLoaded(
        products: products,
        hasMore: products.length == (event.limit ?? 20),
      )),
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
      ),
    );

    result.fold(
      (failure) {
        debugPrint('❌ ProductBloc: Product creation failed - ${failure.message}');
        emit(ProductError(message: failure.message));
      },
      (product) {
        debugPrint('✅ ProductBloc: Product created successfully - ID: ${product.id}');
        emit(ProductCreated(product: product));
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
      ),
    );

    result.fold(
      (failure) => emit(ProductError(message: failure.message)),
      (products) {
        final allProducts = [...currentState.products, ...products];
        emit(ProductsLoaded(
          products: allProducts,
          hasMore: products.length == 20,
        ));
      },
    );
  }
}

