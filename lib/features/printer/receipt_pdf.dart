import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../database/models.dart';
import '../../core/helpers/formatters.dart' as fmt;
import '../../core/helpers/preferences_helper.dart';

class ReceiptPdf {
  static Future<Uint8List> generate({
    required Transaction transaction,
    required List<TransactionItem> items,
  }) async {
    final pdf = pw.Document();

    final storeName = await PreferencesHelper.getStoreName();
    final storeAddress = await PreferencesHelper.getStoreAddress();
    final storePhone = await PreferencesHelper.getStorePhone();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(8),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text(
              storeName,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            if (storeAddress.isNotEmpty)
              pw.Text(
                storeAddress,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 10),
              ),
            if (storePhone.isNotEmpty && storePhone != '-')
              pw.Text(
                storePhone,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 10),
              ),
            pw.SizedBox(height: 4),
            pw.Text(
              'No: ${transaction.invoiceNumber}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              fmt.Formatters.dateTime(transaction.createdAt),
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Divider(),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headers: ['Barang', 'Qty', 'Harga', 'Subtotal'],
              data: items
                  .map(
                    (item) => [
                      item.productName,
                      '${item.qty}',
                      fmt.Formatters.rupiah(item.sellingPrice),
                      fmt.Formatters.rupiah(item.sellingPrice * item.qty),
                    ],
                  )
                  .toList(),
            ),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  fmt.Formatters.rupiah(transaction.subtotal),
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Tunai', style: const pw.TextStyle(fontSize: 10)),
                pw.Text(
                  fmt.Formatters.rupiah(transaction.payment),
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Kembali', style: const pw.TextStyle(fontSize: 10)),
                pw.Text(
                  fmt.Formatters.rupiah(transaction.changeAmount),
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Terima kasih atas kunjungan Anda',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static Future<void> share({
    required Transaction transaction,
    required List<TransactionItem> items,
  }) async {
    final pdfBytes = await generate(transaction: transaction, items: items);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'struk_${transaction.invoiceNumber}.pdf',
    );
  }
}
