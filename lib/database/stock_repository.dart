import 'package:uuid/uuid.dart';

import 'db_helper.dart';
import 'models.dart';
import 'product_repository.dart';

class StockRepository {
  final Uuid _uuid = const Uuid();
  final ProductRepository _productRepo = ProductRepository();

  Future<List<StockHistory>> getHistory(String productId) async {
    final db = await DbHelper.database;
    final rows = await db.query(
      'stock_histories',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'created_at DESC',
    );
    return rows.map(StockHistory.fromMap).toList();
  }

  Future<StockHistory> addStock({
    required String productId,
    required int qty,
    String? note,
    StockHistoryType type = StockHistoryType.stockIn,
  }) async {
    final db = await DbHelper.database;
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    final history = StockHistory(
      id: _uuid.v4(),
      productId: productId,
      qty: qty,
      type: type,
      note: note,
      createdAt: now,
    );

    await db.transaction((txn) async {
      final productRows = await txn.query(
        'products',
        columns: ['stock'],
        where: 'id = ?',
        whereArgs: [productId],
      );
      if (productRows.isEmpty) {
        throw Exception('Product not found');
      }
      final currentStock = productRows.first['stock'] as int;
      final newStock = type == StockHistoryType.stockOut
          ? currentStock - qty.abs()
          : currentStock + qty;

      await txn.insert('stock_histories', history.toMap());
      await txn.update(
        'products',
        {'stock': newStock, 'updated_at': nowMs},
        where: 'id = ?',
        whereArgs: [productId],
      );
    });

    return history;
  }

  Future<StockHistory> adjustStock({
    required String productId,
    required int newQty,
    String? note,
  }) async {
    final db = await DbHelper.database;
    final product = await _productRepo.getById(productId);
    if (product == null) throw Exception('Product not found');

    final diff = newQty - product.stock;
    final now = DateTime.now();
    final history = StockHistory(
      id: _uuid.v4(),
      productId: productId,
      qty: diff,
      type: StockHistoryType.adjustment,
      note: note,
      createdAt: now,
    );

    await db.transaction((txn) async {
      await txn.insert('stock_histories', history.toMap());
      await txn.update(
        'products',
        {'stock': newQty, 'updated_at': now.millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [productId],
      );
    });

    return history;
  }
}
