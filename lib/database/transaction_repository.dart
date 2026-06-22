import 'package:uuid/uuid.dart';

import 'db_helper.dart';
import 'models.dart';

class CartItemForCheckout {
  final String productId;
  final int qty;

  const CartItemForCheckout({required this.productId, required this.qty});
}

class TransactionRepository {
  final Uuid _uuid = const Uuid();

  Future<int> getTodaySequence() async {
    final db = await DbHelper.database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM transactions WHERE created_at >= ? AND created_at < ?',
      [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    return (result.first['cnt'] as int) + 1;
  }

  Future<Transaction> save({
    required String id,
    required String invoiceNumber,
    required double subtotal,
    double discount = 0,
    required double payment,
    required double changeAmount,
    required double totalProfit,
    required List<TransactionItem> items,
  }) async {
    final db = await DbHelper.database;
    final transaction = Transaction(
      id: id,
      invoiceNumber: invoiceNumber,
      subtotal: subtotal,
      discount: discount,
      payment: payment,
      changeAmount: changeAmount,
      totalProfit: totalProfit,
      createdAt: DateTime.now(),
    );

    await db.transaction((txn) async {
      await txn.insert('transactions', transaction.toMap());
      for (final item in items) {
        await txn.insert('transaction_items', item.toMap());
      }
    });

    return transaction;
  }

  Future<List<Transaction>> getAll({
    int? limit,
    int? offset,
    DateTime? start,
    DateTime? end,
  }) async {
    final db = await DbHelper.database;
    String? whereClause;
    List<dynamic>? whereArgs;

    if (start != null && end != null) {
      whereClause = 'created_at >= ? AND created_at < ?';
      whereArgs = [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch];
    }

    final rows = await db.query(
      'transactions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(Transaction.fromMap).toList();
  }

  Future<Transaction?> getById(String id) async {
    final db = await DbHelper.database;
    final rows = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return Transaction.fromMap(rows.first);
  }

  Future<List<TransactionItem>> getItems(String transactionId) async {
    final db = await DbHelper.database;
    final rows = await db.query(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
      orderBy: 'id ASC',
    );
    return rows.map(TransactionItem.fromMap).toList();
  }

  Future<double> getTodayRevenue() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return getRevenue(start: start, end: end);
  }

  Future<double> getTodayProfit() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return getProfit(start: start, end: end);
  }

  Future<int> getTodayTransactionCount() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return getTransactionCount(start: start, end: end);
  }

  Future<double> getRevenue({
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await DbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(subtotal),0) as total FROM transactions WHERE created_at >= ? AND created_at < ?',
      [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<double> getProfit({
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await DbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(total_profit),0) as total FROM transactions WHERE created_at >= ? AND created_at < ?',
      [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<int> getTransactionCount({
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await DbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM transactions WHERE created_at >= ? AND created_at < ?',
      [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    return result.first['cnt'] as int;
  }

  Future<List<TopProduct>> getTopProducts({
    DateTime? start,
    DateTime? end,
    int limit = 5,
  }) async {
    final db = await DbHelper.database;
    if (start != null && end != null) {
      final rows = await db.rawQuery(
        'SELECT ti.product_id, ti.product_name, SUM(ti.qty) as total_qty, SUM(ti.profit) as total_profit '
        'FROM transaction_items ti '
        'INNER JOIN transactions t ON ti.transaction_id = t.id '
        'WHERE t.created_at >= ? AND t.created_at < ? '
        'GROUP BY ti.product_id, ti.product_name '
        'ORDER BY total_qty DESC LIMIT ?',
        [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch, limit],
      );
      return rows
          .map((r) => TopProduct(
                productName: r['product_name'] as String,
                totalQty: r['total_qty'] as int,
                totalProfit: (r['total_profit'] as num).toDouble(),
              ))
          .toList();
    }
    final rows = await db.rawQuery(
      'SELECT product_id, product_name, SUM(qty) as total_qty, SUM(profit) as total_profit FROM transaction_items GROUP BY product_id, product_name ORDER BY total_qty DESC LIMIT ?',
      [limit],
    );
    return rows
        .map((r) => TopProduct(
              productName: r['product_name'] as String,
              totalQty: r['total_qty'] as int,
              totalProfit: (r['total_profit'] as num).toDouble(),
            ))
        .toList();
  }

  Future<Transaction> checkoutAll({
    required String transactionId,
    required String invoiceNumber,
    required double subtotal,
    required double discount,
    required double payment,
    required double changeAmount,
    required double totalProfit,
    required List<TransactionItem> items,
    required List<CartItemForCheckout> cart,
  }) async {
    final db = await DbHelper.database;
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    final transaction = Transaction(
      id: transactionId,
      invoiceNumber: invoiceNumber,
      subtotal: subtotal,
      discount: discount,
      payment: payment,
      changeAmount: changeAmount,
      totalProfit: totalProfit,
      createdAt: now,
    );

    await db.transaction((txn) async {
      await txn.insert('transactions', transaction.toMap());

      for (final item in items) {
        await txn.insert('transaction_items', item.toMap());
      }

      for (final c in cart) {
        final productRows = await txn.query(
          'products',
          columns: ['stock'],
          where: 'id = ?',
          whereArgs: [c.productId],
        );
        if (productRows.isEmpty) continue;
        final currentStock = productRows.first['stock'] as int;
        final newStock = currentStock - c.qty;

        await txn.update(
          'products',
          {'stock': newStock, 'updated_at': nowMs},
          where: 'id = ?',
          whereArgs: [c.productId],
        );

        await txn.insert('stock_histories', {
          'id': _uuid.v4(),
          'product_id': c.productId,
          'qty': c.qty,
          'type': 'OUT',
          'note': 'Transaksi $invoiceNumber',
          'created_at': nowMs,
        });
      }
    });

    return transaction;
  }

  /// Ambil semua transaksi beserta item-itemnya dalam rentang tanggal tertentu
  Future<List<Map<String, dynamic>>> getAllWithItems({
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await DbHelper.database;
    final rows = await db.rawQuery('''
      SELECT
        t.id            AS tx_id,
        t.invoice_number,
        t.subtotal,
        t.discount,
        t.payment,
        t.change_amount,
        t.total_profit,
        t.created_at    AS tx_created_at,
        ti.product_name,
        ti.qty,
        ti.selling_price,
        ti.cost_price,
        ti.profit       AS item_profit
      FROM transactions t
      LEFT JOIN transaction_items ti ON ti.transaction_id = t.id
      WHERE t.created_at >= ? AND t.created_at < ?
      ORDER BY t.created_at ASC, ti.id ASC
    ''', [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch]);
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<void> deleteAll() async {
    final db = await DbHelper.database;
    await db.transaction((txn) async {
      // Delete child first to avoid FK constraint issues (though CASCADE is ON, it's safer)
      await txn.delete('transaction_items');
      await txn.delete('transactions');
    });
  }
}
