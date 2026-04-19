import 'package:cloud_functions/cloud_functions.dart';

import '../data/menu_repository.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class VivianAiService {
  VivianAiService()
    : _functions = FirebaseFunctions.instanceFor(
        region: 'us-central1', // change if your function uses another region
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

    final menuContext = _buildMenuContext(MenuRepository.getAllProducts());
    final cartContext = _buildCartContext(cartItems);

    try {
      final callable = _functions.httpsCallable('askVivian');

      final result = await callable.call({
        'message': trimmed,
        'orderType': orderType,
        'menuContext': menuContext,
        'cartContext': cartContext,
      });

      final data = result.data;

      if (data is Map && data['reply'] != null) {
        return data['reply'].toString().trim();
      }

      return _offlineReply(message: trimmed, cartItems: cartItems);
    } on FirebaseFunctionsException catch (e) {
      print('FirebaseFunctionsException: ${e.code} | ${e.message}');
      return _offlineReply(message: trimmed, cartItems: cartItems);
    } catch (e) {
      print('Vivian AI error: $e');
      return _offlineReply(message: trimmed, cartItems: cartItems);
    }
  }

  String _buildMenuContext(List<ProductModel> products) {
    final buffer = StringBuffer();

    for (final p in products) {
      final variants = p.availableVariants.join(', ');
      final prices = p.prices.entries
          .map((e) => '${e.key}: ₱${e.value.toStringAsFixed(0)}')
          .join(', ');
      final tags = p.tags.join(', ');

      buffer.writeln(
        '- ${p.name} | category: ${p.categoryId} | description: ${p.description} | variants: $variants | prices: $prices | tags: $tags | bestseller: ${p.isBestSeller}',
      );
    }

    return buffer.toString();
  }

  String _buildCartContext(List<CartItemModel> cartItems) {
    if (cartItems.isEmpty) return 'Cart is empty.';

    return cartItems
        .map(
          (e) =>
              '${e.quantity}x ${e.product.name} (${e.variant}) = ₱${e.subtotal.toStringAsFixed(0)}',
        )
        .join('\n');
  }

  String _offlineReply({
    required String message,
    required List<CartItemModel> cartItems,
  }) {
    final q = message.toLowerCase();
    final allProducts = MenuRepository.getAllProducts();
    final bestSellers = allProducts.where((e) => e.isBestSeller).toList();

    if (q.contains('best seller') ||
        q.contains('bestseller') ||
        q.contains('popular')) {
      if (bestSellers.isEmpty) {
        return 'I could not find bestseller items right now.';
      }

      final top = bestSellers
          .take(4)
          .map((e) {
            final minPrice = e.prices.values.reduce((a, b) => a < b ? a : b);
            return '${e.name} (from ₱${minPrice.toStringAsFixed(0)})';
          })
          .join(', ');

      return 'Our popular items include $top.';
    }

    if (q.contains('cart') || q.contains('order')) {
      if (cartItems.isEmpty) {
        return 'Your cart is still empty.';
      }

      final total = cartItems.fold<double>(0, (sum, e) => sum + e.subtotal);
      final summary = cartItems
          .map((e) => '${e.quantity}x ${e.product.name}')
          .join(', ');

      return 'Your current order is $summary. Total so far is ₱${total.toStringAsFixed(0)}.';
    }

    final matched = MenuRepository.searchProducts(message);
    if (matched.isNotEmpty) {
      final top = matched
          .take(5)
          .map((e) {
            final minPrice = e.prices.values.reduce((a, b) => a < b ? a : b);
            return '${e.name} (from ₱${minPrice.toStringAsFixed(0)})';
          })
          .join(', ');

      return 'I found these menu items for "$message": $top.';
    }

    final cheapest = [...allProducts]
      ..sort((a, b) => a.basePrice.compareTo(b.basePrice));

    if (q.contains('cheap') ||
        q.contains('lowest') ||
        q.contains('affordable')) {
      final picks = cheapest
          .take(4)
          .map((e) => '${e.name} (₱${e.basePrice.toStringAsFixed(0)})')
          .join(', ');
      return 'Some affordable choices are $picks.';
    }

    if (q.contains('recommend')) {
      final drinks = allProducts.where((e) => e.categoryId == 'drinks').take(2);
      final meals = allProducts.where((e) => e.categoryId == 'meals').take(2);
      final picks = [...drinks, ...meals].map((e) => e.name).join(', ');
      return 'I recommend $picks.';
    }

    return 'I’m having trouble reaching AI right now, but I can still help with menu search, recommendations, bestsellers, and your current cart.';
  }
}
