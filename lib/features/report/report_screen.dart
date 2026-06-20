import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/helpers/formatters.dart';
import '../../core/helpers/preferences_helper.dart';
import '../../core/services/excel_export_service.dart';
import '../../core/utils/toast_helper.dart';
import '../../database/models.dart';
import '../transaction/providers/transaction_provider.dart';
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
        actions: [
          IconButton(
            tooltip: 'Ekspor ke Excel',
            icon: const Icon(Icons.table_chart_outlined),
            onPressed: () => _showExportDialog(context, ref),
          ),
        ],
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

/// Tampilkan dialog pemilih bulan lalu export ke Excel
Future<void> _showExportDialog(BuildContext context, WidgetRef ref) async {
  final now = DateTime.now();

  // Opsi bulan: bulan ini + 11 bulan sebelumnya
  final months = List.generate(12, (i) {
    return DateTime(now.year, now.month - i, 1);
  });

  DateTime selectedMonth = months[0];

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Ekspor Laporan Excel',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pilih bulan yang ingin diekspor',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                // Dropdown bulan
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(ctx).colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<DateTime>(
                      isExpanded: true,
                      value: selectedMonth,
                      borderRadius: BorderRadius.circular(12),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      items: months.map((m) {
                        final label = '${_monthName(m.month)} ${m.year}${m.year == now.year && m.month == now.month ? ' (Bulan Ini)' : ''}';
                        return DropdownMenuItem(value: m, child: Text(label));
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setModalState(() => selectedMonth = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Info sheet
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Theme.of(ctx).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'File .xlsx berisi 3 sheet: Ringkasan, Riwayat Transaksi, dan Produk Terlaris.',
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: Theme.of(ctx).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Unduh Laporan', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _doExport(context, ref, selectedMonth);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<void> _doExport(BuildContext context, WidgetRef ref, DateTime month) async {
  // Show loading
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    const SnackBar(
      content: Row(children: [
        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
        SizedBox(width: 12),
        Text('Menyiapkan file Excel...'),
      ]),
      duration: Duration(seconds: 10),
    ),
  );

  try {
    final repo = ref.read(transactionRepositoryProvider);
    final storeName = await PreferencesHelper.getStoreName();
    await ExcelExportService.exportMonthly(
      repo: repo,
      storeName: storeName,
      month: month,
    );
    messenger.hideCurrentSnackBar();
  } catch (e) {
    messenger.hideCurrentSnackBar();
    if (context.mounted) {
      ToastHelper.error(context, 'Gagal mengekspor: $e');
    }
  }
}

String _monthName(int month) {
  const names = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  return names[month];
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
