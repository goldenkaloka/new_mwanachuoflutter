# Migration Guide: Existing UI to Clean Architecture

## Overview

This guide helps you migrate the existing UI components to the new Clean Architecture structure with Supabase backend.

## Migration Strategy

### Phase 1: Core Setup ✅
- [x] Set up folder structure
- [x] Add dependencies
- [x] Create core layer files
- [x] Set up Supabase configuration

### Phase 2: Authentication Feature ✅
- [x] Create auth domain layer (entities, use cases, repository interface)
- [x] Create auth data layer (models, data sources, repository implementation)
- [x] Create auth presentation layer (BLoC, states, events)

### Phase 3: Migrate Existing Features

#### Products Feature
1. **Domain Layer**
   - Create `ProductEntity`
   - Create `ProductRepository` interface
   - Create use cases: `GetProducts`, `CreateProduct`, `UpdateProduct`, `DeleteProduct`

2. **Data Layer**
   - Create `ProductModel` extending `ProductEntity`
   - Create `ProductRemoteDataSource` (Supabase)
   - Create `ProductLocalDataSource` (Hive cache)
   - Implement `ProductRepositoryImpl`

3. **Presentation Layer**
   - Create `ProductBloc` with events and states
   - Migrate `product_details_page.dart` to use BLoC
   - Migrate `all_products_page.dart` to use BLoC
   - Migrate `post_product_screen.dart` to use BLoC

#### Services Feature
1. Create domain/data/presentation layers (similar to Products)
2. Migrate existing service screens

#### Accommodations Feature
1. Create domain/data/presentation layers
2. Migrate existing accommodation screens

#### Messages Feature
1. Create domain/data/presentation layers
2. Implement real-time messaging with Supabase Realtime
3. Migrate existing message screens

### Phase 4: Advanced Features
- Reviews and ratings integration
- Notifications with Supabase triggers
- Image upload to Supabase Storage
- Search functionality
- Filters and sorting

## Step-by-Step Migration Example: Products

### Step 1: Create Product Entity

```dart
// lib/features/products/domain/entities/product_entity.dart
import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String id;
  final String sellerId;
  final String universityId;
  final String title;
  final String description;
  final double price;
  final String category;
  final String condition;
  final List<String> images;
  final String status;
  final int views;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductEntity({
    required this.id,
    required this.sellerId,
    required this.universityId,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    required this.images,
    required this.status,
    required this.views,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object> get props => [
        id,
        sellerId,
        universityId,
        title,
        description,
        price,
        category,
        condition,
        images,
        status,
        views,
        createdAt,
        updatedAt,
      ];
}
```

### Step 2: Create Product Model

```dart
// lib/features/products/data/models/product_model.dart
import 'package:mwanachuo/features/products/domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.sellerId,
    required super.universityId,
    required super.title,
    required super.description,
    required super.price,
    required super.category,
    required super.condition,
    required super.images,
    required super.status,
    required super.views,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      sellerId: json['seller_id'],
      universityId: json['university_id'],
      title: json['title'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      category: json['category'],
      condition: json['condition'],
      images: List<String>.from(json['images'] ?? []),
      status: json['status'] ?? 'active',
      views: json['views'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'university_id': universityId,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'condition': condition,
      'images': images,
      'status': status,
      'views': views,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
```

### Step 3: Create Remote Data Source

```dart
// lib/features/products/data/datasources/product_remote_data_source.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mwanachuo/features/products/data/models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts({String? universityId, String? category});
  Future<ProductModel> getProductById(String id);
  Future<ProductModel> createProduct(ProductModel product);
  Future<ProductModel> updateProduct(ProductModel product);
  Future<void> deleteProduct(String id);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final SupabaseClient supabase;

  ProductRemoteDataSourceImpl(this.supabase);

  @override
  Future<List<ProductModel>> getProducts({String? universityId, String? category}) async {
    var query = supabase.from('products').select().eq('status', 'active');
    
    if (universityId != null) {
      query = query.eq('university_id', universityId);
    }
    
    if (category != null) {
      query = query.eq('category', category);
    }
    
    final data = await query.order('created_at', ascending: false);
    return (data as List).map((json) => ProductModel.fromJson(json)).toList();
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    final data = await supabase.from('products').select().eq('id', id).single();
    return ProductModel.fromJson(data);
  }

  @override
  Future<ProductModel> createProduct(ProductModel product) async {
    final data = await supabase.from('products').insert(product.toJson()).select().single();
    return ProductModel.fromJson(data);
  }

  @override
  Future<ProductModel> updateProduct(ProductModel product) async {
    final data = await supabase
        .from('products')
        .update(product.toJson())
        .eq('id', product.id)
        .select()
        .single();
    return ProductModel.fromJson(data);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await supabase.from('products').delete().eq('id', id);
  }
}
```

### Step 4: Create Use Case

```dart
// lib/features/products/domain/usecases/get_products.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/products/domain/entities/product_entity.dart';
import 'package:mwanachuo/features/products/domain/repositories/product_repository.dart';

class GetProducts implements UseCase<List<ProductEntity>, GetProductsParams> {
  final ProductRepository repository;

  GetProducts(this.repository);

  @override
  Future<Either<Failure, List<ProductEntity>>> call(GetProductsParams params) async {
    return await repository.getProducts(
      universityId: params.universityId,
      category: params.category,
    );
  }
}

class GetProductsParams extends Equatable {
  final String? universityId;
  final String? category;

  const GetProductsParams({this.universityId, this.category});

  @override
  List<Object?> get props => [universityId, category];
}
```

### Step 5: Create BLoC

```dart
// lib/features/products/presentation/bloc/product_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/features/products/domain/usecases/get_products.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProducts getProducts;

  ProductBloc({required this.getProducts}) : super(ProductInitial()) {
    on<LoadProductsEvent>(_onLoadProducts);
  }

  Future<void> _onLoadProducts(
    LoadProductsEvent event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    
    final result = await getProducts(GetProductsParams(
      universityId: event.universityId,
      category: event.category,
    ));

    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (products) => emit(ProductsLoaded(products)),
    );
  }
}
```

### Step 6: Update UI to use BLoC

```dart
// lib/features/products/presentation/pages/all_products_page.dart
import 'package:flutter_bloc/flutter_bloc.dart';

class AllProductsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ProductBloc>()..add(LoadProductsEvent()),
      child: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          if (state is ProductLoading) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (state is ProductsLoaded) {
            return GridView.builder(
              itemCount: state.products.length,
              itemBuilder: (context, index) {
                final product = state.products[index];
                return ProductCard(product: product);
              },
            );
          }
          
          if (state is ProductError) {
            return Center(child: Text(state.message));
          }
          
          return SizedBox();
        },
      ),
    );
  }
}
```

## Key Principles

1. **Dependency Rule**: Inner layers don't depend on outer layers
2. **Single Responsibility**: Each class has one job
3. **Interface Segregation**: Use abstract classes for contracts
4. **Dependency Inversion**: Depend on abstractions, not concretions
5. **Testability**: Every layer can be tested in isolation

## Next Steps

1. Run `flutter pub get` to install dependencies
2. Set up Supabase project and run `SUPABASE_SETUP.sql`
3. Update `supabase_config.dart` with your credentials
4. Run code generation
5. Start migrating features one by one
6. Test each feature as you migrate it
7. Update main.dart to initialize Supabase and DI

---

**Remember**: Migration is incremental. You can keep the old code working while gradually moving features to the new architecture.

