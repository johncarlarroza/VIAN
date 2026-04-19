import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item_model.dart';
import '../providers/cart_provider.dart';
import '../services/transaction_service.dart';
import 'order_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String orderType;
  final String customerName;

  const PaymentScreen({
    super.key,
    required this.orderType,
    this.customerName = 'Walk-in Customer',
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPayment = 'cash';
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: const Text('Payment'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2A24),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildOrderInfoCard(),
                  const SizedBox(height: 16),
                  _summaryCard(cart),
                  const SizedBox(height: 20),

                  _paymentOption(Icons.money_rounded, 'Cash', 'cash'),
                  _paymentOption(Icons.qr_code_rounded, 'GCash', 'gcash'),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: cart.itemList.isEmpty || _isSubmitting
                          ? null
                          : () async {
                              if (_selectedPayment == 'gcash') {
                                _showGcashQR(context, cart);
                              } else {
                                await _completePayment(context, cart);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F6D44),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
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
          ),
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAEAEA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F5EC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFF1F6D44),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.customerName.trim().isEmpty
                      ? 'Walk-in Customer'
                      : widget.customerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F2A24),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.orderType == 'dine_in'
                      ? 'Dine-In Order'
                      : 'Takeout Order',
                  style: const TextStyle(
                    color: Color(0xFF6E7A74),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(CartProvider cart) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAEAEA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Color(0xFF1F2A24),
            ),
          ),
          const SizedBox(height: 12),
          ...cart.itemList.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.product.name} x${item.quantity}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2A312D),
                      ),
                    ),
                  ),
                  Text(
                    '₱${item.subtotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2A312D),
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 22),
          Row(
            children: [
              const Text(
                'Items',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6E7A74),
                ),
              ),
              const Spacer(),
              Text(
                '${cart.totalItems}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2A312D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Color(0xFF1F2A24),
                ),
              ),
              const Spacer(),
              Text(
                '₱${cart.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F6D44),
                  fontSize: 18,
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE9F5EC) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF1F6D44) : const Color(0xFFEAEAEA),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ListTile(
          leading: Icon(icon, color: const Color(0xFF1F6D44)),
          title: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            value == 'cash'
                ? 'Pay directly at the counter'
                : 'Scan QR to complete payment',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF6E7A74),
            ),
          ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Scan GCash QR',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/qr.png',
              height: 220,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.qr_code_rounded, size: 100),
            ),
            const SizedBox(height: 12),
            Text(
              'Amount: ₱${cart.totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 8),
            const Text(
              'After payment, tap "I Paid" to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6E7A74),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () async {
                    Navigator.pop(context);
                    await _completePayment(context, cart);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F6D44),
              foregroundColor: Colors.white,
            ),
            child: const Text('I Paid'),
          ),
        ],
      ),
    );
  }

  Future<void> _completePayment(BuildContext context, CartProvider cart) async {
    if (cart.itemList.isEmpty || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final List<CartItemModel> orderedItems = List<CartItemModel>.from(
        cart.itemList,
      );
      final double orderedTotal = cart.totalAmount;

      final String orderNumber = await TransactionService.saveTransaction(
        customerName: widget.customerName,
        orderType: widget.orderType,
        paymentMethod: _selectedPayment,
        items: orderedItems,
        total: orderedTotal,
      );

      if (!mounted) return;

      context.read<CartProvider>().clearCart();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(
            orderNumber: orderNumber,
            orderType: widget.orderType,
            customerName: widget.customerName,
            items: orderedItems,
            total: orderedTotal,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save transaction: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
