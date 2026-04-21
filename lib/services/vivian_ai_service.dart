import 'package:cloud_functions/cloud_functions.dart';

import '../data/menu_repository.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class VivianAiService {
  VivianAiService()
      : _functions = FirebaseFunctions.instanceFor(
          region: 'us-central1',
        );

  final FirebaseFunctions _functions;

  Future<String> askVivian({
    required String message,
    required String orderType,
    required List<CartItemModel> cartItems,
  }) async {
    final trimmed = message.trim();

    if (trimmed.isEmpty) {
      return 'Ask me anything about our menu, prices, variants, or recommendations.';
    }

    final products = MenuRepository.getCachedProducts().isNotEmpty
        ? MenuRepository.getCachedProducts()
        : await MenuRepository.getAllProductsOnce();

    try {
      final callable = _functions.httpsCallable('askVivian');

      final result = await callable.call({
        'message': trimmed,
        'orderType': orderType,

        // ✅ send structured data, not ugly raw text
        'menuItems': products.map((e) => e.toMap()).toList(),
        'cartItems': cartItems.map((e) => _cartItemToMap(e)).toList(),

        // ✅ clear old legacy context
        'menuContext': '',
        'cartContext': '',
      });

      final data = result.data;

      if (data is Map && data['reply'] != null) {
        return data['reply'].toString().trim();
      }

      return _offlineReply(
        message: trimmed,
        cartItems: cartItems,
        allProducts: products,
      );
    } on FirebaseFunctionsException {
      return _offlineReply(
        message: trimmed,
        cartItems: cartItems,
        allProducts: products,
      );
    } catch (_) {
      return _offlineReply(
        message: trimmed,
        cartItems: cartItems,
        allProducts: products,
      );
    }
  }

  Map<String, dynamic> _cartItemToMap(CartItemModel item) {
    return {
      'productId': item.product.id,
      'name': item.product.name,
      'description': item.product.description,
      'categoryId': item.product.categoryId,
      'imageUrl': item.product.imageUrl,
      'variant': item.variant,
      'quantity': item.quantity,
      'price': item.unitPrice,
      'subtotal': item.subtotal,
      'tags': item.product.tags,
      'notes': '',
    };
  }

  String _offlineReply({
    required String message,
    required List<CartItemModel> cartItems,
    required List<ProductModel> allProducts,
  }) {
    final q = message.toLowerCase();
    final availableProducts = allProducts.where((e) => e.isAvailable).toList();
    final bestSellers = availableProducts.where((e) => e.isBestSeller).toList();

    if (q.contains('best seller') ||
        q.contains('bestseller') ||
        q.contains('popular') ||
        q.contains('best coffee')) {
      if (bestSellers.isEmpty) {
        final coffee = availableProducts
            .where((e) =>
                e.categoryId == 'drinks' ||
                e.tags.any((tag) => tag.toLowerCase().contains('coffee')))
            .take(3)
            .toList();

        if (coffee.isNotEmpty) {
          final picks = coffee.map((e) => e.name).join(', ');
          return 'Some great coffee picks are $picks.';
        }

        return 'I could not find bestseller items right now.';
      }

      final top = bestSellers.take(4).map((e) {
        final minPrice = e.prices.values.isEmpty
            ? 0.0
            : e.prices.values.reduce((a, b) => a < b ? a : b);
        return '${e.name} (from ₱${minPrice.toStringAsFixed(0)})';
      }).join(', ');

      return 'Our popular items include $top.';
    }

    if (q.contains('sweet') || q.contains('dessert')) {
      final sweetItems = availableProducts.where((e) {
        return e.categoryId == 'desserts' ||
            e.tags.any((tag) {
              final t = tag.toLowerCase();
              return t.contains('sweet') ||
                  t.contains('dessert') ||
                  t.contains('cake') ||
                  t.contains('chocolate');
            });
      }).take(4).toList();

      if (sweetItems.isNotEmpty) {
        return 'If you want something sweet, I recommend ${sweetItems.map((e) => e.name).join(', ')}.';
      }
    }

    if (q.contains('meal') || q.contains('food') || q.contains('filling')) {
      final meals = availableProducts
          .where((e) => e.categoryId == 'meals')
          .take(4)
          .toList();

      if (meals.isNotEmpty) {
        return 'For something filling, you can try ${meals.map((e) => e.name).join(', ')}.';
      }
    }

    if (q.contains('recommend') || q.contains('suggest')) {
      final drinks =
          availableProducts.where((e) => e.categoryId == 'drinks').take(2);
      final meals =
          availableProducts.where((e) => e.categoryId == 'meals').take(2);

      final picks = [...drinks, ...meals].map((e) => e.name).toSet().join(', ');

      if (picks.isNotEmpty) {
        return 'You can try these: $picks.';
      }
    }

    if (q.contains('cart')) {
      if (cartItems.isEmpty) {
        return 'Your cart is currently empty.';
      }

      final summary =
          cartItems.map((e) => '${e.quantity}x ${e.product.name}').join(', ');

      return 'Your cart currently has $summary.';
    }

    final exact = availableProducts.where((e) {
      return q.contains(e.name.toLowerCase());
    }).toList();

    if (exact.isNotEmpty) {
      final p = exact.first;
      final prices = p.prices.entries
          .map((e) => '${e.key}: ₱${e.value.toStringAsFixed(0)}')
          .join(', ');

      return '${p.name}: ${p.description.isNotEmpty ? p.description : 'A good menu choice.'} Available variants and prices: $prices.';
    }

    return 'I can help with menu items, variants, prices, best sellers, and cart suggestions.';
  }
}