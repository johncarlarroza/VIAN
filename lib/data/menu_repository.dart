import '../models/category_model.dart';
import '../models/product_model.dart';
import 'app_categories.dart';
import 'app_products.dart';

class MenuRepository {
  static List<CategoryModel> getCategories() {
    final items = [...appCategories];
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items.where((e) => e.isActive).toList();
  }

  static List<ProductModel> getAllProducts() {
    final items = [...appProducts];
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items.where((e) => e.isAvailable).toList();
  }

  static List<ProductModel> getProductsByCategory(String categoryId) {
    if (categoryId == 'best_sellers') {
      final items = appProducts
          .where((e) => e.isAvailable && e.isBestSeller)
          .toList();
      items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return items;
    }

    final items = appProducts
        .where((e) => e.isAvailable && e.categoryId == categoryId)
        .toList();
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
  }

  static List<ProductModel> searchProducts(String keyword) {
    final query = keyword.trim().toLowerCase();
    if (query.isEmpty) return getAllProducts();

    return appProducts.where((product) {
      final haystack = [
        product.name,
        product.description,
        product.categoryId,
        ...product.tags,
      ].join(' ').toLowerCase();

      return product.isAvailable && haystack.contains(query);
    }).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }
}
