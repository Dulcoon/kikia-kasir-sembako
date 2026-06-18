import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/helpers/formatters.dart';
import '../../database/models.dart';
import 'providers/report_provider.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(reportFilterProvider);
    final asyncData = ref.watch(reportProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        title: Text(
          'Laporan',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.refresh(reportProvider.future),
          child: ListView(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 96),
            children: [
              _FilterBar(
                filter: filter,
                onChanged: (f) => ref.read(reportFilterProvider.notifier).state = f,
              ),
              const SizedBox(height: 20),
              _StatCard(
                label: 'Omzet',
                value: Formatters.rupiah(data.revenue),
                icon: Icons.trending_up_rounded,
                color: Theme.of(context).colorScheme.primary,
                bgColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              ),
              const SizedBox(height: 12),
              _StatCard(
                label: 'Profit',
                value: Formatters.rupiah(data.profit),
                icon: Icons.account_balance_wallet_rounded,
                color: (Theme.of(context).brightness == Brightness.dark ? Color(0xFF4ADE80) : Color(0xFF16A34A)),
                bgColor: (Theme.of(context).brightness == Brightness.dark ? Color(0xFF4ADE80) : Color(0xFF16A34A)).withValues(alpha: 0.1),
              ),
              const SizedBox(height: 12),
              _StatCard(
                label: 'Jumlah Transaksi',
                value: '${data.transactionCount}',
                icon: Icons.receipt_long_rounded,
                color: (Theme.of(context).brightness == Brightness.dark ? Color(0xFFFBBF24) : Color(0xFFD97706)),
                bgColor: (Theme.of(context).brightness == Brightness.dark ? Color(0xFFFBBF24) : Color(0xFFD97706)).withValues(alpha: 0.1),
              ),
              const SizedBox(height: 24),
              Text(
                'Produk Terlaris',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              if (data.topProducts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Center(
                    child: Text(
                      'Belum ada data penjualan.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                )
              else
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
                      itemCount: data.topProducts.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        indent: 0,
                        endIndent: 0,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      itemBuilder: (_, i) => _TopProductTile(
                        rank: i + 1,
                        product: data.topProducts[i],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final ReportFilter filter;
  final ValueChanged<ReportFilter> onChanged;

  const _FilterBar({required this.filter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: ReportFilter.values.map((f) {
          final selected = f == filter;
          final label = switch (f) {
            ReportFilter.today => 'Hari Ini',
            ReportFilter.thisWeek => 'Minggu Ini',
            ReportFilter.thisMonth => 'Bulan Ini',
          };
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (!selected) onChanged(f);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopProductTile extends StatelessWidget {
  final int rank;
  final TopProduct product;

  const _TopProductTile({required this.rank, required this.product});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rankColor = switch (rank) {
      1 => isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B), // emas
      2 => isDark ? const Color(0xFFCBD5E1) : const Color(0xFF94A3B8), // perak
      3 => isDark ? const Color(0xFFFB923C) : const Color(0xFFCD7C2F), // perunggu
      _ => Theme.of(context).colorScheme.onSurfaceVariant,
    };

    final rankBgColor = switch (rank) {
      1 => isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7),
      2 => isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
      3 => isDark ? const Color(0xFF7C2D12) : const Color(0xFFFDF2E9),
      _ => Theme.of(context).scaffoldBackgroundColor,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rankBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: rankColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${product.totalQty} terjual',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            Formatters.rupiah(product.totalProfit),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: (Theme.of(context).brightness == Brightness.dark ? Color(0xFF4ADE80) : Color(0xFF16A34A)),
            ),
          ),
        ],
      ),
    );
  }
}
