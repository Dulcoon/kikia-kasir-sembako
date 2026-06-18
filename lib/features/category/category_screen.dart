import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
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
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Kategori',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
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
                    separatorBuilder: (_, _) => const Divider(
                      height: 1, 
                      indent: 0, 
                      endIndent: 0, 
                      color: Color(0xFFE1E2ED),
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
        backgroundColor: const Color(0xFFDBE1FF), // primary-fixed
        foregroundColor: const Color(0xFF00174B), // on-primary-fixed
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onPressed: () => _openAdd(context),
        icon: const Icon(Icons.add),
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
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
                  decoration: const BoxDecoration(
                    color: Color(0xFFDBE1FF), // primary-fixed
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.label,
                    color: AppColors.primary,
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count produk',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Delete button
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete),
                  color: AppColors.textSecondary,
                  iconSize: 20,
                  tooltip: 'Hapus',
                  splashRadius: 24,
                  hoverColor: AppColors.danger.withValues(alpha: 0.1),
                  highlightColor: AppColors.danger.withValues(alpha: 0.1),
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
                color: AppColors.textSecondary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.label_outline,
                  size: 40, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Text('Belum ada kategori',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Tambah kategori untuk mengelompokkan produk.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
