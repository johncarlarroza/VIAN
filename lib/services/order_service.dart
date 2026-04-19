import 'package:cloud_firestore/cloud_firestore.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> createOrder({
    required String orderType,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
    required int totalItems,
    required double subtotalAmount,
    required double totalAmount,
    String customerName = '',
    String notes = '',
  }) async {
    final now = DateTime.now();
    final queueDate = _formatDate(now);

    final result = await _firestore.runTransaction<Map<String, dynamic>>((
      transaction,
    ) async {
      final counterRef = _firestore.collection('daily_counters').doc(queueDate);

      final counterSnap = await transaction.get(counterRef);

      int lastQueueNumber = 0;
      if (counterSnap.exists) {
        final data = counterSnap.data();
        if (data != null && data['lastQueueNumber'] != null) {
          final value = data['lastQueueNumber'];
          if (value is int) {
            lastQueueNumber = value;
          } else if (value is num) {
            lastQueueNumber = value.toInt();
          }
        }
      }

      final nextQueueNumber = lastQueueNumber + 1;
      final orderNumber = nextQueueNumber.toString().padLeft(3, '0');

      transaction.set(counterRef, {
        'lastQueueNumber': nextQueueNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final orderRef = _firestore.collection('orders').doc();

      transaction.set(orderRef, {
        'orderNumber': orderNumber,
        'queueNumber': nextQueueNumber,
        'queueDate': queueDate,
        'serviceType': orderType,
        'status': 'pending',
        'paymentStatus': paymentMethod == 'cash'
            ? 'unpaid'
            : 'pending_verification',
        'paymentMethod': paymentMethod,
        'customerName': customerName,
        'notes': notes,
        'items': items,
        'totalItems': totalItems,
        'subtotalAmount': subtotalAmount,
        'discountAmount': 0,
        'totalAmount': totalAmount,
        'source': 'kiosk',
        'assignedStaffId': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'completedAt': null,
      });

      return {
        'orderId': orderRef.id,
        'orderNumber': orderNumber,
        'queueNumber': nextQueueNumber,
        'queueDate': queueDate,
        'paymentMethod': paymentMethod,
      };
    });

    return result;
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
