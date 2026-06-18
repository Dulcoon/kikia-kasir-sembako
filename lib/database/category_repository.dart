import 'package:uuid/uuid.dart';

import 'db_helper.dart';
import 'models.dart';

class CategoryRepository {
  final Uuid _uuid = const Uuid();

  Future<List<Category>> getAll() async {
    final db = await DbHelper.database;
    final rows = await db.query(
      'categories',
      where: 'deleted_at IS NULL',
      orderBy: 'name ASC',
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<Category?> getById(String id) async {
    final db = await DbHelper.database;
    final rows = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return Category.fromMap(rows.first);
  }

  Future<Category> create({required String name}) async {
    final db = await DbHelper.database;
    final now = DateTime.now();
    final category = Category(
      id: _uuid.v4(),
      name: name,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert('categories', category.toMap());
    return category;
  }

  Future<Category> update({required String id, required String name}) async {
    final db = await DbHelper.database;
    final now = DateTime.now();
    await db.update(
      'categories',
      {
        'name': name,
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
      'categories',
      {
        'deleted_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> countProducts(String categoryId) async {
    final db = await DbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM products WHERE category_id = ? AND deleted_at IS NULL',
      [categoryId],
    );
    return result.first['cnt'] as int;
  }
}
