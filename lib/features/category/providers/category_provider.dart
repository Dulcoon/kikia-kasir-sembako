import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/category_repository.dart';
import '../../../database/models.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

final categoryListProvider =
    AsyncNotifierProvider<CategoryListNotifier, List<Category>>(
  CategoryListNotifier.new,
);

class CategoryListNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    final repo = ref.read(categoryRepositoryProvider);
    return repo.getAll();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  Future<void> addCategory(String name) async {
    final repo = ref.read(categoryRepositoryProvider);
    await repo.create(name: name);
    await refresh();
  }

  Future<void> updateCategory({required String id, required String name}) async {
    final repo = ref.read(categoryRepositoryProvider);
    await repo.update(id: id, name: name);
    await refresh();
  }

  Future<void> deleteCategory(String id) async {
    final repo = ref.read(categoryRepositoryProvider);
    await repo.softDelete(id);
    await refresh();
  }
}
