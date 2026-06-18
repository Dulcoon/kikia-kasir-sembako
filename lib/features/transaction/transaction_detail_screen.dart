import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/helpers/formatters.dart';
import '../../database/models.dart';
import '../printer/receipt_pdf.dart';
import 'providers/transaction_provider.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(transactionDetailProvider(transactionId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurfaceVariant),
        title: Text(
          'Detail Transaksi',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () async {
              final detail = asyncDetail.valueOrNull;
              if (detail == null) return;
              await ReceiptPdf.share(
                transaction: detail.transaction,
                items: detail.items,
              );
            },
            tooltip: 'Share Struk',
          ),
        ],
      ),
      body: asyncDetail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('Transaksi tidak ditemukan'));
          }
          return _DetailContent(
            transaction: detail.transaction,
            items: detail.items,
          );
        },
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  final Transaction transaction;
  final List<TransactionItem> items;

  const _DetailContent({
    required this.transaction,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(transaction.invoiceNumber,
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(Formatters.dateTime(transaction.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Item',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                                '${item.qty} × ${Formatters.rupiah(item.sellingPrice)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Text(Formatters.rupiah(item.sellingPrice * item.qty),
                          style: TextStyle(
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _SummaryRow(label: 'Subtotal', value: transaction.subtotal),
              Divider(height: 24),
              _SummaryRow(
                  label: 'Tunai', value: transaction.payment),
              _SummaryRow(
                  label: 'Kembalian',
                  value: transaction.changeAmount),
              Divider(height: 24),
              _SummaryRow(
                  label: 'Total',
                  value: transaction.subtotal,
                  bold: true),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Laba',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: (Theme.of(context).brightness == Brightness.dark ? Color(0xFF4ADE80) : Color(0xFF16A34A)))),
                  Text(Formatters.rupiah(transaction.totalProfit),
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: (Theme.of(context).brightness == Brightness.dark ? Color(0xFF4ADE80) : Color(0xFF16A34A)))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              await ReceiptPdf.share(
                transaction: transaction,
                items: items,
              );
            },
            icon: Icon(Icons.share),
            label: const Text(
              'Share Struk PDF',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
          Text(Formatters.rupiah(value),
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }
}
