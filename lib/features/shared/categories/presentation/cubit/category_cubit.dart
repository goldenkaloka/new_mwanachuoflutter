import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/categories/domain/usecases/get_product_categories.dart';
import 'package:mwanachuo/features/shared/categories/domain/usecases/get_product_conditions.dart';
import 'package:mwanachuo/features/shared/categories/presentation/cubit/category_state.dart';

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
      (categories) => emit(CategoriesLoaded(
        categories: categories,
        conditions: state is CategoriesLoaded 
            ? (state as CategoriesLoaded).conditions 
            : [],
      )),
    );
  }

  /// Load product conditions
  Future<void> loadProductConditions() async {
    emit(CategoryLoading());
    
    final result = await getProductConditions(NoParams());
    
    result.fold(
      (failure) => emit(CategoryError(failure.message)),
      (conditions) => emit(CategoriesLoaded(
        categories: state is CategoriesLoaded 
            ? (state as CategoriesLoaded).categories 
            : [],
        conditions: conditions,
      )),
    );
  }

  /// Load both categories and conditions
  Future<void> loadAll() async {
    emit(CategoryLoading());
    
    final categoriesResult = await getProductCategories(NoParams());
    final conditionsResult = await getProductConditions(NoParams());
    
    categoriesResult.fold(
      (failure) => emit(CategoryError(failure.message)),
      (categories) {
        conditionsResult.fold(
          (failure) => emit(CategoryError(failure.message)),
          (conditions) => emit(CategoriesLoaded(
            categories: categories,
            conditions: conditions,
          )),
        );
      },
    );
  }
}

