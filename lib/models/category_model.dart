class CategoryModel {
  final String id;
  final String name;
  final String iconName;
  final bool isActive;
  final int sortOrder;
  final String imageUrl;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
    this.isActive = true,
    this.sortOrder = 0,
    this.imageUrl = '',
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      iconName: (map['iconName'] ?? '').toString(),
      isActive: map['isActive'] ?? true,
      sortOrder: (map['sortOrder'] ?? 0) is int
          ? (map['sortOrder'] ?? 0) as int
          : int.tryParse(map['sortOrder'].toString()) ?? 0,
      imageUrl: (map['imageUrl'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'imageUrl': imageUrl,
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? iconName,
    bool? isActive,
    int? sortOrder,
    String? imageUrl,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
