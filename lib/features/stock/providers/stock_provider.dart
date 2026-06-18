import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/models.dart';
import '../../../database/stock_repository.dart';
import '../../product/providers/product_provider.dart';

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  return StockRepository();
});

final stockHistoryProvider =
    FutureProvider.family<List<StockHistory>, String>((ref, productId) {
  final repo = ref.read(stockRepositoryProvider);
  return repo.getHistory(productId);
});

class StockActions {
  StockActions(this.ref);

  final Ref ref;

  Future<void> addStock({
    required String productId,
    required int qty,
    String? note,
  }) async {
    final repo = ref.read(stockRepositoryProvider);
    await repo.addStock(productId: productId, qty: qty, note: note);
    ref.invalidate(productListProvider);
    ref.invalidate(productDetailProvider(productId));
    ref.invalidate(stockHistoryProvider(productId));
  }

  Future<void> adjustStock({
    required String productId,
    required int newQty,
    String? note,
  }) async {
    final repo = ref.read(stockRepositoryProvider);
    await repo.adjustStock(productId: productId, newQty: newQty, note: note);
    ref.invalidate(productListProvider);
    ref.invalidate(productDetailProvider(productId));
    ref.invalidate(stockHistoryProvider(productId));
  }
}

final stockActionsProvider = Provider<StockActions>((ref) => StockActions(ref));
