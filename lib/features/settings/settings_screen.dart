import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/toast_helper.dart';
import '../update/screens/update_screen.dart';
import '../transaction/providers/transaction_provider.dart';
import 'providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _populateControllers(SettingsState state) {
    if (_nameCtrl.text.isEmpty &&
        _addressCtrl.text.isEmpty &&
        _phoneCtrl.text.isEmpty) {
      _nameCtrl.text = state.storeName;
      _addressCtrl.text = state.storeAddress;
      _phoneCtrl.text = state.storePhone;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(settingsProvider.notifier)
        .saveSettings(
          name: _nameCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
        );

    if (mounted) {
      ToastHelper.success(context, 'Pengaturan berhasil disimpan');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);

    if (settingsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    _populateControllers(settingsState);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Pengaturan',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Informasi Toko',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nama Toko',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.store),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Nama toko tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressCtrl,
                      decoration: InputDecoration(
                        labelText: 'Alamat Toko',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      maxLines: 3,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Alamat toko tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nomor Telepon',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Nomor telepon tidak boleh kosong';
                        }
                        return null;
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _save,
                  icon: Icon(Icons.save),
                  label: const Text(
                    'Simpan Pengaturan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Tampilan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const _ThemeSettingsSection(),
              const SizedBox(height: 32),
              const Text(
                'Aplikasi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const _AppSettingsSection(),
              const SizedBox(height: 32),
              const Text(
                'Data',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const _DataSettingsSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppSettingsSection extends StatelessWidget {
  const _AppSettingsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.system_update),
            title: const Text('Pembaruan Aplikasi'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const UpdateScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ThemeSettingsSection extends ConsumerWidget {
  const _ThemeSettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                themeMode == ThemeMode.dark
                    ? Icons.dark_mode
                    : themeMode == ThemeMode.light
                        ? Icons.light_mode
                        : Icons.brightness_auto,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Tema Aplikasi',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              segments: const <ButtonSegment<ThemeMode>>[
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  label: Text('Terang'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  label: Text('Gelap'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  label: Text('Sistem'),
                  icon: Icon(Icons.brightness_auto_outlined),
                ),
              ],
              selected: <ThemeMode>{themeMode},
              onSelectionChanged: (Set<ThemeMode> newSelection) {
                ref.read(themeProvider.notifier).setThemeMode(newSelection.first);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DataSettingsSection extends ConsumerStatefulWidget {
  const _DataSettingsSection();

  @override
  ConsumerState<_DataSettingsSection> createState() => _DataSettingsSectionState();
}

class _DataSettingsSectionState extends ConsumerState<_DataSettingsSection> {
  Future<void> _confirmDelete() async {
    final TextEditingController confirmController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Semua Transaksi?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tindakan ini akan menghapus permanen seluruh riwayat transaksi Anda. Stok barang tidak akan berubah.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Ketik "yakin" untuk melanjutkan:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmController,
                decoration: InputDecoration(
                  hintText: 'yakin',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton.tonal(
              style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              onPressed: () {
                if (confirmController.text.trim().toLowerCase() == 'yakin') {
                  Navigator.pop(context, true);
                } else {
                  ToastHelper.error(context, 'Kata konfirmasi salah');
                }
              },
              child: const Text('Hapus Semua', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        final repo = ref.read(transactionRepositoryProvider);
        await repo.deleteAll();
        
        // Refresh transaction list
        ref.invalidate(transactionListProvider);
        
        if (mounted) {
          ToastHelper.success(context, 'Seluruh data transaksi berhasil dihapus');
        }
      } catch (e) {
        if (mounted) {
          ToastHelper.error(context, 'Gagal menghapus data: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
            title: Text(
              'Hapus Semua Data Transaksi',
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Tindakan ini tidak bisa dibatalkan'),
            onTap: _confirmDelete,
          ),
        ],
      ),
    );
  }
}
