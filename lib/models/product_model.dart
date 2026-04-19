class ProductModel {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final String imageUrl;
  final Map<String, double> prices;
  final List<String> availableVariants;
  final bool hasVariants;
  final bool isAvailable;
  final bool isBestSeller;
  final int stockQty;
  final String displayType;
  final int sortOrder;
  final List<String> tags;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    this.imageUrl = '',
    required this.prices,
    required this.availableVariants,
    required this.hasVariants,
    this.isAvailable = true,
    this.isBestSeller = false,
    this.stockQty = 999,
    this.displayType = 'general',
    this.sortOrder = 0,
    this.tags = const [],
  });

  double get basePrice {
    if (prices.isEmpty) return 0;
    return prices.values.first;
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    final rawPrices = (map['prices'] as Map<String, dynamic>? ?? {});
    final parsedPrices = rawPrices.map(
      (key, value) => MapEntry(
        key,
        value is num
            ? value.toDouble()
            : double.tryParse(value.toString()) ?? 0,
      ),
    );

    final rawVariants = (map['availableVariants'] as List<dynamic>? ?? []);
    final rawTags = (map['tags'] as List<dynamic>? ?? []);

    return ProductModel(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      categoryId: (map['categoryId'] ?? '').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      prices: parsedPrices,
      availableVariants: rawVariants.map((e) => e.toString()).toList(),
      hasVariants: map['hasVariants'] ?? false,
      isAvailable: map['isAvailable'] ?? true,
      isBestSeller: map['isBestSeller'] ?? false,
      stockQty: (map['stockQty'] ?? 999) is int
          ? (map['stockQty'] ?? 999) as int
          : int.tryParse(map['stockQty'].toString()) ?? 999,
      displayType: (map['displayType'] ?? 'general').toString(),
      sortOrder: (map['sortOrder'] ?? 0) is int
          ? (map['sortOrder'] ?? 0) as int
          : int.tryParse(map['sortOrder'].toString()) ?? 0,
      tags: rawTags.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'imageUrl': imageUrl,
      'prices': prices,
      'availableVariants': availableVariants,
      'hasVariants': hasVariants,
      'isAvailable': isAvailable,
      'isBestSeller': isBestSeller,
      'stockQty': stockQty,
      'displayType': displayType,
      'sortOrder': sortOrder,
      'tags': tags,
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    String? categoryId,
    String? imageUrl,
    Map<String, double>? prices,
    List<String>? availableVariants,
    bool? hasVariants,
    bool? isAvailable,
    bool? isBestSeller,
    int? stockQty,
    String? displayType,
    int? sortOrder,
    List<String>? tags,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      imageUrl: imageUrl ?? this.imageUrl,
      prices: prices ?? this.prices,
      availableVariants: availableVariants ?? this.availableVariants,
      hasVariants: hasVariants ?? this.hasVariants,
      isAvailable: isAvailable ?? this.isAvailable,
      isBestSeller: isBestSeller ?? this.isBestSeller,
      stockQty: stockQty ?? this.stockQty,
      displayType: displayType ?? this.displayType,
      sortOrder: sortOrder ?? this.sortOrder,
      tags: tags ?? this.tags,
    );
  }
}
