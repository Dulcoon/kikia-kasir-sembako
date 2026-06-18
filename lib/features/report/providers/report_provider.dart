import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/models.dart';
import '../../transaction/providers/transaction_provider.dart';

enum ReportFilter { today, thisWeek, thisMonth }

class ReportData {
  final double revenue;
  final double profit;
  final int transactionCount;
  final List<TopProduct> topProducts;

  const ReportData({
    required this.revenue,
    required this.profit,
    required this.transactionCount,
    required this.topProducts,
  });
}

final reportFilterProvider = StateProvider<ReportFilter>((ref) {
  return ReportFilter.today;
});

final reportProvider = FutureProvider<ReportData>((ref) async {
  final filter = ref.watch(reportFilterProvider);
  final repo = ref.read(transactionRepositoryProvider);

  final now = DateTime.now();
  late DateTime start;
  late DateTime end;

  switch (filter) {
    case ReportFilter.today:
      start = DateTime(now.year, now.month, now.day);
      end = start.add(const Duration(days: 1));
    case ReportFilter.thisWeek:
      start = now.subtract(Duration(days: now.weekday - 1));
      start = DateTime(start.year, start.month, start.day);
      end = start.add(const Duration(days: 7));
    case ReportFilter.thisMonth:
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 1);
  }

  final revenue = await repo.getRevenue(start: start, end: end);
  final profit = await repo.getProfit(start: start, end: end);
  final txCount = await repo.getTransactionCount(start: start, end: end);
  final top = await repo.getTopProducts(start: start, end: end);

  return ReportData(
    revenue: revenue,
    profit: profit,
    transactionCount: txCount,
    topProducts: top,
  );
});
