import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../database/models.dart';
import '../../database/transaction_repository.dart';

class ExcelExportService {
  ExcelExportService._();

  static final _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  static final _dtFormat = DateFormat('dd/MM/yyyy HH:mm', 'id_ID');
  static final _monthFormat = DateFormat('MMMM yyyy', 'id_ID');
  static final _fileMonthFormat = DateFormat('yyyy-MM', 'id_ID');

  /// Export laporan bulan tertentu ke file .xlsx lalu share.
  static Future<void> exportMonthly({
    required TransactionRepository repo,
    required String storeName,
    required DateTime month,
  }) async {
    // Rentang bulan
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    // Ambil data dari DB
    final rows = await repo.getAllWithItems(start: start, end: end);
    final topProducts = await repo.getTopProducts(start: start, end: end, limit: 20);
    final revenue = await repo.getRevenue(start: start, end: end);
    final profit = await repo.getProfit(start: start, end: end);
    final txCount = await repo.getTransactionCount(start: start, end: end);

    final excel = Excel.createExcel();

    // ── Sheet 1: Ringkasan ────────────────────────────────────────────────────
    final summarySheet = excel['Ringkasan'];
    excel.setDefaultSheet('Ringkasan');

    _addSummarySheet(
      sheet: summarySheet,
      storeName: storeName,
      month: month,
      revenue: revenue,
      profit: profit,
      txCount: txCount,
      start: start,
      end: end,
    );

    // ── Sheet 2: Riwayat Transaksi ────────────────────────────────────────────
    final txSheet = excel['Riwayat Transaksi'];
    _addTransactionSheet(sheet: txSheet, rows: rows);

    // ── Sheet 3: Produk Terlaris ──────────────────────────────────────────────
    final productSheet = excel['Produk Terlaris'];
    _addTopProductSheet(sheet: productSheet, topProducts: topProducts);

    // Hapus sheet default "Sheet1" jika ada
    excel.delete('Sheet1');

    // Simpan ke file sementara
    final dir = await getTemporaryDirectory();
    final fileName =
        '${storeName.replaceAll(' ', '_')}_Laporan_${_fileMonthFormat.format(month)}.xlsx';
    final file = File('${dir.path}/$fileName');
    final bytes = excel.encode();
    if (bytes == null) throw Exception('Gagal menyusun file Excel');
    await file.writeAsBytes(bytes);

    // Share / Save ke Downloads
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
      subject: 'Laporan ${_monthFormat.format(month)} – $storeName',
    );
  }

  // ── Helper: Sheet Ringkasan ─────────────────────────────────────────────────
  static void _addSummarySheet({
    required Sheet sheet,
    required String storeName,
    required DateTime month,
    required double revenue,
    required double profit,
    required int txCount,
    required DateTime start,
    required DateTime end,
  }) {
    final titleStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.fromHexString('#1E3A5F'),
    );
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1E3A5F'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );
    final labelStyle = CellStyle(bold: true);
    final valueStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#F0F4F8'),
    );

    // Judul
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(storeName);
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = titleStyle;

    sheet.cell(CellIndex.indexByString('A2')).value =
        TextCellValue('Laporan Bulanan – ${_monthFormat.format(month)}');

    sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue(
      'Periode: ${DateFormat('dd MMM yyyy', 'id_ID').format(start)} s/d ${DateFormat('dd MMM yyyy', 'id_ID').format(end.subtract(const Duration(seconds: 1)))}',
    );

    // Spacer
    sheet.appendRow([]);

    // Header tabel ringkasan
    final headerRow = ['Keterangan', 'Nilai'];
    sheet.appendRow(headerRow.map((h) => TextCellValue(h)).toList());
    final headerRowIdx = sheet.maxRows - 1;
    for (int c = 0; c < headerRow.length; c++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: headerRowIdx))
          .cellStyle = headerStyle;
    }

    // Data ringkasan
    final summaryData = [
      ['Total Transaksi', '$txCount transaksi'],
      ['Total Omzet', _rupiah.format(revenue)],
      ['Total Laba Kotor', _rupiah.format(profit)],
      ['Rata-rata Omzet/Hari', _rupiah.format(revenue / _daysInRange(start, end))],
    ];

    for (final row in summaryData) {
      sheet.appendRow(row.map((v) => TextCellValue(v)).toList());
      final rowIdx = sheet.maxRows - 1;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx)).cellStyle =
          labelStyle;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx)).cellStyle =
          valueStyle;
    }

    // Lebar kolom
    sheet.setColumnWidth(0, 30);
    sheet.setColumnWidth(1, 25);
  }

  // ── Helper: Sheet Riwayat Transaksi ─────────────────────────────────────────
  static void _addTransactionSheet({
    required Sheet sheet,
    required List<Map<String, dynamic>> rows,
  }) {
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1E3A5F'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );

    final headers = [
      'No. Invoice',
      'Tanggal & Waktu',
      'Nama Produk',
      'Qty',
      'Harga Jual',
      'Harga Modal',
      'Laba Item',
      'Total Transaksi',
      'Bayar',
      'Kembalian',
      'Total Laba Transaksi',
    ];

    // Header row
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
    final headerIdx = sheet.maxRows - 1;
    for (int c = 0; c < headers.length; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: headerIdx)).cellStyle =
          headerStyle;
    }

    // Baris data
    for (final row in rows) {
      final createdAt = DateTime.fromMillisecondsSinceEpoch(row['tx_created_at'] as int);
      sheet.appendRow([
        TextCellValue(row['invoice_number']?.toString() ?? ''),
        TextCellValue(_dtFormat.format(createdAt)),
        TextCellValue(row['product_name']?.toString() ?? ''),
        IntCellValue((row['qty'] as int?) ?? 0),
        DoubleCellValue((row['selling_price'] as num?)?.toDouble() ?? 0),
        DoubleCellValue((row['cost_price'] as num?)?.toDouble() ?? 0),
        DoubleCellValue((row['item_profit'] as num?)?.toDouble() ?? 0),
        DoubleCellValue((row['subtotal'] as num?)?.toDouble() ?? 0),
        DoubleCellValue((row['payment'] as num?)?.toDouble() ?? 0),
        DoubleCellValue((row['change_amount'] as num?)?.toDouble() ?? 0),
        DoubleCellValue((row['total_profit'] as num?)?.toDouble() ?? 0),
      ]);
    }

    // Lebar kolom
    final widths = [20.0, 20.0, 25.0, 8.0, 15.0, 15.0, 15.0, 18.0, 15.0, 15.0, 22.0];
    for (int i = 0; i < widths.length; i++) {
      sheet.setColumnWidth(i, widths[i]);
    }
  }

  // ── Helper: Sheet Produk Terlaris ───────────────────────────────────────────
  static void _addTopProductSheet({
    required Sheet sheet,
    required List<TopProduct> topProducts,
  }) {
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1E3A5F'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );

    final headers = ['Peringkat', 'Nama Produk', 'Qty Terjual', 'Total Pendapatan', 'Total Laba'];
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
    final headerIdx = sheet.maxRows - 1;
    for (int c = 0; c < headers.length; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: headerIdx)).cellStyle =
          headerStyle;
    }

    for (int i = 0; i < topProducts.length; i++) {
      final p = topProducts[i];
      final revenue = p.totalQty * (p.totalProfit / (p.totalQty == 0 ? 1 : 1));
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(p.productName),
        IntCellValue(p.totalQty),
        DoubleCellValue(revenue),
        DoubleCellValue(p.totalProfit),
      ]);
    }

    sheet.setColumnWidth(0, 12);
    sheet.setColumnWidth(1, 30);
    sheet.setColumnWidth(2, 15);
    sheet.setColumnWidth(3, 20);
    sheet.setColumnWidth(4, 15);
  }

  static int _daysInRange(DateTime start, DateTime end) {
    final diff = end.difference(start).inDays;
    return diff == 0 ? 1 : diff;
  }
}
