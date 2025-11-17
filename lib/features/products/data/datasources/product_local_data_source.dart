import 'dart:convert';
import 'package:mwanachuo/core/constants/storage_constants.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/features/products/data/models/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstract class defining product local data source operations
abstract class ProductLocalDataSource {
  /// Cache products
  Future<void> cacheProducts(List<ProductModel> products);

  /// Get cached products
  Future<List<ProductModel>> getCachedProducts();

  /// Cache single product
  Future<void> cacheProduct(ProductModel product);

  /// Get cached product
  Future<ProductModel> getCachedProduct(String productId);

  /// Clear product cache
  Future<void> clearCache();
}

/// Implementation of ProductLocalDataSource using SharedPreferences
class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final SharedPreferences sharedPreferences;

  ProductLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheProducts(List<ProductModel> products) async {
    try {
      final jsonList = products.map((p) => p.toJson()).toList();
      await sharedPreferences.setString(
        StorageConstants.productsCacheKey,
        json.encode(jsonList),
      );
    } catch (e) {
      throw CacheException('Failed to cache products: $e');
    }
  }

  @override
  Future<List<ProductModel>> getCachedProducts() async {
    try {
      final jsonString = sharedPreferences.getString(
        StorageConstants.productsCacheKey,
      );

      if (jsonString == null) {
        throw CacheException('No cached products found');
      }

      final jsonList = json.decode(jsonString) as List;
      return jsonList.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      throw CacheException('Failed to get cached products: $e');
    }
  }

  @override
  Future<void> cacheProduct(ProductModel product) async {
    try {
      await sharedPreferences.setString(
        '${StorageConstants.productCachePrefix}_${product.id}',
        json.encode(product.toJson()),
      );
    } catch (e) {
      throw CacheException('Failed to cache product: $e');
    }
  }

  @override
  Future<ProductModel> getCachedProduct(String productId) async {
    try {
      final jsonString = sharedPreferences.getString(
        '${StorageConstants.productCachePrefix}_$productId',
      );

      if (jsonString == null) {
        throw CacheException('No cached product found');
      }

      return ProductModel.fromJson(json.decode(jsonString));
    } catch (e) {
      throw CacheException('Failed to get cached product: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await sharedPreferences.remove(StorageConstants.productsCacheKey);
      
      // Remove individual product caches
      final keys = sharedPreferences.getKeys();
      final productKeys = keys.where((key) =>
          key.startsWith(StorageConstants.productCachePrefix));
      
      for (final key in productKeys) {
        await sharedPreferences.remove(key);
      }
    } catch (e) {
      throw CacheException('Failed to clear cache: $e');
    }
  }
}

