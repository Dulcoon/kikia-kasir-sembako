import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/helpers/formatters.dart';
import '../../database/models.dart';
import '../product/providers/product_provider.dart';
import 'providers/stock_provider.dart';
import 'stock_form_screen.dart';

class StockScreen extends ConsumerWidget {
  final Product product;

  const StockScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(stockHistoryProvider(product.id));
    final liveProductAsync = ref.watch(productDetailProvider(product.id));

    final displayProduct =
        liveProductAsync.valueOrNull ?? product;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurfaceVariant),
        title: Text(
          'Stok: ${displayProduct.name}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddStock(context, ref),
        icon: Icon(Icons.add),
        label: const Text(
          'Tambah Stok',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _StockSummary(product: displayProduct),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Riwayat Stok',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (histories) {
                if (histories.isEmpty) {
                  return const Center(child: Text('Belum ada riwayat stok.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: histories.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _HistoryTile(history: histories[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openAddStock(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => StockFormScreen(product: product),
      ),
    );
    if (result == true) {
      ref.invalidate(productDetailProvider(product.id));
    }
  }
}

class _StockSummary extends StatelessWidget {
  final Product product;

  const _StockSummary({required this.product});

  @override
  Widget build(BuildContext context) {
    final unit = product.unit ?? '';
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stok Saat Ini',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.stock}${unit.isNotEmpty ? ' $unit' : ''}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Harga Modal',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                Formatters.rupiah(product.costPrice),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final StockHistory history;

  const _HistoryTile({required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive =
        history.type == StockHistoryType.stockIn || history.qty > 0;
    final qtyLabel = history.qty.abs().toString();
    final typeLabel = switch (history.type) {
      StockHistoryType.stockIn => 'Masuk',
      StockHistoryType.stockOut => 'Keluar',
      StockHistoryType.adjustment => 'Koreksi',
    };

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isPositive ? (Theme.of(context).brightness == Brightness.dark ? Color(0xFF4ADE80) : Color(0xFF16A34A)).withValues(alpha: 0.1) : Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isPositive ? Icons.add : Icons.remove,
            size: 20,
            color: isPositive ? (Theme.of(context).brightness == Brightness.dark ? Color(0xFF4ADE80) : Color(0xFF16A34A)) : Theme.of(context).colorScheme.error,
          ),
        ),
        title: Text(
          '$typeLabel: $qtyLabel',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          history.note ?? Formatters.dateTime(history.createdAt),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        trailing: Text(
          Formatters.dateTime(history.createdAt),
          style: theme.textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
