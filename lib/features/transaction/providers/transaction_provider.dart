import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/models.dart';
import '../../../database/transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

enum TransactionFilterType { all, today, thisWeek, thisMonth, custom }

class TransactionFilterState {
  final TransactionFilterType type;
  final DateTimeRange? customRange;

  const TransactionFilterState({required this.type, this.customRange});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionFilterState &&
        other.type == type &&
        other.customRange == customRange;
  }

  @override
  int get hashCode => type.hashCode ^ customRange.hashCode;
}

final transactionFilterProvider = StateProvider<TransactionFilterState>(
  (ref) => const TransactionFilterState(type: TransactionFilterType.all),
);

final transactionListProvider = FutureProvider<List<Transaction>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final filter = ref.watch(transactionFilterProvider);

  DateTime? start;
  DateTime? end;
  final now = DateTime.now();

  switch (filter.type) {
    case TransactionFilterType.all:
      break;
    case TransactionFilterType.today:
      start = DateTime(now.year, now.month, now.day);
      end = start.add(const Duration(days: 1));
      break;
    case TransactionFilterType.thisWeek:
      // Minggu dimulai hari Senin (weekday=1)
      final daysFromMonday = now.weekday - 1;
      start = DateTime(now.year, now.month, now.day - daysFromMonday);
      end = start.add(const Duration(days: 7));
      break;
    case TransactionFilterType.thisMonth:
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 1);
      break;
    case TransactionFilterType.custom:
      if (filter.customRange != null) {
        start = DateTime(
          filter.customRange!.start.year,
          filter.customRange!.start.month,
          filter.customRange!.start.day,
        );
        end = DateTime(
          filter.customRange!.end.year,
          filter.customRange!.end.month,
          filter.customRange!.end.day + 1,
        );
      }
      break;
  }

  if (start != null && end != null) {
    return repo.getAll(start: start, end: end);
  }

  return repo.getAll();
});

final transactionDetailProvider = FutureProvider.family
    .autoDispose<TransactionDetail?, String>((ref, transactionId) async {
      final repo = ref.read(transactionRepositoryProvider);
      final transaction = await repo.getById(transactionId);
      if (transaction == null) return null;
      final items = await repo.getItems(transactionId);
      return TransactionDetail(transaction: transaction, items: items);
    });

class TransactionDetail {
  final Transaction transaction;
  final List<TransactionItem> items;

  const TransactionDetail({required this.transaction, required this.items});
}
