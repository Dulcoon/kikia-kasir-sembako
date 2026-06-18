import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../product/providers/product_provider.dart';
import '../../transaction/providers/transaction_provider.dart';

class DashboardData {
  final double todayRevenue;
  final double todayProfit;
  final int todayTransactionCount;
  final int activeProductCount;

  const DashboardData({
    required this.todayRevenue,
    required this.todayProfit,
    required this.todayTransactionCount,
    required this.activeProductCount,
  });
}

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final transactionRepo = ref.read(transactionRepositoryProvider);
  final productRepo = ref.read(productRepositoryProvider);

  final revenue = await transactionRepo.getTodayRevenue();
  final profit = await transactionRepo.getTodayProfit();
  final txCount = await transactionRepo.getTodayTransactionCount();
  final productCount = await productRepo.getActiveProductCount();

  return DashboardData(
    todayRevenue: revenue,
    todayProfit: profit,
    todayTransactionCount: txCount,
    activeProductCount: productCount,
  );
});
