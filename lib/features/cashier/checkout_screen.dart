import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/helpers/formatters.dart';
import '../../core/utils/toast_helper.dart';
import 'providers/cashier_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _paymentCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  double _payment = 0;
  double _discount = 0;
  bool _loading = false;
  String? _resultInvoice;
  double _resultSubtotal = 0;
  double _resultDiscount = 0;
  double _resultPayment = 0;
  double _resultChange = 0;

  @override
  void dispose() {
    _paymentCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  void _onPaymentChanged(String v) {
    setState(() {
      _payment = double.tryParse(v.trim()) ?? 0;
    });
  }

  void _onDiscountChanged(String v) {
    setState(() {
      _discount = double.tryParse(v.trim()) ?? 0;
    });
  }

  void _setQuickPayment(double value) {
    setState(() {
      _payment = value;
      _paymentCtrl.text = Formatters.rupiahRaw(value);
    });
  }

  Future<void> _processCheckout() async {
    final notifier = ref.read(cashierProvider.notifier);
    final subtotal = ref.read(cashierProvider).subtotal;
    final grandTotal = subtotal - _discount;
    final change = _payment - grandTotal;

    if (_payment < grandTotal) {
      ToastHelper.warning(context, 'Uang kurang!');
      return;
    }

    setState(() => _loading = true);
    try {
      final invoice = await notifier.checkout(
        payment: _payment,
        changeAmount: change,
        discount: _discount,
      );
      if (!mounted) return;
      setState(() {
        _resultInvoice = invoice;
        _resultSubtotal = subtotal;
        _resultDiscount = _discount;
        _resultPayment = _payment;
        _resultChange = change;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ToastHelper.error(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _done() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_resultInvoice != null) {
      return _SuccessScreen(
        invoice: _resultInvoice!,
        subtotal: _resultSubtotal,
        discount: _resultDiscount,
        payment: _resultPayment,
        change: _resultChange,
        onDone: _done,
      );
    }

    final subtotal = ref.watch(cashierProvider).subtotal;
    final grandTotal = subtotal - _discount;
    final change = _payment - grandTotal;
    final isValid = _payment >= grandTotal && grandTotal >= 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                Text('Total Belanja',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text(Formatters.rupiah(subtotal),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: _discount > 0 ? FontWeight.w600 : FontWeight.w800,
                        fontSize: _discount > 0 ? 24 : null,
                        decoration: _discount > 0 ? TextDecoration.lineThrough : null,
                        color: Theme.of(context).colorScheme.onSurface)),
                if (_discount > 0) ...[
                  const SizedBox(height: 8),
                  Text('Diskon',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                              letterSpacing: 1.2)),
                  Text('- ${Formatters.rupiah(_discount)}',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.error)),
                  const SizedBox(height: 12),
                  Text('Total Bayar',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2)),
                  Text(Formatters.rupiah(grandTotal),
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.primary)),
                ]
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _discountCtrl,
            decoration: InputDecoration(
              labelText: 'Potongan / Diskon (Opsional)',
              prefixText: 'Rp ',
              prefixStyle: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600),
            ),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            keyboardType: TextInputType.number,
            onChanged: _onDiscountChanged,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _paymentCtrl,
            decoration: InputDecoration(
              labelText: 'Jumlah Tunai',
              prefixText: 'Rp ',
              prefixStyle: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600),
            ),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            keyboardType: TextInputType.number,
            autofocus: true,
            onChanged: _onPaymentChanged,
          ),
          if (subtotal > 0) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                  label: const Text('Uang Pas'),
                  onPressed: () => _setQuickPayment(grandTotal),
                ),
                for (final amt in _quickAmounts(grandTotal))
                  ActionChip(
                    label: Text(Formatters.rupiahRaw(amt.toDouble())),
                    onPressed: () => _setQuickPayment(amt.toDouble()),
                  ),
              ],
            ),
          ],
          if (_payment > 0) ...[
            const SizedBox(height: 20),
            _ChangeCard(change: change),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loading ? null : (isValid ? _processCheckout : null),
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Icon(Icons.check_circle, size: 22),
            label: Text(
                _loading ? 'Memproses...' : 'Selesaikan Transaksi',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<int> _quickAmounts(double subtotal) {
    final s = subtotal.toInt();
    final candidates = <int>{};

    // 1. Pecahan uang kertas standar Indonesia yang lebih besar dari total belanja
    final standardNotes = [5000, 10000, 20000, 50000, 100000];
    for (final note in standardNotes) {
      if (note > s) {
        candidates.add(note);
      }
    }

    // 2. Pembulatan ke atas untuk kembalian logis (misal belanja 32.000 -> 35.000, 40.000)
    if (s > 0) {
      final next5k = ((s / 5000).ceil()) * 5000;
      if (next5k > s) candidates.add(next5k);

      final next10k = ((s / 10000).ceil()) * 10000;
      if (next10k > s) candidates.add(next10k);

      final next50k = ((s / 50000).ceil()) * 50000;
      if (next50k > s) candidates.add(next50k);
    }

    final sorted = candidates.toList()..sort();
    return sorted.take(4).toList(); // Tampilkan maksimal 4 nominal agar rapi
  }
}

class _ChangeCard extends StatelessWidget {
  final double change;

  const _ChangeCard({required this.change});

  @override
  Widget build(BuildContext context) {
    final isNegative = change < 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isNegative ? Theme.of(context).colorScheme.error : (Theme.of(context).brightness == Brightness.dark ? Color(0xFF4ADE80) : Color(0xFF16A34A)))
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isNegative ? Theme.of(context).colorScheme.error : (Theme.of(context).brightness == Brightness.dark ? Color(0xFF4ADE80) : Color(0xFF16A34A)))
              .withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isNegative ? Icons.warning_amber : Icons.check_circle,
            color: isNegative ? Theme.of(context).colorScheme.error : (Theme.of(context).brightness == Brightness.dark ? Color(0xFF4ADE80) : Color(0xFF16A34A)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isNegative ? 'Kurang' : 'Kembalian',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            Formatters.rupiah(change.abs()),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isNegative ? Theme.of(context).colorScheme.error : (Theme.of(context).brightness == Brightness.dark ? Color(0xFF4ADE80) : Color(0xFF16A34A)),
                ),
          ),
        ],
      ),
    );
  }
}

