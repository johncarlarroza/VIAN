import 'package:flutter/material.dart';
import 'package:vian_kopi/screens/pdf_service.dart';

import '../models/cart_item_model.dart';

class OrderSuccessScreen extends StatelessWidget {
  final String orderNumber;
  final String orderType;
  final String customerName;

  // ✅ ADD THESE
  final List<CartItemModel> items;
  final double total;

  const OrderSuccessScreen({
    super.key,
    required this.orderNumber,
    required this.orderType,
    required this.customerName,
    required this.items, // ✅
    required this.total, // ✅
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F6D44),
      body: Center(
        child: Container(
          width: 420,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 16),

              const Text(
                'Order Successful!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),

              const SizedBox(height: 10),

              Text('Order #: $orderNumber'),
              Text(orderType.toUpperCase()),

              const SizedBox(height: 20),

              // ✅ ITEMS LIST
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7F8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: items.map((e) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${e.product.name} x${e.quantity}'),
                        Text('₱${e.subtotal.toStringAsFixed(0)}'),
                      ],
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 14),

              Text(
                'TOTAL: ₱${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 20),

              // 🔥 DOWNLOAD PDF
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    PdfService.generateReceipt(
                      orderNumber: orderNumber,
                      customerName: customerName,
                      items: items,
                      total: total,
                    );
                  },
                  child: const Text('Download Receipt'),
                ),
              ),

              const SizedBox(height: 10),

              TextButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('Back to Menu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
