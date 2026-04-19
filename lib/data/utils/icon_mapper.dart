import 'package:flutter/material.dart';

IconData getIconFromName(String iconName) {
  switch (iconName) {
    case 'star':
      return Icons.star_rounded;
    case 'local_cafe':
      return Icons.local_cafe_rounded;
    case 'restaurant':
      return Icons.restaurant_rounded;
    case 'bakery_dining':
      return Icons.bakery_dining_rounded;
    case 'cake':
      return Icons.cake_rounded;
    default:
      return Icons.category_rounded;
  }
}
