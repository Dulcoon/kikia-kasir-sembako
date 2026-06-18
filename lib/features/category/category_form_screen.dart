import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/models.dart';
import 'providers/category_provider.dart';

class CategoryFormScreen extends ConsumerStatefulWidget {
  final Category? category;

  const CategoryFormScreen({super.key, this.category});

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  bool _saving = false;

  bool get isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category?.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameCtrl.text.trim();

    setState(() => _saving = true);
    try {
      final notifier = ref.read(categoryListProvider.notifier);
      if (isEditing) {
        await notifier.updateCategory(
          id: widget.category!.id,
          name: name,
        );
      } else {
        await notifier.addCategory(name);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurfaceVariant),
        title: Text(
          isEditing ? 'Edit Kategori' : 'Tambah Kategori',
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
              child: TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Kategori',
                  hintText: 'cth: Sembako, Minuman, Snack',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                textCapitalization: TextCapitalization.words,
                autofocus: true,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
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
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(Icons.save),
                label: Text(
                  isEditing ? 'Simpan Perubahan' : 'Simpan Kategori',
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
