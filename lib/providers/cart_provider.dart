import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  /// key = productId_variant
  final Map<String, CartItemModel> _items = {};

  Map<String, CartItemModel> get items => _items;

  List<CartItemModel> get itemList => _items.values.toList();

  bool get isEmpty => _items.isEmpty;

  int get totalItems {
    int total = 0;
    for (var item in _items.values) {
      total += item.quantity;
    }
    return total;
  }

  double get subtotal {
    double total = 0;
    for (var item in _items.values) {
      total += item.subtotal;
    }
    return total;
  }

  double get totalAmount => subtotal; // extend later for tax/discount

  /// -------------------------
  /// ADD ITEM
  /// -------------------------
  void addItem({
    required ProductModel product,
    required String variant,
    int quantity = 1,
    String note = '',
  }) {
    final key = '${product.id}_$variant';

    final price = product.prices[variant] ?? product.basePrice;

    if (_items.containsKey(key)) {
      final existing = _items[key]!;

      _items[key] = existing.copyWith(quantity: existing.quantity + quantity);
    } else {
      _items[key] = CartItemModel(
        product: product,
        variant: variant,
        quantity: quantity,
        unitPrice: price,
        note: note,
      );
    }

    notifyListeners();
  }

  /// -------------------------
  /// INCREASE QUANTITY
  /// -------------------------
  void increaseQty(String key) {
    if (!_items.containsKey(key)) return;

    final item = _items[key]!;

    _items[key] = item.copyWith(quantity: item.quantity + 1);

    notifyListeners();
  }

  /// -------------------------
  /// DECREASE QUANTITY
  /// -------------------------
  void decreaseQty(String key) {
    if (!_items.containsKey(key)) return;

    final item = _items[key]!;

    if (item.quantity <= 1) {
      _items.remove(key);
    } else {
      _items[key] = item.copyWith(quantity: item.quantity - 1);
    }

    notifyListeners();
  }

  /// -------------------------
  /// REMOVE ITEM
  /// -------------------------
  void removeItem(String key) {
    _items.remove(key);
    notifyListeners();
  }

  /// -------------------------
  /// CLEAR CART
  /// -------------------------
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  /// -------------------------
  /// UPDATE NOTE (optional)
  /// -------------------------
  void updateNote(String key, String note) {
    if (!_items.containsKey(key)) return;

    final item = _items[key]!;

    _items[key] = item.copyWith(note: note);
    notifyListeners();
  }

  /// -------------------------
  /// CONVERT TO ORDER FORMAT
  /// -------------------------
  List<Map<String, dynamic>> toOrderItems() {
    return _items.values.map((item) => item.toOrderMap()).toList();
  }
}
