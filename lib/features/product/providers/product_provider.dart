import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/models.dart';
import '../../../database/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

final productDetailProvider =
    FutureProvider.family.autoDispose<Product?, String>((ref, id) async {
  final repo = ref.read(productRepositoryProvider);
  return repo.getById(id);
});

final productListProvider =
    AsyncNotifierProvider<ProductListNotifier, List<Product>>(
  ProductListNotifier.new,
);

class ProductListNotifier extends AsyncNotifier<List<Product>> {
  String _query = '';
  String? _categoryId;

  @override
  Future<List<Product>> build() async {
    final repo = ref.read(productRepositoryProvider);
    return repo.getAll(
      query: _query.isEmpty ? null : _query,
      categoryId: _categoryId,
    );
  }

  void search(String query) {
    _query = query;
    ref.invalidateSelf();
  }

  void filterByCategory(String? categoryId) {
    _categoryId = categoryId;
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  Future<void> addProduct({
    required String name,
    required double costPrice,
    required double sellingPrice,
    required String categoryId,
    String? unit,
  }) async {
    final repo = ref.read(productRepositoryProvider);
    await repo.create(
      name: name,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      categoryId: categoryId,
      unit: unit,
    );
    await refresh();
  }

  Future<void> updateProduct({
    required String id,
    required String name,
    required double costPrice,
    required double sellingPrice,
    required String categoryId,
    String? unit,
  }) async {
    final repo = ref.read(productRepositoryProvider);
    await repo.update(
      id: id,
      name: name,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      categoryId: categoryId,
      unit: unit,
    );
    await refresh();
  }

  Future<void> deleteProduct(String id) async {
    final repo = ref.read(productRepositoryProvider);
    await repo.softDelete(id);
    await refresh();
  }
}
