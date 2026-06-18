import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart' as package_info_plus;
import '../../core/theme/theme_provider.dart';
import '../../core/utils/toast_helper.dart';
import '../update/models/update_info.dart' as update_info;
import '../update/services/update_service.dart';
import '../update/widgets/update_dialog.dart' as update_dialog;
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
          'Pengaturan Toko',
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
            ],
          ),
        ),
      ),
    );
  }
}

class _AppSettingsSection extends ConsumerStatefulWidget {
  const _AppSettingsSection();

  @override
  ConsumerState<_AppSettingsSection> createState() =>
      _AppSettingsSectionState();
}

class _AppSettingsSectionState extends ConsumerState<_AppSettingsSection> {
  String _version = 'Memuat...';
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await package_info_plus.PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = '${info.version} (Build ${info.buildNumber})';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _version = 'Tidak diketahui';
        });
      }
    }
  }

  Future<void> _checkUpdate() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final service = ref.read(updateServiceProvider);
      final updateInfo = await service.checkUpdate();

      if (mounted) {
        if (updateInfo != null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                update_dialog.UpdateDialog(updateInfo: updateInfo),
          );
        } else {
          ToastHelper.info(context, 'Aplikasi Anda sudah versi terbaru.');
        }
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  // Hidden feature for testing: long press on the version text to simulate update
  void _simulateUpdate() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => update_dialog.UpdateDialog(
        updateInfo: update_info.UpdateInfo(
          version: '9.9.9',
          buildNumber: 999,
          forceUpdate: false,
          apkUrl:
              'https://raw.githubusercontent.com/Dulcoon/kikia-kasir-sembako/main/dummy.apk', // Placeholder
          changelog: [
            'Ini adalah pembaruan simulasi (testing)',
            'Progress bar akan muncul saat didownload',
          ],
        ),
      ),
    );
  }

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
            leading: Icon(Icons.info_outline),
            title: const Text('Versi Aplikasi'),
            subtitle: GestureDetector(
              onLongPress: _simulateUpdate,
              child: Text(_version),
            ),
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.system_update),
            title: const Text('Cek Pembaruan'),
            trailing: _isChecking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.chevron_right),
            onTap: _isChecking ? null : _checkUpdate,
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
