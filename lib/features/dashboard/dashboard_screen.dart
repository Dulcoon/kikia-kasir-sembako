import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/helpers/formatters.dart';
import '../../main_shell.dart';
import '../product/product_form_screen.dart';
import '../settings/settings_screen.dart';
import 'providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) {
      return 'Halo, Selamat Pagi!';
    } else if (hour < 15) {
      return 'Halo, Selamat Siang!';
    } else if (hour < 18) {
      return 'Halo, Selamat Sore!';
    } else {
      return 'Halo, Selamat Malam!';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.storefront, color: Theme.of(context).colorScheme.primary, size: 36),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'KikiaStore',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              color: Theme.of(context).colorScheme.primary,
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
          child: Container(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Akses Cepat',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                      icon: Icon(Icons.add_shopping_cart, size: 20),
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
                      icon: Icon(Icons.add_box, size: 20),
                      label: const Text(
                        'Tambah Barang',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
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
                color: Theme.of(context).colorScheme.primary,
                showGraph: true,
                isProfitGraph: false,
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                label: 'Profit Hari Ini',
                value: Formatters.rupiah(data.todayProfit),
                icon: Icons.account_balance_wallet,
                color: (Theme.of(context).brightness == Brightness.dark ? Color(0xFF4ADE80) : Color(0xFF16A34A)),
                showGraph: true,
                isProfitGraph: true,
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                label: 'Transaksi Hari Ini',
                value: '${data.todayTransactionCount}',
                icon: Icons.receipt_long,
                color: (Theme.of(context).brightness == Brightness.dark ? Color(0xFFFBBF24) : Color(0xFFD97706)),
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                label: 'Produk Aktif',
                value: '${data.activeProductCount}',
                icon: Icons.inventory_2,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.transparent
                : Colors.black.withValues(alpha: 0.02),
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
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
