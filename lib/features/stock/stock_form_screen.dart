import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/models.dart';
import 'providers/stock_provider.dart';

class StockFormScreen extends ConsumerStatefulWidget {
  final Product product;

  const StockFormScreen({super.key, required this.product});

  @override
  ConsumerState<StockFormScreen> createState() => _StockFormScreenState();
}

class _StockFormScreenState extends ConsumerState<StockFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _noteCtrl;
  bool _isAdjustment = false;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController();
    _noteCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final qty = int.parse(_qtyCtrl.text.trim());
    final note = _noteCtrl.text.trim();

    final actions = ref.read(stockActionsProvider);
    if (_isAdjustment) {
      await actions.adjustStock(
        productId: widget.product.id,
        newQty: qty,
        note: note.isEmpty ? null : note,
      );
    } else {
      await actions.addStock(
        productId: widget.product.id,
        qty: qty,
        note: note.isEmpty ? null : note,
      );
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final unit = widget.product.unit ?? '';
    final unitLabel = unit.isNotEmpty ? ' ($unit)' : '';

    return Scaffold(
      appBar: AppBar(title: Text(_isAdjustment ? 'Koreksi Stok' : 'Tambah Stok')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Barang: ${widget.product.name}',
                style: Theme.of(context).textTheme.titleMedium),
            Text('Stok saat ini: ${widget.product.stock}$unitLabel'),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Mode Koreksi Stok'),
              subtitle: Text(
                _isAdjustment
                    ? 'Set stok ke nilai absolut'
                    : 'Tambah stok ke nilai saat ini',
              ),
              value: _isAdjustment,
              onChanged: (v) => setState(() => _isAdjustment = v),
            ),
            TextFormField(
              controller: _qtyCtrl,
              decoration: InputDecoration(
                labelText: _isAdjustment ? 'Stok Baru' : 'Jumlah',
                helperText: _isAdjustment
                    ? 'Masukkan total stok yang benar'
                    : 'Jumlah stok yang ditambahkan',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                final n = int.tryParse(v.trim());
                if (n == null) return 'Harus angka';
                if (n < 0) return 'Tidak boleh negatif';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _save,
              icon: Icon(_isAdjustment ? Icons.tune : Icons.add_box),
              label: Text(_isAdjustment ? 'Simpan Koreksi' : 'Tambah Stok'),
            ),
          ],
        ),
      ),
    );
  }
}