class _SuccessScreen extends StatelessWidget {
  final String invoice;
  final double subtotal;
  final double discount;
  final double payment;
  final double change;
  final VoidCallback onDone;

  const _SuccessScreen({
    required this.invoice,
    required this.subtotal,
    required this.discount,
    required this.payment,
    required this.change,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final grandTotal = subtotal - discount;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header area ─────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    // Success badge
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: (Theme.of(context).brightness == Brightness.dark ? Color(0xFF4ADE80) : Color(0xFF16A34A)),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (Theme.of(context).brightness == Brightness.dark ? Color(0xFF4ADE80) : Color(0xFF16A34A)).withValues(alpha: 0.3),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Pembayaran Berhasil',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      invoice,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // ── Receipt card ───────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Total block with accent
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 20),
                            decoration: BoxDecoration(
                              color: (Theme.of(context).brightness == Brightness.dark ? Color(0xFF4ADE80) : Color(0xFF16A34A)).withValues(alpha: 0.06),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TOTAL PEMBAYARAN',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  Formatters.rupiah(grandTotal),
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Transform.translate(
                                offset: const Offset(-10, 0),
                                child: _notchCircle(context, left: true),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  color: Theme.of(context).colorScheme.outlineVariant,
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(10, 0),
                                child: _notchCircle(context, left: false),
                              ),
                            ],
                          ),
                          // Detail rows
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                if (discount > 0) ...[
                                  _DetailRow(
                                    label: 'Subtotal',
                                    value: Formatters.rupiah(subtotal),
                                  ),
                                  const SizedBox(height: 14),
                                  _DetailRow(
                                    label: 'Diskon',
                                    value: '- ${Formatters.rupiah(discount)}',
                                    valueColor: Theme.of(context).colorScheme.error,
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                _DetailRow(
                                  label: 'Tunai Diterima',
                                  value: Formatters.rupiah(payment),
                                ),
                                const SizedBox(height: 14),
                                _DetailRow(
                                  label: 'Kembalian',
                                  value: Formatters.rupiah(change),
                                  valueColor: (Theme.of(context).brightness == Brightness.dark ? Color(0xFF4ADE80) : Color(0xFF16A34A)),
                                  valueBold: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // ── Bottom action ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onDone,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Selesai',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notchCircle(BuildContext context, {required bool left}) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 1),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: valueBold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

