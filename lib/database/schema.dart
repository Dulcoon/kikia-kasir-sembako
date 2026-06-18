const String kSchemaProducts = '''
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
''';

const String kSchemaCategories = '''
CREATE TABLE categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);
''';

const String kSchemaStockHistories = '''
CREATE TABLE stock_histories (
  id TEXT PRIMARY KEY,
  product_id TEXT NOT NULL,
  qty INTEGER NOT NULL,
  type TEXT NOT NULL,
  note TEXT,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
);
''';

const String kSchemaTransactions = '''
CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  invoice_number TEXT NOT NULL UNIQUE,
  subtotal REAL NOT NULL DEFAULT 0,
  payment REAL NOT NULL DEFAULT 0,
  change_amount REAL NOT NULL DEFAULT 0,
  total_profit REAL NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL
);
''';

const String kSchemaTransactionItems = '''
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
''';

const String kIndexProductsName =
    'CREATE INDEX idx_products_name ON products(name);';
const String kIndexProductsDeletedAt =
    'CREATE INDEX idx_products_deleted_at ON products(deleted_at);';
const String kIndexStockHistoriesProductId =
    'CREATE INDEX idx_stock_histories_product_id ON stock_histories(product_id);';
const String kIndexStockHistoriesCreatedAt =
    'CREATE INDEX idx_stock_histories_created_at ON stock_histories(created_at);';
const String kIndexTransactionsCreatedAt =
    'CREATE INDEX idx_transactions_created_at ON transactions(created_at);';
const String kIndexTransactionsInvoiceNumber =
    'CREATE UNIQUE INDEX idx_transactions_invoice_number ON transactions(invoice_number);';
const String kIndexTransactionItemsTransactionId =
    'CREATE INDEX idx_transaction_items_transaction_id ON transaction_items(transaction_id);';
const String kIndexTransactionItemsProductId =
    'CREATE INDEX idx_transaction_items_product_id ON transaction_items(product_id);';

const String kIndexProductsCategoryId =
    'CREATE INDEX idx_products_category_id ON products(category_id);';
const String kIndexCategoriesName =
    'CREATE INDEX idx_categories_name ON categories(name);';
const String kIndexCategoriesDeletedAt =
    'CREATE INDEX idx_categories_deleted_at ON categories(deleted_at);';

const int kDbVersion = 2;
