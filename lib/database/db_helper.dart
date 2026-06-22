import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'migrations.dart';

class DbHelper {
  DbHelper._();

  static const String _dbFileName = 'warungkasir.db';

  static Database? _database;

  static Future<Database> get database async {
    return _database ??= await _open();
  }

  static Future<String> _dbPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, _dbFileName);
  }

  static Future<Database> _open() async {
    final path = await _dbPath();
    final db = await openDatabase(
      path,
      version: 3,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: Migrations.onCreate,
      onUpgrade: Migrations.onUpgrade,
    );

    // Self-healing: Buat tabel jika ada yang belum terbentuk karena kesalahan migrasi sebelumnya
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        cost_price REAL NOT NULL DEFAULT 0,
        selling_price REAL NOT NULL DEFAULT 0,
        stock INTEGER NOT NULL DEFAULT 0,
        unit TEXT,
        category_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stock_histories (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        qty INTEGER NOT NULL,
        type TEXT NOT NULL,
        note TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id TEXT PRIMARY KEY,
        invoice_number TEXT NOT NULL UNIQUE,
        subtotal REAL NOT NULL DEFAULT 0,
        discount REAL NOT NULL DEFAULT 0,
        payment REAL NOT NULL DEFAULT 0,
        change_amount REAL NOT NULL DEFAULT 0,
        total_profit REAL NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transaction_items (
        id TEXT PRIMARY KEY,
        transaction_id TEXT NOT NULL,
        product_id TEXT,
        product_name TEXT NOT NULL,
        qty INTEGER NOT NULL,
        cost_price REAL NOT NULL,
        selling_price REAL NOT NULL,
        profit REAL NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE
      );
    ''');

    // Pastikan kategori default "Umum" ada jika kosong
    final countCats = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM categories'));
    if (countCats == 0) {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert('categories', {
        'id': 'default-umum-id',
        'name': 'Umum',
        'created_at': now,
        'updated_at': now,
      });
    }

    return db;
  }

  static Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
