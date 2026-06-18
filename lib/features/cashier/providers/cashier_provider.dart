import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/helpers/formatters.dart';
import '../../../database/models.dart';
import '../../../database/transaction_repository.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../product/providers/product_provider.dart';
import '../../report/providers/report_provider.dart';
import '../../transaction/providers/transaction_provider.dart';

class CartItem {
  final Product product;
  int qty;

  CartItem({required this.product, required this.qty});

  double get subtotal => product.sellingPrice * qty;
  double get profit => (product.sellingPrice - product.costPrice) * qty;
}

enum CashierStage { scanning, checkout }

class CashierState {
  final CashierStage stage;
  final List<CartItem> cart;

  const CashierState({required this.stage, required this.cart});

  double get subtotal => cart.fold(0, (sum, item) => sum + item.subtotal);
  int get totalItems => cart.fold(0, (sum, item) => sum + item.qty);
}

class CashierNotifier extends StateNotifier<CashierState> {
  CashierNotifier(this.ref)
      : super(CashierState(stage: CashierStage.scanning, cart: []));

  final Ref ref;
  final Uuid _uuid = const Uuid();

  void addProduct(Product product) {
    final updated = [...state.cart];
    final idx = updated.indexWhere((c) => c.product.id == product.id);
    
    int currentQty = 0;
    if (idx >= 0) {
      currentQty = updated[idx].qty;
    }
    
    if (currentQty + 1 > product.stock) {
      // Do not allow adding beyond stock
      return;
    }

    if (idx >= 0) {
      updated[idx] = CartItem(
        product: updated[idx].product,
        qty: currentQty + 1,
      );
    } else {
      updated.add(CartItem(product: product, qty: 1));
    }
    state = CashierState(stage: state.stage, cart: updated);
  }

  void updateQty(int index, int qty) {
    final product = state.cart[index].product;
    if (qty > product.stock) {
      qty = product.stock;
    }

    if (qty <= 0) {
      final updated = [...state.cart]..removeAt(index);
      state = CashierState(stage: state.stage, cart: updated);
    } else {
      final updated = [...state.cart];
      updated[index] = CartItem(
        product: product,
        qty: qty,
      );
      state = CashierState(stage: state.stage, cart: updated);
    }
  }

  void removeItem(int index) {
    final updated = [...state.cart]..removeAt(index);
    state = CashierState(stage: state.stage, cart: updated);
  }

  void clearCart() {
    state = CashierState(stage: state.stage, cart: []);
  }

  void proceedToCheckout() {
    state = CashierState(stage: CashierStage.checkout, cart: state.cart);
  }

  void backToScanning() {
    state = CashierState(stage: CashierStage.scanning, cart: state.cart);
  }

  Future<String> checkout({
    required double payment,
    required double changeAmount,
  }) async {
    final transactionRepo = ref.read(transactionRepositoryProvider);
    final productRepo = ref.read(productRepositoryProvider);

    for (final item in state.cart) {
      final product = await productRepo.getById(item.product.id);
      if (product == null) {
        throw Exception('Produk "${item.product.name}" tidak ditemukan');
      }
      if (product.stock < item.qty) {
        throw Exception(
          'Stok "${item.product.name}" tidak cukup '
          '(sisa ${product.stock}, diminta ${item.qty})',
        );
      }
    }

    final now = DateTime.now();
    final seq = await transactionRepo.getTodaySequence();
    final invoiceNumber = Formatters.generateInvoiceNumber(
      date: now,
      sequence: seq,
    );
    final totalProfit =
        state.cart.fold<double>(0, (sum, item) => sum + item.profit);

    final transactionId = _uuid.v4();
    final items = state.cart
        .map(
          (c) => TransactionItem(
            id: _uuid.v4(),
            transactionId: transactionId,
            productId: c.product.id,
            productName: c.product.name,
            qty: c.qty,
            costPrice: c.product.costPrice,
            sellingPrice: c.product.sellingPrice,
            profit: c.profit,
          ),
        )
        .toList();

    final cartForDb = state.cart
        .map(
          (c) => CartItemForCheckout(
            productId: c.product.id,
            qty: c.qty,
          ),
        )
        .toList();

    await transactionRepo.checkoutAll(
      transactionId: transactionId,
      invoiceNumber: invoiceNumber,
      subtotal: state.subtotal,
      payment: payment,
      changeAmount: changeAmount,
      totalProfit: totalProfit,
      items: items,
      cart: cartForDb,
    );

    ref.invalidate(productListProvider);
    ref.invalidate(transactionListProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(reportProvider);

    state = CashierState(stage: CashierStage.scanning, cart: []);
    return invoiceNumber;
  }
}

final cashierProvider = StateNotifierProvider<CashierNotifier, CashierState>((
  ref,
) {
  return CashierNotifier(ref);
});
