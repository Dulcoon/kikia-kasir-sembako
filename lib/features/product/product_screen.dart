import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/helpers/formatters.dart';
import '../../database/models.dart';
import '../category/category_screen.dart';
import '../category/providers/category_provider.dart';
import '../settings/settings_screen.dart';
import '../stock/stock_screen.dart';
import 'product_form_screen.dart';
import 'providers/product_provider.dart';

class ProductScreen extends ConsumerStatefulWidget {
  const ProductScreen({super.key});

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 64,
          title: Text(
            'Barang',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.account_circle_outlined, color: AppColors.textSecondary, size: 28),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            onTap: (i) => setState(() => _tabIndex = i),
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(text: 'Produk'),
              Tab(text: 'Kategori'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ProductListTab(),
            CategoryScreen(),
          ],
        ),
        floatingActionButton: _tabIndex == 0
            ? FloatingActionButton.extended(
                backgroundColor: const Color(0xFFDBE1FF), // primary-fixed
                foregroundColor: AppColors.primary,
                elevation: 0,
                focusElevation: 0,
                hoverElevation: 0,
                highlightElevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onPressed: () => _openAdd(context),
                icon: const Icon(Icons.add),
                label: const Text('Tambah', style: TextStyle(fontWeight: FontWeight.w600)),
              )
            : null,
      ),
    );
  }

  void _openAdd(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProductFormScreen()),
    );
  }
}

class _ProductListTab extends ConsumerWidget {
  const _ProductListTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListProvider);
    final categoriesAsync = ref.watch(categoryListProvider);

    return Column(
      children: [
        _SearchBar(onChanged: (q) {
          ref.read(productListProvider.notifier).search(q);
        }),
        _CategoryFilterBar(
          categoriesAsync: categoriesAsync,
          productsAsync: productsAsync,
        ),
        Expanded(
          child: productsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (products) {
              if (products.isEmpty) {
                return const _EmptyView();
              }
              return ListView.separated(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 96),
                itemCount: products.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _ProductTile(
                  product: products[i],
                  categoryName: _findCategoryName(
                      categoriesAsync.valueOrNull, products[i].categoryId),
                  onEdit: () => _openEdit(context, ref, products[i]),
                  onStock: () => _openStock(context, ref, products[i]),
                  onDelete: () => _deleteProduct(context, ref, products[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String? _findCategoryName(List<Category>? categories, String id) {
    if (categories == null) return null;
    for (final c in categories) {
      if (c.id == id) return c.name;
    }
    return null;
  }

  void _openEdit(BuildContext context, WidgetRef ref, Product product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(product: product),
      ),
    );
  }

  void _openStock(BuildContext context, WidgetRef ref, Product product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StockScreen(product: product),
      ),
    );
  }

  Future<void> _deleteProduct(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus barang?'),
        content: Text(
          '"${product.name}" akan di-soft-delete. '
          'Riwayat transaksi tetap tersimpan.',
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
      await ref.read(productListProvider.notifier).deleteProduct(product.id);
    }
  }
}

class _CategoryFilterBar extends ConsumerWidget {
  final AsyncValue<List<Category>> categoriesAsync;
  final AsyncValue<List<Product>> productsAsync;

  const _CategoryFilterBar({
    required this.categoriesAsync,
    required this.productsAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = productsAsync.valueOrNull ?? [];
    final categories = categoriesAsync.valueOrNull ?? [];

    final selectedId = _selectedIdFor(products);
    if (selectedId == null && categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _buildChip(
            label: 'Semua',
            isSelected: selectedId == null,
            onTap: () => ref.read(productListProvider.notifier).filterByCategory(null),
          ),
          for (final c in categories)
            _buildChip(
              label: c.name,
              isSelected: selectedId == c.id,
              onTap: () => ref.read(productListProvider.notifier).filterByCategory(c.id),
            ),
        ],
      ),
    );
  }

  Widget _buildChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFDBE1FF) : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? null : Border.all(color: AppColors.border.withValues(alpha: 0.8)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(Icons.check, size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF00174B) : AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _selectedIdFor(List<Product> products) {
    if (products.isEmpty) return null;
    return products.first.categoryId;
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Cari barang...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.8), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.8), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final String? categoryName;
  final VoidCallback onEdit;
  final VoidCallback onStock;
  final VoidCallback onDelete;

  const _ProductTile({
    required this.product,
    required this.categoryName,
    required this.onEdit,
    required this.onStock,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final stockLabel = '${product.stock}${product.unit != null && product.unit!.isNotEmpty ? ' ${product.unit}' : ''}';
    
    return Stack(
      children: [
        InkWell(
          onTap: onEdit,
          onLongPress: onDelete,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.only(right: 60),
                  child: Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Bottom row: Stock info and Prices
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Stock badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDEDF9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            stockLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Price and Action
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              Formatters.rupiah(product.costPrice),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              Formatters.rupiah(product.sellingPrice),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: onStock,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              border: Border.all(color: AppColors.primary, width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
        ),
        
        // Category Badge positioned at top right
        if (categoryName != null)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB), // primary-container
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Text(
                categoryName!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
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
              child: const Icon(Icons.inventory_2_outlined,
                  size: 40, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Text('Belum ada barang',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Ketuk tombol "Tambah" di bawah untuk menambah barang.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
