import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  final String variant;
  final int quantity;
  final double unitPrice;
  final String note;

  const CartItemModel({
    required this.product,
    required this.variant,
    required this.quantity,
    required this.unitPrice,
    this.note = '',
  });

  double get subtotal => unitPrice * quantity;

  String get cartKey => '${product.id}_$variant';

  CartItemModel copyWith({
    ProductModel? product,
    String? variant,
    int? quantity,
    double? unitPrice,
    String? note,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      variant: variant ?? this.variant,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toOrderMap() {
    return {
      'productId': product.id,
      'name': product.name,
      'variant': variant,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'subtotal': subtotal,
      'imageUrl': product.imageUrl,
      'note': note,
    };
  }
}
