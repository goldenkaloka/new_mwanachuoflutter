import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/features/orders/domain/entities/order.dart';

// Events
abstract class CartEvent extends Equatable {
  const CartEvent();
  @override
  List<Object?> get props => [];
}

class AddToCart extends CartEvent {
  final OrderItem item;
  final String vendorId;
  const AddToCart(this.item, this.vendorId);
  @override
  List<Object?> get props => [item, vendorId];
}

class RemoveFromCart extends CartEvent {
  final String productId;
  const RemoveFromCart(this.productId);
  @override
  List<Object?> get props => [productId];
}

class UpdateQuantity extends CartEvent {
  final String productId;
  final int quantity;
  const UpdateQuantity(this.productId, this.quantity);
  @override
  List<Object?> get props => [productId, quantity];
}

class ClearCart extends CartEvent {}

// State
class CartState extends Equatable {
  final List<OrderItem> items;
  final String? vendorId;

  const CartState({this.items = const [], this.vendorId});

  double get totalPrice =>
      items.fold(0, (sum, item) => sum + (item.priceAtTime * item.quantity));
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({
    List<OrderItem>? items,
    String? vendorId,
    bool clearVendor = false,
  }) {
    return CartState(
      items: items ?? this.items,
      vendorId: clearVendor ? null : (vendorId ?? this.vendorId),
    );
  }

  @override
  List<Object?> get props => [items, vendorId];
}

// Bloc
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<UpdateQuantity>(_onUpdateQuantity);
    on<ClearCart>(_onClearCart);
  }

  void _onAddToCart(AddToCart event, Emitter<CartState> emit) {
    if (state.vendorId != null && state.vendorId != event.vendorId) {
      // Different vendor, for now we just clear and add new item (or could show error)
      emit(CartState(items: [event.item], vendorId: event.vendorId));
      return;
    }

    final existingIndex = state.items.indexWhere(
      (item) => item.productId == event.item.productId,
    );

    if (existingIndex >= 0) {
      final updatedItems = List<OrderItem>.from(state.items);
      final existingItem = updatedItems[existingIndex];
      updatedItems[existingIndex] = OrderItem(
        id: existingItem.id,
        productId: existingItem.productId,
        productName: existingItem.productName,
        quantity: existingItem.quantity + event.item.quantity,
        priceAtTime: existingItem.priceAtTime,
      );
      emit(state.copyWith(items: updatedItems, vendorId: event.vendorId));
    } else {
      emit(
        state.copyWith(
          items: [...state.items, event.item],
          vendorId: event.vendorId,
        ),
      );
    }
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<CartState> emit) {
    final updatedItems = state.items
        .where((item) => item.productId != event.productId)
        .toList();
    emit(state.copyWith(items: updatedItems));
  }

  void _onUpdateQuantity(UpdateQuantity event, Emitter<CartState> emit) {
    if (event.quantity <= 0) {
      add(RemoveFromCart(event.productId));
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.productId == event.productId) {
        return OrderItem(
          id: item.id,
          productId: item.productId,
          productName: item.productName,
          quantity: event.quantity,
          priceAtTime: item.priceAtTime,
        );
      }
      return item;
    }).toList();

    emit(state.copyWith(items: updatedItems));
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    emit(const CartState());
  }
}
