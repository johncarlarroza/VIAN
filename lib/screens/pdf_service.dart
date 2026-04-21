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

    final logoBytes = await rootBundle.load('assets/vianlogo.png');
    final Uint8List logoUint8 = logoBytes.buffer.asUint8List();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ================= LOGO =================
              pw.Center(
                child: pw.Image(
                  pw.MemoryImage(logoUint8),
                  height: 42,
                ),
              ),

              pw.SizedBox(height: 6),

              // ================= STORE NAME =================
              pw.Center(
                child: pw.Text(
                  'VIAN CAFÉ',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              pw.SizedBox(height: 2),

              pw.Center(
                child: pw.Text(
                  'OFFICIAL RECEIPT',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              pw.SizedBox(height: 2),

              pw.Center(
                child: pw.Text(
                  'Thank you for ordering!',
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              ),

              pw.SizedBox(height: 10),

              pw.Container(
                width: double.infinity,
                child: pw.Text(
                  '----------------------------------------',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),

              pw.SizedBox(height: 4),

              // ================= ORDER INFO =================
              _infoRow('Order No', orderNumber),
              _infoRow(
                'Customer',
                customerName.trim().isEmpty ? 'Walk-in Customer' : customerName,
              ),
              _infoRow('Date', _formattedNow()),

              pw.SizedBox(height: 4),

              pw.Container(
                width: double.infinity,
                child: pw.Text(
                  '----------------------------------------',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),

              pw.SizedBox(height: 6),

              // ================= HEADER =================
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 5,
                    child: pw.Text(
                      'ITEM',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      'QTY',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'AMOUNT',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 4),

              pw.Container(
                width: double.infinity,
                child: pw.Text(
                  '----------------------------------------',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),

              pw.SizedBox(height: 6),

              // ================= ITEMS =================
              ...items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 5,
                        child: pw.Text(
                          _itemLabel(item),
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          item.quantity.toString(),
                          style: const pw.TextStyle(fontSize: 9),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          item.subtotal.toStringAsFixed(2),
                          style: const pw.TextStyle(fontSize: 9),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              pw.Container(
                width: double.infinity,
                child: pw.Text(
                  '----------------------------------------',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),

              pw.SizedBox(height: 8),

              // ================= TOTALS =================
              _amountRow('Subtotal', total),
              _amountRow('Discount', 0),
              _amountRow('VAT', 0),

              pw.SizedBox(height: 4),

              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      'TOTAL',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Text(
                    total.toStringAsFixed(2),
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ],
              ),

              pw.SizedBox(height: 8),

              pw.Container(
                width: double.infinity,
                child: pw.Text(
                  '----------------------------------------',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),

              pw.SizedBox(height: 10),

              // ================= FOOTER =================
              pw.Center(
                child: pw.Text(
                  'THIS SERVES AS YOUR OFFICIAL RECEIPT',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),

              pw.SizedBox(height: 6),

              pw.Center(
                child: pw.Text(
                  'Please keep this receipt for reference.',
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              ),

              pw.SizedBox(height: 6),

              pw.Center(
                child: pw.Text(
                  'Thank you and enjoy your meal!',
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 58,
            child: pw.Text(
              '$label:',
              style: const pw.TextStyle(fontSize: 8.5),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 8.5),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _amountRow(String label, double amount) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
          pw.Text(
            amount.toStringAsFixed(2),
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.right,
          ),
        ],
      ),
    );
  }

  static String _formattedNow() {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');

    return '$year-$month-$day $hour:$minute';
  }

  static String _itemLabel(CartItemModel item) {
    final variant = _extractVariant(item);

    if (variant.isEmpty) {
      return item.product.name;
    }

    return '${item.product.name} ($variant)';
  }

  static String _extractVariant(CartItemModel item) {
    try {
      final dynamic selectedSize = (item as dynamic).selectedSize;
      if (selectedSize != null &&
          selectedSize.toString().trim().isNotEmpty &&
          selectedSize.toString().toLowerCase() != 'null') {
        return selectedSize.toString();
      }
    } catch (_) {}

    try {
      final dynamic selectedVariant = (item as dynamic).selectedVariant;
      if (selectedVariant != null &&
          selectedVariant.toString().trim().isNotEmpty &&
          selectedVariant.toString().toLowerCase() != 'null') {
        return selectedVariant.toString();
      }
    } catch (_) {}

    try {
      final dynamic size = (item as dynamic).size;
      if (size != null &&
          size.toString().trim().isNotEmpty &&
          size.toString().toLowerCase() != 'null') {
        return size.toString();
      }
    } catch (_) {}

    try {
      final dynamic variant = (item as dynamic).variant;
      if (variant != null &&
          variant.toString().trim().isNotEmpty &&
          variant.toString().toLowerCase() != 'null') {
        return variant.toString();
      }
    } catch (_) {}

    return '';
  }
}