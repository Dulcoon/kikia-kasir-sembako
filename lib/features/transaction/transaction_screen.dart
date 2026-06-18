import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/helpers/formatters.dart';
import '../../database/models.dart';
import 'providers/transaction_provider.dart';
import 'transaction_detail_screen.dart';

class TransactionScreen extends ConsumerWidget {
  const TransactionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTx = ref.watch(transactionListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        title: Text(
          'Riwayat Transaksi',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
        ),
      ),
      body: Column(
        children: [
          const _FilterBar(),
          Expanded(
            child: asyncTx.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const _EmptyView();
                }
                return ListView(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 96),
                  children: [
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
                          itemCount: transactions.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 1, 
                            indent: 0, 
                            endIndent: 0, 
                            color: Color(0xFFE1E2ED),
                          ),
                          itemBuilder: (_, i) => _TransactionTile(
                            transaction: transactions[i],
                            onTap: () => _openDetail(context, transactions[i].id),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, String transactionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionDetailScreen(
          transactionId: transactionId,
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const _TransactionTile({required this.transaction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFDBE1FF), // primary-fixed
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.invoiceNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Formatters.dateTime(transaction.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              Formatters.rupiah(transaction.subtotal),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Belum Ada Transaksi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Transaksi yang sudah selesai\nakan tampil di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(transactionFilterProvider);
    
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _FilterChip(
            label: 'Semua',
            isSelected: filterState.type == TransactionFilterType.all,
            onTap: () => ref.read(transactionFilterProvider.notifier).state = const TransactionFilterState(type: TransactionFilterType.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Hari Ini',
            isSelected: filterState.type == TransactionFilterType.today,
            onTap: () => ref.read(transactionFilterProvider.notifier).state = const TransactionFilterState(type: TransactionFilterType.today),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Minggu Ini',
            isSelected: filterState.type == TransactionFilterType.thisWeek,
            onTap: () => ref.read(transactionFilterProvider.notifier).state = const TransactionFilterState(type: TransactionFilterType.thisWeek),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Bulan Ini',
            isSelected: filterState.type == TransactionFilterType.thisMonth,
            onTap: () => ref.read(transactionFilterProvider.notifier).state = const TransactionFilterState(type: TransactionFilterType.thisMonth),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: filterState.type == TransactionFilterType.custom && filterState.customRange != null
                ? '${Formatters.dateShort(filterState.customRange!.start)} - ${Formatters.dateShort(filterState.customRange!.end)}'
                : 'Pilih Tanggal',
            icon: Icons.calendar_today_rounded,
            isSelected: filterState.type == TransactionFilterType.custom,
            onTap: () async {
              final picked = await showDateRangePicker(
                context: context,
                initialDateRange: filterState.customRange,
                firstDate: DateTime(2020),
                lastDate: DateTime(2050),
                helpText: 'Pilih Rentang Waktu',
                cancelText: 'BATAL',
                confirmText: 'TERAPKAN',
                saveText: 'SIMPAN',
                fieldStartHintText: 'Mulai',
                fieldEndHintText: 'Selesai',
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.primary,
                        onPrimary: Colors.white,
                        surface: AppColors.surface,
                        onSurface: AppColors.text,
                        secondary: AppColors.primary,
                      ),
                      dialogBackgroundColor: AppColors.surface,
                      datePickerTheme: DatePickerThemeData(
                        backgroundColor: AppColors.surface,
                        headerBackgroundColor: AppColors.primary,
                        headerForegroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        dayStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        yearStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                ref.read(transactionFilterProvider.notifier).state = 
                    TransactionFilterState(type: TransactionFilterType.custom, customRange: picked);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
