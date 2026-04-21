import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';

class MenuRepository {
  MenuRepository._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static List<ProductModel> _cachedProducts = [];

  static Stream<List<ProductModel>> watchAllProducts() {
    return _firestore.collection('products').snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => _productFromFirestore(doc))
          .where((e) => e.isAvailable)
          .toList();

      items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      _cachedProducts = items;
      return items;
    });
  }

  static Stream<List<ProductModel>> watchProductsByCategory(String categoryId) {
    return watchAllProducts().map((products) {
      if (categoryId == 'all_menu') {
        return products;
      }

      if (categoryId == 'best_sellers') {
        return products.where((e) => e.isBestSeller).toList();
      }

      return products.where((e) => e.categoryId == categoryId).toList();
    });
  }

  static Stream<List<ProductModel>> searchProducts(String keyword) {
    return watchAllProducts().map((products) {
      final query = keyword.trim().toLowerCase();

      if (query.isEmpty) return products;

      final items = products.where((product) {
        final haystack = [
          product.name,
          product.description,
          product.categoryId,
          ...product.tags,
        ].join(' ').toLowerCase();

        return haystack.contains(query);
      }).toList();

      items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return items;
    });
  }

  static Stream<List<CategoryModel>> watchCategories() {
    return watchAllProducts().map((products) {
      final ids = <String>{};
      for (final p in products) {
        ids.add(p.categoryId);
      }

      final categories = <CategoryModel>[
        const CategoryModel(
          id: 'all_menu',
          name: 'All Menu',
          iconName: 'restaurant_menu',
          sortOrder: -1,
        ),
        const CategoryModel(
          id: 'best_sellers',
          name: 'Best Sellers',
          iconName: 'star',
          sortOrder: 0,
        ),
      ];

      final mapped = ids.map((id) {
        return CategoryModel(
          id: id,
          name: _displayCategoryName(id),
          iconName: _iconForCategory(id),
          sortOrder: _sortForCategory(id),
        );
      }).toList();

      mapped.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      categories.addAll(mapped);

      return categories;
    });
  }

  static Future<List<ProductModel>> getAllProductsOnce() async {
    final snapshot = await _firestore.collection('products').get();

    final items = snapshot.docs
        .map((doc) => _productFromFirestore(doc))
        .where((e) => e.isAvailable)
        .toList();

    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    _cachedProducts = items;
    return items;
  }

  static List<ProductModel> getCachedProducts() {
    return _cachedProducts;
  }

  static ProductModel _productFromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final pricesRaw = Map<String, dynamic>.from(data['prices'] ?? {});
    final prices = <String, double>{};

    pricesRaw.forEach((key, value) {
      if (value is int) {
        prices[key] = value.toDouble();
      } else if (value is double) {
        prices[key] = value;
      } else if (value is num) {
        prices[key] = value.toDouble();
      } else {
        prices[key] = double.tryParse(value.toString()) ?? 0;
      }
    });

    final availableVariants =
        (data['availableVariants'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        prices.keys.toList();

    return ProductModel(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      categoryId: _webCategoryFromFirestoreCategory(
        (data['category'] ?? '').toString(),
      ),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      prices: prices,
      availableVariants: availableVariants,
      hasVariants: (data['hasVariants'] ?? false) == true,
      isAvailable: (data['isAvailable'] ?? true) == true,
      isBestSeller: (data['isBestSeller'] ?? false) == true,
      stockQty: _toInt(data['stockQty']),
      displayType: (data['displayType'] ?? 'food').toString(),
      sortOrder: _toInt(data['sortOrder']),
      tags: (data['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  static String _webCategoryFromFirestoreCategory(String category) {
    switch (category) {
      case 'Coffee':
      case "Vian's Special Coffee":
      case 'Non-Coffee':
      case 'Frappe':
        return 'drinks';
      case 'Rice Bowl':
      case 'Pasta':
        return 'meals';
      case 'Café Bites':
      case 'Side Bites':
        return 'snacks';
      case 'Desserts':
        return 'desserts';
      default:
        return 'others';
    }
  }

  static String _displayCategoryName(String id) {
    switch (id) {
      case 'drinks':
        return 'Drinks';
      case 'meals':
        return 'Meals';
      case 'snacks':
        return 'Snacks';
      case 'desserts':
        return 'Desserts';
      case 'others':
        return 'Others';
      default:
        return id;
    }
  }

  static String _iconForCategory(String id) {
    switch (id) {
      case 'drinks':
        return 'local_cafe';
      case 'meals':
        return 'restaurant';
      case 'snacks':
        return 'bakery_dining';
      case 'desserts':
        return 'cake';
      case 'others':
        return 'restaurant_menu';
      default:
        return 'restaurant_menu';
    }
  }

  static int _sortForCategory(String id) {
    switch (id) {
      case 'drinks':
        return 1;
      case 'meals':
        return 2;
      case 'snacks':
        return 3;
      case 'desserts':
        return 4;
      case 'others':
        return 5;
      default:
        return 99;
    }
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}