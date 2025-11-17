import 'package:equatable/equatable.dart';

/// Product category entity
class ProductCategoryEntity extends Equatable {
  final String id;
  final String name;
  final String icon;
  final int productCount;

  const ProductCategoryEntity({
    required this.id,
    required this.name,
    required this.icon,
    this.productCount = 0,
  });

  @override
  List<Object?> get props => [id, name, icon, productCount];
}

/// Predefined product categories
class ProductCategories {
  static const electronics = 'Electronics';
  static const books = 'Books & Textbooks';
  static const clothing = 'Clothing & Fashion';
  static const furniture = 'Furniture';
  static const sports = 'Sports & Fitness';
  static const beauty = 'Beauty & Personal Care';
  static const food = 'Food & Beverages';
  static const stationery = 'Stationery & Supplies';
  static const automotive = 'Automotive';
  static const other = 'Other';

  static List<String> get all => [
        electronics,
        books,
        clothing,
        furniture,
        sports,
        beauty,
        food,
        stationery,
        automotive,
        other,
      ];
}

/// Product condition options
class ProductCondition {
  static const brandNew = 'Brand New';
  static const likeNew = 'Like New';
  static const good = 'Good';
  static const fair = 'Fair';
  static const poor = 'Poor';

  static List<String> get all => [
        brandNew,
        likeNew,
        good,
        fair,
        poor,
      ];
}

