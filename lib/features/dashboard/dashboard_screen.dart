import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/helpers/formatters.dart';
import '../../main_shell.dart';
import '../product/product_form_screen.dart';
import '../settings/settings_screen.dart';
import 'providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        title: Row(
          children: [
            const Icon(Icons.storefront, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Halo, Selamat Pagi!',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'KikiaStore',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.account_circle,
              color: AppColors.primary,
              size: 28,
            ),
            tooltip: 'Pengaturan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.refresh(dashboardProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 8),
              // Akses Cepat
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Akses Cepat',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        ref.read(mainShellIndexProvider.notifier).state =
                            2; // Index for Kasir
                      },
                      icon: const Icon(Icons.add_shopping_cart, size: 20),
                      label: const Text(
                        'Transaksi Baru',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProductFormScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_box, size: 20),
                      label: const Text(
                        'Tambah Barang',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Summary Cards
              _SummaryCard(
                label: 'Omzet Hari Ini',
                value: Formatters.rupiah(data.todayRevenue),
                icon: Icons.trending_up,
                color: AppColors.primary,
                showGraph: true,
                isProfitGraph: false,
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                label: 'Profit Hari Ini',
                value: Formatters.rupiah(data.todayProfit),
                icon: Icons.account_balance_wallet,
                color: AppColors.success,
                showGraph: true,
                isProfitGraph: true,
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                label: 'Transaksi Hari Ini',
                value: '${data.todayTransactionCount}',
                icon: Icons.receipt_long,
                color: AppColors.warning,
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                label: 'Produk Aktif',
                value: '${data.activeProductCount}',
                icon: Icons.inventory_2,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool showGraph;
  final bool isProfitGraph;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.showGraph = false,
    this.isProfitGraph = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
          if (showGraph)
            SizedBox(
              width: 64,
              height: 32,
              child: CustomPaint(
                painter: _GraphPainter(
                  color: color.withValues(alpha: 0.4),
                  isProfit: isProfitGraph,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final Color color;
  final bool isProfit;

  _GraphPainter({required this.color, required this.isProfit});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (isProfit) {
      // M0 30 Q 20 10, 40 25 T 100 10
      path.moveTo(0, size.height * 0.75);
      path.quadraticBezierTo(
        size.width * 0.2,
        size.height * 0.25,
        size.width * 0.4,
        size.height * 0.625,
      );
      path.quadraticBezierTo(
        size.width * 0.6,
        size.height * 1.0,
        size.width,
        size.height * 0.25,
      );
    } else {
      // M0 35 Q 25 35, 50 20 T 100 5
      path.moveTo(0, size.height * 0.875);
      path.quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.875,
        size.width * 0.5,
        size.height * 0.5,
      );
      path.quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.125,
        size.width,
        size.height * 0.125,
      );
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
