class Product {
  final String id;
  final String name;
  final double costPrice;
  final double sellingPrice;
  final int stock;
  final String? unit;
  final String categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Product({
    required this.id,
    required this.name,
    required this.costPrice,
    required this.sellingPrice,
    this.stock = 0,
    this.unit,
    required this.categoryId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'cost_price': costPrice,
        'selling_price': sellingPrice,
        'stock': stock,
        'unit': unit,
        'category_id': categoryId,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'deleted_at': deletedAt?.millisecondsSinceEpoch,
      };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'] as String,
        name: map['name'] as String,
        costPrice: (map['cost_price'] as num).toDouble(),
        sellingPrice: (map['selling_price'] as num).toDouble(),
        stock: (map['stock'] as int),
        unit: map['unit'] as String?,
        categoryId: map['category_id'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
        deletedAt: map['deleted_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['deleted_at'] as int)
            : null,
      );

  Product copyWith({
    String? id,
    String? name,
    double? costPrice,
    double? sellingPrice,
    int? stock,
    String? unit,
    String? categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        costPrice: costPrice ?? this.costPrice,
        sellingPrice: sellingPrice ?? this.sellingPrice,
        stock: stock ?? this.stock,
        unit: unit ?? this.unit,
        categoryId: categoryId ?? this.categoryId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );
}

class Category {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Category({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'deleted_at': deletedAt?.millisecondsSinceEpoch,
      };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as String,
        name: map['name'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
        deletedAt: map['deleted_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['deleted_at'] as int)
            : null,
      );

  Category copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );
}

enum StockHistoryType {
  stockIn('IN'),
  stockOut('OUT'),
  adjustment('ADJUSTMENT');

  final String dbValue;
  const StockHistoryType(this.dbValue);

  static StockHistoryType fromDbValue(String value) {
    return StockHistoryType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => stockIn,
    );
  }
}

class TopProduct {
  final String productName;
  final int totalQty;
  final double totalProfit;

  const TopProduct({
    required this.productName,
    required this.totalQty,
    required this.totalProfit,
  });
}

class StockHistory {
  final String id;
  final String productId;
  final int qty;
  final StockHistoryType type;
  final String? note;
  final DateTime createdAt;

  const StockHistory({
    required this.id,
    required this.productId,
    required this.qty,
    required this.type,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'product_id': productId,
        'qty': qty,
        'type': type.dbValue,
        'note': note,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory StockHistory.fromMap(Map<String, dynamic> map) => StockHistory(
        id: map['id'] as String,
        productId: map['product_id'] as String,
        qty: map['qty'] as int,
        type: StockHistoryType.fromDbValue(map['type'] as String),
        note: map['note'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['created_at'] as int,
        ),
      );
}

class Transaction {
  final String id;
  final String invoiceNumber;
  final double subtotal;
  final double payment;
  final double changeAmount;
  final double totalProfit;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.invoiceNumber,
    required this.subtotal,
    required this.payment,
    required this.changeAmount,
    required this.totalProfit,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'invoice_number': invoiceNumber,
        'subtotal': subtotal,
        'payment': payment,
        'change_amount': changeAmount,
        'total_profit': totalProfit,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
        id: map['id'] as String,
        invoiceNumber: map['invoice_number'] as String,
        subtotal: (map['subtotal'] as num).toDouble(),
        payment: (map['payment'] as num).toDouble(),
        changeAmount: (map['change_amount'] as num).toDouble(),
        totalProfit: (map['total_profit'] as num).toDouble(),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['created_at'] as int,
        ),
      );
}

class TransactionItem {
  final String id;
  final String transactionId;
  final String? productId;
  final String productName;
  final int qty;
  final double costPrice;
  final double sellingPrice;
  final double profit;

  const TransactionItem({
    required this.id,
    required this.transactionId,
    this.productId,
    required this.productName,
    required this.qty,
    required this.costPrice,
    required this.sellingPrice,
    required this.profit,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'transaction_id': transactionId,
        'product_id': productId,
        'product_name': productName,
        'qty': qty,
        'cost_price': costPrice,
        'selling_price': sellingPrice,
        'profit': profit,
      };

  factory TransactionItem.fromMap(Map<String, dynamic> map) =>
      TransactionItem(
        id: map['id'] as String,
        transactionId: map['transaction_id'] as String,
        productId: map['product_id'] as String?,
        productName: map['product_name'] as String,
        qty: map['qty'] as int,
        costPrice: (map['cost_price'] as num).toDouble(),
        sellingPrice: (map['selling_price'] as num).toDouble(),
        profit: (map['profit'] as num).toDouble(),
      );

  TransactionItem copyWith({
    String? id,
    String? transactionId,
    String? productId,
    String? productName,
    int? qty,
    double? costPrice,
    double? sellingPrice,
    double? profit,
  }) =>
      TransactionItem(
        id: id ?? this.id,
        transactionId: transactionId ?? this.transactionId,
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        qty: qty ?? this.qty,
        costPrice: costPrice ?? this.costPrice,
        sellingPrice: sellingPrice ?? this.sellingPrice,
        profit: profit ?? this.profit,
      );
}
