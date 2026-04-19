import '../models/category_model.dart';

const List<CategoryModel> appCategories = [
  CategoryModel(
    id: 'best_sellers',
    name: 'Best Sellers',
    iconName: 'star',
    sortOrder: 0,
  ),
  CategoryModel(
    id: 'drinks',
    name: 'Drinks',
    iconName: 'local_cafe',
    sortOrder: 1,
  ),
  CategoryModel(
    id: 'meals',
    name: 'Meals',
    iconName: 'restaurant',
    sortOrder: 2,
  ),
  CategoryModel(
    id: 'snacks',
    name: 'Snacks',
    iconName: 'bakery_dining',
    sortOrder: 3,
  ),
  CategoryModel(
    id: 'desserts',
    name: 'Desserts',
    iconName: 'cake',
    sortOrder: 4,
  ),
];
