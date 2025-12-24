import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/categories/domain/usecases/get_product_categories.dart';
import 'package:mwanachuo/features/shared/categories/domain/usecases/get_product_conditions.dart';
import 'package:mwanachuo/features/shared/categories/presentation/cubit/category_state.dart';
import 'package:mwanachuo/features/shared/categories/domain/entities/category_entity.dart';

/// Cubit for managing category and condition state
class CategoryCubit extends Cubit<CategoryState> {
  final GetProductCategories getProductCategories;
  final GetProductConditions getProductConditions;

  CategoryCubit({
    required this.getProductCategories,
    required this.getProductConditions,
  }) : super(CategoryInitial());

  /// Load product categories
  Future<void> loadProductCategories() async {
    emit(CategoryLoading());

    final result = await getProductCategories(NoParams());

    result.fold(
      (failure) => emit(CategoryError(failure.message)),
      (categories) => emit(
        CategoriesLoaded(
          categories: categories,
          conditions: state is CategoriesLoaded
              ? (state as CategoriesLoaded).conditions
              : [],
        ),
      ),
    );
  }

  /// Load product conditions
  Future<void> loadProductConditions() async {
    emit(CategoryLoading());

    final result = await getProductConditions(NoParams());

    result.fold(
      (failure) => emit(CategoryError(failure.message)),
      (conditions) => emit(
        CategoriesLoaded(
          categories: state is CategoriesLoaded
              ? (state as CategoriesLoaded).categories
              : [],
          conditions: conditions,
        ),
      ),
    );
  }

  /// Load both categories and conditions
  Future<void> loadAll() async {
    emit(CategoryLoading());

    final categoriesResult = await getProductCategories(NoParams());
    final conditionsResult = await getProductConditions(NoParams());

    categoriesResult.fold((failure) => emit(CategoryError(failure.message)), (
      categories,
    ) {
      conditionsResult.fold(
        (failure) => emit(CategoryError(failure.message)),
        (conditions) => emit(
          CategoriesLoaded(categories: categories, conditions: conditions),
        ),
      );
    });
  }

  /// Load service categories (Static list for now)
  Future<void> loadServiceCategories() async {
    emit(CategoryLoading());

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    final categories = [
      const ProductCategoryEntity(
        id: 's1',
        name: 'Tutoring',
        icon: 'book',
        displayOrder: 1,
      ),
      const ProductCategoryEntity(
        id: 's2',
        name: 'Cleaning',
        icon: 'spa',
        displayOrder: 2,
      ),
      const ProductCategoryEntity(
        id: 's3',
        name: 'Laundry',
        icon: 'tshirt',
        displayOrder: 3,
      ),
      const ProductCategoryEntity(
        id: 's4',
        name: 'Delivery',
        icon: 'car',
        displayOrder: 4,
      ),
      const ProductCategoryEntity(
        id: 's5',
        name: 'Printing',
        icon: 'pencil',
        displayOrder: 5,
      ),
      const ProductCategoryEntity(
        id: 's6',
        name: 'Graphics & Design',
        icon: 'palette',
        displayOrder: 6,
      ),
      const ProductCategoryEntity(
        id: 's7',
        name: 'Repairs',
        icon: 'wrench',
        displayOrder: 7,
      ),
      const ProductCategoryEntity(
        id: 's8',
        name: 'Beauty & Salon',
        icon: 'ring',
        displayOrder: 8,
      ),
      const ProductCategoryEntity(
        id: 's9',
        name: 'Photography',
        icon: 'camera_alt',
        displayOrder: 9,
      ),
      const ProductCategoryEntity(
        id: 's10',
        name: 'Other',
        icon: 'more_horiz',
        displayOrder: 10,
      ),
    ];

    emit(CategoriesLoaded(categories: categories, conditions: []));
  }
}
