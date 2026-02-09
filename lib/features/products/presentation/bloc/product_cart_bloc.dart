import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/features/products/domain/entities/product_entity.dart';

// ==================== EVENTS ====================

abstract class ProductCartEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AddProductToCart extends ProductCartEvent {
  final ProductEntity product;
  final int quantity;

  AddProductToCart({required this.product, this.quantity = 1});

  @override
  List<Object?> get props => [product, quantity];
}

class RemoveFromCart extends ProductCartEvent {
  final String productId;

  RemoveFromCart(this.productId);

  @override
  List<Object?> get props => [productId];
}

class UpdateCartQuantity extends ProductCartEvent {
  final String productId;
  final int quantity;

  UpdateCartQuantity({required this.productId, required this.quantity});

  @override
  List<Object?> get props => [productId, quantity];
}

class ClearCart extends ProductCartEvent {}

class ClearSellerCart extends ProductCartEvent {
  final String sellerId;

  ClearSellerCart(this.sellerId);

  @override
  List<Object?> get props => [sellerId];
}

// ==================== STATE ====================

class CartItem extends Equatable {
  final ProductEntity product;
  final int quantity;

  const CartItem({required this.product, required this.quantity});

  double get subtotal => product.price * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(product: product, quantity: quantity ?? this.quantity);
  }

  @override
  List<Object?> get props => [product, quantity];
}

class ProductCartState extends Equatable {
  final Map<String, List<CartItem>> itemsBySeller; // Grouped by seller ID
  final int totalItems;
  final double totalAmount;

  const ProductCartState({
    this.itemsBySeller = const {},
    this.totalItems = 0,
    this.totalAmount = 0,
  });

  List<CartItem> get allItems {
    return itemsBySeller.values.expand((items) => items).toList();
  }

  List<String> get sellerIds => itemsBySeller.keys.toList();

  List<CartItem> getItemsForSeller(String sellerId) {
    return itemsBySeller[sellerId] ?? [];
  }

  double getSubtotalForSeller(String sellerId) {
    final items = getItemsForSeller(sellerId);
    return items.fold(0, (sum, item) => sum + item.subtotal);
  }

  int getItemCountForSeller(String sellerId) {
    final items = getItemsForSeller(sellerId);
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  @override
  List<Object?> get props => [itemsBySeller, totalItems, totalAmount];
}

// ==================== BLOC ====================

class ProductCartBloc extends Bloc<ProductCartEvent, ProductCartState> {
  ProductCartBloc() : super(const ProductCartState()) {
    on<AddProductToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<UpdateCartQuantity>(_onUpdateQuantity);
    on<ClearCart>(_onClearCart);
    on<ClearSellerCart>(_onClearSellerCart);
  }

  void _onAddToCart(AddProductToCart event, Emitter<ProductCartState> emit) {
    final newItemsBySeller = Map<String, List<CartItem>>.from(
      state.itemsBySeller,
    );
    final sellerId = event.product.sellerId;

    // Get existing items for this seller
    final sellerItems = List<CartItem>.from(newItemsBySeller[sellerId] ?? []);

    // Check if product already exists
    final existingIndex = sellerItems.indexWhere(
      (item) => item.product.id == event.product.id,
    );

    if (existingIndex >= 0) {
      // Update quantity
      sellerItems[existingIndex] = sellerItems[existingIndex].copyWith(
        quantity: sellerItems[existingIndex].quantity + event.quantity,
      );
    } else {
      // Add new item
      sellerItems.add(
        CartItem(product: event.product, quantity: event.quantity),
      );
    }

    newItemsBySeller[sellerId] = sellerItems;

    emit(_calculateTotals(newItemsBySeller));
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<ProductCartState> emit) {
    final newItemsBySeller = Map<String, List<CartItem>>.from(
      state.itemsBySeller,
    );

    // Find and remove the product
    for (final sellerId in newItemsBySeller.keys.toList()) {
      final sellerItems = newItemsBySeller[sellerId]!;
      sellerItems.removeWhere((item) => item.product.id == event.productId);

      if (sellerItems.isEmpty) {
        newItemsBySeller.remove(sellerId);
      } else {
        newItemsBySeller[sellerId] = sellerItems;
      }
    }

    emit(_calculateTotals(newItemsBySeller));
  }

  void _onUpdateQuantity(
    UpdateCartQuantity event,
    Emitter<ProductCartState> emit,
  ) {
    if (event.quantity <= 0) {
      add(RemoveFromCart(event.productId));
      return;
    }

    final newItemsBySeller = Map<String, List<CartItem>>.from(
      state.itemsBySeller,
    );

    // Find and update the product
    for (final sellerId in newItemsBySeller.keys) {
      final sellerItems = List<CartItem>.from(newItemsBySeller[sellerId]!);
      final index = sellerItems.indexWhere(
        (item) => item.product.id == event.productId,
      );

      if (index >= 0) {
        sellerItems[index] = sellerItems[index].copyWith(
          quantity: event.quantity,
        );
        newItemsBySeller[sellerId] = sellerItems;
        break;
      }
    }

    emit(_calculateTotals(newItemsBySeller));
  }

  void _onClearCart(ClearCart event, Emitter<ProductCartState> emit) {
    emit(const ProductCartState());
  }

  void _onClearSellerCart(
    ClearSellerCart event,
    Emitter<ProductCartState> emit,
  ) {
    final newItemsBySeller = Map<String, List<CartItem>>.from(
      state.itemsBySeller,
    );
    newItemsBySeller.remove(event.sellerId);
    emit(_calculateTotals(newItemsBySeller));
  }

  ProductCartState _calculateTotals(Map<String, List<CartItem>> itemsBySeller) {
    int totalItems = 0;
    double totalAmount = 0;

    for (final items in itemsBySeller.values) {
      for (final item in items) {
        totalItems += item.quantity;
        totalAmount += item.subtotal;
      }
    }

    return ProductCartState(
      itemsBySeller: itemsBySeller,
      totalItems: totalItems,
      totalAmount: totalAmount,
    );
  }
}
