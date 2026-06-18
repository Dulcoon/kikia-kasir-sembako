import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/models.dart';
import 'category_form_screen.dart';
import 'providers/category_provider.dart';

class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCats = ref.watch(categoryListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Inherit background from ProductScreen TabBarView
      body: asyncCats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (categories) {
          if (categories.isEmpty) {
            return const _EmptyView();
          }
          return ListView(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 96),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Kategori',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1, 
                      indent: 0, 
                      endIndent: 0, 
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                    itemBuilder: (_, i) => _CategoryTile(
                      category: categories[i],
                      onTap: () => _openEdit(context, categories[i]),
                      onDelete: () => _deleteCategory(context, ref, categories[i]),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onPressed: () => _openAdd(context),
        icon: Icon(Icons.add),
        label: const Text('Kategori', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _openAdd(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CategoryFormScreen()),
    );
  }

  void _openEdit(BuildContext context, Category category) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryFormScreen(category: category),
      ),
    );
  }

  Future<void> _deleteCategory(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus kategori?'),
        content: Text(
          '"${category.name}" akan di-soft-delete. Produk terkait tetap '
          'tersimpan tapi tanpa kategori.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref
          .read(categoryListProvider.notifier)
          .deleteCategory(category.id);
    }
  }
}

class _CategoryTile extends ConsumerWidget {
  final Category category;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CategoryTile({
    required this.category,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<int>(
      future: ref
          .read(categoryRepositoryProvider)
          .countProducts(category.id),
      builder: (_, snap) {
        final count = snap.data ?? 0;
        return InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.label,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Texts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count produk',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Delete button
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  iconSize: 20,
                  tooltip: 'Hapus',
                  splashRadius: 24,
                  hoverColor: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                  highlightColor: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.label_outline,
                  size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Text('Belum ada kategori',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Tambah kategori untuk mengelompokkan produk.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
