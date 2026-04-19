import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  String _selectedStatus = 'pending';

  final List<String> _statuses = const [
    'pending',
    'preparing',
    'ready',
    'completed',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F3EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF155433),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Orders',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.2),
        ),
      ),
      body: Column(
        children: [
          _buildStatusTabs(),
          Expanded(child: _buildOrdersList()),
        ],
      ),
    );
  }

  Widget _buildStatusTabs() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      color: const Color(0xFFF6F3EB),
      child: Row(
        children: _statuses.map((status) {
          final selected = status == _selectedStatus;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedStatus = status;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF23613E)
                      : const Color(0xFFFBFAF7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF23613E)
                        : const Color(0xFFE5DECF),
                  ),
                ),
                child: Center(
                  child: Text(
                    _prettyStatus(status),
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF435248),
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrdersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: _selectedStatus)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading orders: ${snapshot.error}',
              style: const TextStyle(
                color: Color(0xFF7A7A7A),
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFFFBFAF7),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5DECF)),
              ),
              child: Text(
                'No ${_prettyStatus(_selectedStatus).toLowerCase()} orders.',
                style: const TextStyle(
                  color: Color(0xFF7A7A7A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _OrderCard(orderId: doc.id, data: data);
          },
        );
      },
    );
  }

  String _prettyStatus(String value) {
    switch (value) {
      case 'pending':
        return 'Pending';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready';
      case 'completed':
        return 'Completed';
      default:
        return value;
    }
  }
}

class _OrderCard extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;

  const _OrderCard({required this.orderId, required this.data});

  @override
  Widget build(BuildContext context) {
    final orderNumber = (data['orderNumber'] ?? '').toString();
    final queueNumber = (data['queueNumber'] ?? '').toString();
    final serviceType = (data['serviceType'] ?? '').toString();
    final paymentMethod = (data['paymentMethod'] ?? '').toString();
    final paymentStatus = (data['paymentStatus'] ?? '').toString();
    final customerName = (data['customerName'] ?? '').toString();
    final notes = (data['notes'] ?? '').toString();
    final status = (data['status'] ?? '').toString();
    final totalAmount = _toDouble(data['totalAmount']);
    final items = (data['items'] as List?) ?? [];

    final nextStatus = _nextStatus(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFAF7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5DECF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// header
          Row(
            children: [
              Text(
                '#$orderNumber',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF23613E),
                ),
              ),
              const SizedBox(width: 8),
              _statusChip(status),
              const Spacer(),
              Text(
                'Queue $queueNumber',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6F7A73),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _infoBox(
                  label: 'Order Type',
                  value: serviceType == 'dine_in' ? 'Dine-In' : 'Takeout',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _infoBox(
                  label: 'Payment',
                  value: paymentMethod.isEmpty
                      ? '—'
                      : paymentMethod.toUpperCase(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _infoBox(
                  label: 'Payment Status',
                  value: _prettyPaymentStatus(paymentStatus),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _infoBox(
                  label: 'Customer',
                  value: customerName.trim().isEmpty ? 'Walk-in' : customerName,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          const Text(
            'Items',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF435248),
            ),
          ),

          const SizedBox(height: 8),

          ...items.map((item) {
            final itemMap = item as Map<String, dynamic>;
            final name = (itemMap['name'] ?? '').toString();
            final variant = (itemMap['variant'] ?? '').toString();
            final qty = (itemMap['quantity'] ?? 0).toString();
            final subtotal = _toDouble(itemMap['subtotal']);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F1E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$qty × $name (${_prettyVariant(variant)})',
                      style: const TextStyle(
                        color: Color(0xFF435248),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '₱${subtotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFF23613E),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            );
          }),

          if (notes.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F6F0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5DECF)),
              ),
              child: Text(
                'Notes: $notes',
                style: const TextStyle(
                  color: Color(0xFF6F7A73),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),

          Row(
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF435248),
                ),
              ),
              const Spacer(),
              Text(
                '₱${totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF23613E),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (nextStatus != null)
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _statusColor(nextStatus),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('orders')
                      .doc(orderId)
                      .update({
                        'status': nextStatus,
                        'updatedAt': FieldValue.serverTimestamp(),
                        if (nextStatus == 'completed')
                          'completedAt': FieldValue.serverTimestamp(),
                        if (nextStatus == 'completed' &&
                            paymentMethod == 'cash' &&
                            paymentStatus == 'unpaid')
                          'paymentStatus': 'paid',
                      });
                },
                child: Text(
                  _nextActionLabel(status),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ),

          if (paymentMethod == 'gcash' &&
              paymentStatus == 'pending_verification') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF23613E),
                  side: const BorderSide(color: Color(0xFF23613E)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('orders')
                      .doc(orderId)
                      .update({
                        'paymentStatus': 'paid',
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                },
                child: const Text(
                  'Mark GCash as Paid',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoBox({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF93A294),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF435248),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _statusColor(status).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _prettyStatus(status),
        style: TextStyle(
          color: _statusColor(status),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  String _prettyStatus(String value) {
    switch (value) {
      case 'pending':
        return 'Pending';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready';
      case 'completed':
        return 'Completed';
      default:
        return value;
    }
  }

  String _prettyPaymentStatus(String value) {
    switch (value) {
      case 'unpaid':
        return 'Unpaid';
      case 'paid':
        return 'Paid';
      case 'pending_verification':
        return 'Pending Verification';
      default:
        return value.isEmpty ? '—' : value;
    }
  }

  String _prettyVariant(String value) {
    switch (value) {
      case 'hot':
        return 'Hot';
      case 'iced12':
        return 'Iced 12oz';
      case 'iced16':
        return 'Iced 16oz';
      case 'withDrink':
        return 'with drink';
      case 'withoutDrink':
        return 'without drink';
      case 'slice':
        return 'Slice';
      case 'whole':
        return 'Whole';
      case 'regular':
        return 'Regular';
      default:
        return value.replaceAll('_', ' ');
    }
  }

  String? _nextStatus(String current) {
    switch (current) {
      case 'pending':
        return 'preparing';
      case 'preparing':
        return 'ready';
      case 'ready':
        return 'completed';
      default:
        return null;
    }
  }

  String _nextActionLabel(String current) {
    switch (current) {
      case 'pending':
        return 'Accept & Start Preparing';
      case 'preparing':
        return 'Mark as Ready';
      case 'ready':
        return 'Complete Order';
      default:
        return 'Done';
    }
  }

  Color _statusColor(String value) {
    switch (value) {
      case 'pending':
        return const Color(0xFFD97706);
      case 'preparing':
        return const Color(0xFF2563EB);
      case 'ready':
        return const Color(0xFF16A34A);
      case 'completed':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF23613E);
    }
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
