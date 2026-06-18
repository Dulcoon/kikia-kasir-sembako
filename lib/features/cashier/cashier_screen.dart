import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/helpers/formatters.dart';
import '../../database/models.dart';
import '../product/providers/product_provider.dart';
import '../settings/settings_screen.dart';
import 'providers/cashier_provider.dart';
import 'checkout_screen.dart';

class CashierScreen extends ConsumerStatefulWidget {
  const CashierScreen({super.key});

  @override
  ConsumerState<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends ConsumerState<CashierScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';
  bool _isCartExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _addToCart(Product product) {
    final cart = ref.read(cashierProvider).cart;
    int currentQty = 0;
    try {
      currentQty = cart.firstWhere((c) => c.product.id == product.id).qty;
    } catch (_) {}

    if (currentQty >= product.stock) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stok ${product.name} habis (maksimal ${product.stock})'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    ref.read(cashierProvider.notifier).addProduct(product);
    _searchCtrl.clear();
    _searchFocus.requestFocus();
    setState(() => _query = '');
    ref.read(productListProvider.notifier).search('');
  }

  void _openCheckout() {
    final cart = ref.read(cashierProvider).cart;
    if (cart.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
  }

  void _onSearchChanged(String v) {
    setState(() => _query = v);
    ref.read(productListProvider.notifier).search(v);
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _searchFocus.requestFocus();
    setState(() => _query = '');
    ref.read(productListProvider.notifier).search('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        title: Row(
          children: [
            const Icon(Icons.storefront_outlined, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Text(
              'KikiaStore',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: AppColors.textSecondary, size: 28),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border.withValues(alpha: 0.5), height: 1),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 768;
          if (isDesktop) {
            return Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSearchBar(),
                      Container(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
                      Expanded(child: _buildProductGrid()),
                    ],
                  ),
                ),
                Container(
                  width: 420,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(left: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
                  ),
                  child: _buildRightPane(isMobile: false),
                ),
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchBar(),
                Container(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, gridConstraints) {
                      final collapsedHeight = (constraints.maxHeight * 0.55).clamp(0.0, gridConstraints.maxHeight);
                      final expandedHeight = gridConstraints.maxHeight;

                      return Stack(
                        children: [
                          Positioned.fill(
                            child: _buildProductGrid(bottomPadding: collapsedHeight),
                          ),
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOutCubic,
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: _isCartExpanded ? expandedHeight : collapsedHeight,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, -4),
                                  )
                                ],
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                child: _buildRightPane(isMobile: true),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: TextField(
        controller: _searchCtrl,
        focusNode: _searchFocus,
        decoration: InputDecoration(
          hintText: 'Cari Nama Barang...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearSearch,
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.8), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.8), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildProductGrid({double bottomPadding = 0}) {
    final productsAsync = ref.watch(productListProvider);
    final cashierState = ref.watch(cashierProvider);

    return Container(
      color: AppColors.background, // F8FAFC background for the grid area
      child: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (products) {
          if (products.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada barang.\nSilakan tambah barang di menu Barang.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16 + bottomPadding),
            children: [
              const Text(
                'PILIH CEPAT',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  childAspectRatio: 1.1, // Adjusted for image-like layout
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  final isInCart = cashierState.cart.any((item) => item.product.id == product.id);
                  return _ProductCard(
                    product: product,
                    isInCart: isInCart,
                    onTap: () => _addToCart(product),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRightPane({bool isMobile = false}) {
    final cashierState = ref.watch(cashierProvider);
    final cart = cashierState.cart;
    final subtotal = cashierState.subtotal;

    return Column(
      children: [
        if (isMobile)
          GestureDetector(
            onTap: () => setState(() => _isCartExpanded = !_isCartExpanded),
            onVerticalDragUpdate: (details) {
              if (details.delta.dy < -5) setState(() => _isCartExpanded = true);
              if (details.delta.dy > 5) setState(() => _isCartExpanded = false);
            },
            child: Container(
              color: AppColors.surface, // Background for drag handle
              width: double.infinity,
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
            ),
          ),

        // Cart Header
        GestureDetector(
          onTap: isMobile ? () => setState(() => _isCartExpanded = !_isCartExpanded) : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: isMobile ? 8 : 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart_outlined, color: AppColors.primary, size: 26),
                    const SizedBox(width: 8),
                    Text(
                      'Keranjang (${cart.length})',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    if (isMobile) ...[
                      const SizedBox(width: 4),
                      Icon(
                        _isCartExpanded ? Icons.expand_more : Icons.expand_less,
                        color: AppColors.textSecondary,
                        size: 20,
                      )
                    ]
                  ],
                ),
                TextButton.icon(
                  onPressed: cart.isEmpty
                      ? null
                      : () => ref.read(cashierProvider.notifier).clearCart(),
                  icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                  label: const Text('Kosongkan', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Cart Items
        Expanded(
          child: Container(
            color: AppColors.surface,
            child: cart.isEmpty
                ? const Center(
                    child: Text(
                      'Keranjang kosong',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.length,
                    itemBuilder: (context, i) {
                      final item = cart[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    Formatters.rupiah(item.product.sellingPrice),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Quantity Controls
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F3FE), // Sangat light blue/purple
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 20),
                                    onPressed: () => ref
                                        .read(cashierProvider.notifier)
                                        .updateQty(i, item.qty - 1),
                                    color: AppColors.text,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 40),
                                  ),
                                  SizedBox(
                                    width: 24,
                                    child: Text(
                                      '${item.qty}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 20),
                                    onPressed: () {
                                      if (item.qty >= item.product.stock) {
                                        ScaffoldMessenger.of(context).clearSnackBars();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Stok ${item.product.name} habis (maksimal ${item.product.stock})'),
                                            backgroundColor: AppColors.danger,
                                            behavior: SnackBarBehavior.floating,
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      } else {
                                        ref.read(cashierProvider.notifier).updateQty(i, item.qty + 1);
                                      }
                                    },
                                    color: AppColors.primary,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 40),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => ref.read(cashierProvider.notifier).removeItem(i),
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),

        // Footer (Summary & Action)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    'TOTAL',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    Formatters.rupiah(subtotal),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: -1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton.icon(
                  onPressed: subtotal <= 0 ? null : _openCheckout,
                  icon: const Icon(Icons.payments_outlined, size: 28),
                  label: const Text(
                    'Bayar',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final bool isInCart;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.isInCart,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final outOfStock = product.stock <= 0;
    return InkWell(
      onTap: outOfStock ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: outOfStock ? AppColors.textSecondary : AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              Formatters.rupiah(product.sellingPrice),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: outOfStock ? AppColors.textSecondary : AppColors.primary,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${product.stock} stok',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: outOfStock
                        ? AppColors.border
                        : isInCart
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    outOfStock ? Icons.block : Icons.add,
                    size: 20,
                    color: outOfStock
                        ? AppColors.textSecondary
                        : isInCart
                            ? AppColors.surface
                            : AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
