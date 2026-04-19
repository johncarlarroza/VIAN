import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item_model.dart';

class TransactionService {
  TransactionService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<String> saveTransaction({
    required String customerName,
    required String orderType,
    required String paymentMethod,
    required List<CartItemModel> items,
    required double total,
  }) async {
    final now = DateTime.now();

    final yyyy = now.year.toString();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');

    final day = '$yyyy-$mm-$dd';
    final month = '$yyyy-$mm';
    final year = yyyy;

    final orderNumber =
        'VC-$yyyy$mm$dd-${now.millisecondsSinceEpoch.toString().substring(7)}';

    final totalItems = items.fold<int>(0, (sum, item) => sum + item.quantity);

    final docRef = await _firestore.collection('transactions').add({
      'orderNumber': orderNumber,
      'customerName': customerName.trim().isEmpty
          ? 'Walk-in Customer'
          : customerName.trim(),
      'orderType': orderType,
      'paymentMethod': paymentMethod,
      'paymentStatus': 'paid',
      'status': 'completed',
      'total': total,
      'totalItems': totalItems,
      'items': items.map((item) {
        return {
          'productId': item.product.id,
          'name': item.product.name,
          'variant': item.variant,
          'quantity': item.quantity,
          'unitPrice': item.unitPrice,
          'subtotal': item.subtotal,
          'note': item.note,
        };
      }).toList(),
      'day': day,
      'month': month,
      'year': year,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await docRef.update({'transactionId': docRef.id});

    return orderNumber;
  }
}
