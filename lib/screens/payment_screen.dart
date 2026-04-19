import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item_model.dart';
import '../providers/cart_provider.dart';
import 'order_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String orderType;

  const PaymentScreen({super.key, required this.orderType});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPayment = 'cash';

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Payment'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _summaryCard(cart),
            const SizedBox(height: 20),

            _paymentOption(Icons.money, 'Cash', 'cash'),
            _paymentOption(Icons.qr_code, 'GCash', 'gcash'),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: cart.itemList.isEmpty
                    ? null
                    : () {
                        if (_selectedPayment == 'gcash') {
                          _showGcashQR(context, cart);
                        } else {
                          _completePayment(context, cart);
                        }
                      },
                child: Text(
                  'PAY ₱${cart.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 10),
          ...cart.itemList.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${item.product.name} x${item.quantity}'),
                  ),
                  Text('₱${item.subtotal.toStringAsFixed(0)}'),
                ],
              ),
            );
          }),
          const Divider(),
          Row(
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '₱${cart.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F6D44),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentOption(IconData icon, String label, String value) {
    final selected = _selectedPayment == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPayment = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE9F5EC) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF1F6D44) : const Color(0xFFEAEAEA),
          ),
        ),
        child: ListTile(
          leading: Icon(icon),
          title: Text(label),
          trailing: selected
              ? const Icon(Icons.check_circle, color: Color(0xFF1F6D44))
              : null,
        ),
      ),
    );
  }

  void _showGcashQR(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Scan GCash QR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/qr.png',
              height: 200,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.qr_code, size: 100),
            ),
            const SizedBox(height: 10),
            Text('Amount: ₱${cart.totalAmount.toStringAsFixed(0)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completePayment(context, cart);
            },
            child: const Text('I Paid'),
          ),
        ],
      ),
    );
  }

  void _completePayment(BuildContext context, CartProvider cart) {
    final List<CartItemModel> orderedItems = List<CartItemModel>.from(
      cart.itemList,
    );
    final double orderedTotal = cart.totalAmount;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OrderSuccessScreen(
          orderNumber: DateTime.now().millisecondsSinceEpoch
              .toString()
              .substring(7),
          orderType: widget.orderType,
          customerName: 'Customer',
          items: orderedItems,
          total: orderedTotal,
        ),
      ),
    );

    context.read<CartProvider>().clearCart();
  }
}
