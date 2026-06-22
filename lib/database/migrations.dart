import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class Migrations {
  Migrations._();

  static const Uuid _uuid = Uuid();

  static Future<void> onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE products (
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
      CREATE TABLE stock_histories (
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
      CREATE TABLE transactions (
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
      CREATE TABLE transaction_items (
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

    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('categories', {
      'id': _uuid.v4(),
      'name': 'Umum',
      'created_at': now,
      'updated_at': now,
    });

    await _createIndexes(db);
  }

  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _migrateV1ToV2(db);
    }
    if (oldVersion < 3) {
      await _migrateV2ToV3(db);
    }
  }

  static Future<void> _migrateV2ToV3(Database db) async {
    await db.execute(
      'ALTER TABLE transactions ADD COLUMN discount REAL NOT NULL DEFAULT 0;',
    );
  }

  static Future<void> _migrateV1ToV2(Database db) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      );
    ''');

    final umumId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('categories', {
      'id': umumId,
      'name': 'Umum',
      'created_at': now,
      'updated_at': now,
    });

    await db.execute(
      'ALTER TABLE products ADD COLUMN category_id TEXT REFERENCES categories(id) ON DELETE SET NULL;',
    );

    await db.rawUpdate(
      'UPDATE products SET category_id = ? WHERE category_id IS NULL;',
      [umumId],
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_products_category_id ON products(category_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_categories_name ON categories(name);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_categories_deleted_at ON categories(deleted_at);',
    );
  }

  static Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX idx_products_name ON products(name);');
    await db.execute(
      'CREATE INDEX idx_products_deleted_at ON products(deleted_at);',
    );
    await db.execute(
      'CREATE INDEX idx_products_category_id ON products(category_id);',
    );
    await db.execute(
      'CREATE INDEX idx_stock_histories_product_id ON stock_histories(product_id);',
    );
    await db.execute(
      'CREATE INDEX idx_stock_histories_created_at ON stock_histories(created_at);',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_created_at ON transactions(created_at);',
    );
    await db.execute(
      'CREATE UNIQUE INDEX idx_transactions_invoice_number ON transactions(invoice_number);',
    );
    await db.execute(
      'CREATE INDEX idx_transaction_items_transaction_id ON transaction_items(transaction_id);',
    );
    await db.execute(
      'CREATE INDEX idx_transaction_items_product_id ON transaction_items(product_id);',
    );
    await db.execute(
      'CREATE INDEX idx_categories_name ON categories(name);',
    );
    await db.execute(
      'CREATE INDEX idx_categories_deleted_at ON categories(deleted_at);',
    );
  }
}
