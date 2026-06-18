import 'package:uuid/uuid.dart';

import 'db_helper.dart';
import 'models.dart';

class ProductRepository {
  final Uuid _uuid = const Uuid();

  Future<List<Product>> getAll({String? query, String? categoryId}) async {
    final db = await DbHelper.database;

    final where = <String>['deleted_at IS NULL'];
    final args = <Object?>[];

    if (query != null && query.isNotEmpty) {
      where.add('name LIKE ?');
      args.add('%$query%');
    }
    if (categoryId != null) {
      where.add('category_id = ?');
      args.add(categoryId);
    }

    final rows = await db.query(
      'products',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'name ASC',
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<Product?> getById(String id) async {
    final db = await DbHelper.database;
    final rows = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  Future<Product> create({
    required String name,
    required double costPrice,
    required double sellingPrice,
    required String categoryId,
    int stock = 0,
    String? unit,
  }) async {
    final db = await DbHelper.database;
    final now = DateTime.now();
    final product = Product(
      id: _uuid.v4(),
      name: name,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      stock: stock,
      unit: unit,
      categoryId: categoryId,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('products', product.toMap());
    return product;
  }

  Future<Product> update({
    required String id,
    required String name,
    required double costPrice,
    required double sellingPrice,
    required String categoryId,
    String? unit,
  }) async {
    final db = await DbHelper.database;
    final now = DateTime.now();

    await db.update(
      'products',
      {
        'name': name,
        'cost_price': costPrice,
        'selling_price': sellingPrice,
        'unit': unit,
        'category_id': categoryId,
        'updated_at': now.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    return (await getById(id))!;
  }

  Future<void> softDelete(String id) async {
    final db = await DbHelper.database;
    final now = DateTime.now();
    await db.update(
      'products',
      {
        'deleted_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Product> updateStock(String id, int newStock) async {
    final db = await DbHelper.database;
    final now = DateTime.now();
    await db.update(
      'products',
      {
        'stock': newStock,
        'updated_at': now.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return (await getById(id))!;
  }

  Future<int> getActiveProductCount() async {
    final db = await DbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM products WHERE deleted_at IS NULL',
    );
    return result.first['cnt'] as int;
  }
}
