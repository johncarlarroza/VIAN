import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/cart_item_model.dart';

class PdfService {
  static Future<void> generateReceipt({
    required String orderNumber,
    required String customerName,
    required List<CartItemModel> items,
    required double total,
  }) async {
    final pdf = pw.Document();

    // 🔥 LOAD LOGO
    final logoBytes = await rootBundle.load('assets/vianlogo.png');
    final Uint8List logoUint8 = logoBytes.buffer.asUint8List();

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // ================= LOGO =================
              pw.Image(pw.MemoryImage(logoUint8), height: 60),

              pw.SizedBox(height: 8),

              pw.Text(
                'VIAN CAFÉ',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.Text(
                'Official Receipt',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),

              pw.SizedBox(height: 12),

              pw.Divider(),

              // ================= INFO =================
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [pw.Text('Order #:'), pw.Text(orderNumber)],
              ),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [pw.Text('Customer:'), pw.Text(customerName)],
              ),

              pw.SizedBox(height: 8),

              pw.Divider(),

              // ================= ITEMS =================
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  'Items',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),

              pw.SizedBox(height: 6),

              ...items.map(
                (item) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          '${item.quantity}x ${item.product.name}',
                        ),
                      ),
                      pw.Text('₱${item.subtotal.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ),

              pw.SizedBox(height: 8),
              pw.Divider(),

              // ================= TOTAL =================
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  pw.Text(
                    '₱${total.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              pw.Text(
                'Thank you for your order!',
                style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
