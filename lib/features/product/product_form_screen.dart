import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/models.dart';
import '../../core/utils/toast_helper.dart';
import '../category/providers/category_provider.dart';
import 'providers/product_provider.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _sellCtrl;
  late final TextEditingController _unitCtrl;
  String? _categoryId;

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _costCtrl = TextEditingController(text: p?.costPrice.toStringAsFixed(0) ?? '');
    _sellCtrl = TextEditingController(text: p?.sellingPrice.toStringAsFixed(0) ?? '');
    _unitCtrl = TextEditingController(text: p?.unit ?? '');
    _categoryId = p?.categoryId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _costCtrl.dispose();
    _sellCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final cost = double.parse(_costCtrl.text.trim());
    final sell = double.parse(_sellCtrl.text.trim());
    final unit = _unitCtrl.text.trim();
    final categoryId = _categoryId;

    if (categoryId == null) {
      ToastHelper.warning(context, 'Pilih kategori terlebih dahulu');
      return;
    }

    final notifier = ref.read(productListProvider.notifier);
    if (isEditing) {
      await notifier.updateProduct(
        id: widget.product!.id,
        name: name,
        costPrice: cost,
        sellingPrice: sell,
        categoryId: categoryId,
        unit: unit.isEmpty ? null : unit,
      );
    } else {
      await notifier.addProduct(
        name: name,
        costPrice: cost,
        sellingPrice: sell,
        categoryId: categoryId,
        unit: unit.isEmpty ? null : unit,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurfaceVariant),
        title: Text(
          isEditing ? 'Edit Barang' : 'Tambah Barang',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nama Barang',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _costCtrl,
                          decoration: InputDecoration(
                            labelText: 'Harga Modal',
                            prefixText: 'Rp ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                            if (double.tryParse(v.trim()) == null) return 'Harus angka';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _sellCtrl,
                          decoration: InputDecoration(
                            labelText: 'Harga Jual',
                            prefixText: 'Rp ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                            if (double.tryParse(v.trim()) == null) return 'Harus angka';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _unitCtrl,
                    decoration: InputDecoration(
                      labelText: 'Satuan (kg, pcs, bks...)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  categoriesAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Text('Error: $e'),
                    data: (categories) {
                      if (categories.isEmpty) {
                        return TextFormField(
                          enabled: false,
                          decoration: InputDecoration(
                            labelText: 'Kategori',
                            helperText: 'Tambah kategori dulu di tab Kategori',
                            border: OutlineInputBorder(),
                          ),
                        );
                      }
                      _categoryId ??= categories.first.id;
                      return DropdownButtonFormField<String>(
                        initialValue: _categoryId,
                        decoration: InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final c in categories)
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                        ],
                        onChanged: (v) => setState(() => _categoryId = v),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Pilih kategori' : null,
                      );
                    },
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
                onPressed: _save,
                icon: Icon(Icons.save),
                label: Text(
                  isEditing ? 'Simpan Perubahan' : 'Simpan Barang',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
