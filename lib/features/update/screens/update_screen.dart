import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/update_info.dart';
import '../services/update_service.dart';

class UpdateScreen extends ConsumerStatefulWidget {
  const UpdateScreen({super.key});

  @override
  ConsumerState<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends ConsumerState<UpdateScreen> {
  String _currentVersion = 'Memuat...';
  bool _isChecking = true;
  UpdateInfo? _updateInfo;
  String? _error;

  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initUpdateCheck();
  }

  Future<void> _initUpdateCheck() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _currentVersion = '${info.version} (Build ${info.buildNumber})';
        });
      }

      final updateService = ref.read(updateServiceProvider);
      final updateInfo = await updateService.checkUpdate();

      if (mounted) {
        setState(() {
          _updateInfo = updateInfo;
          _isChecking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _startDownload(String apkUrl) async {
    setState(() {
      _isDownloading = true;
      _error = null;
    });

    try {
      final updateService = ref.read(updateServiceProvider);
      await updateService.downloadAndInstallApk(
        apkUrl: apkUrl,
        onProgress: (progress) {
          setState(() {
            _downloadProgress = progress;
          });
        },
      );
      
      // Jika berhasil membuka APK, biarkan halaman tetap ada (karena proses instalasi akan menutupi layar)
      // _isDownloading tidak di-set false agar tombol tetap disable
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembaruan Aplikasi', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            _buildHeaderIcon(context),
            const SizedBox(height: 32),
            _buildCurrentVersionInfo(context),
            const SizedBox(height: 24),
            
            if (_isChecking)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              _buildErrorState(context)
            else if (_updateInfo != null)
              _buildUpdateAvailableState(context, _updateInfo!)
            else
              _buildUpToDateState(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.system_update_rounded,
        size: 80,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildCurrentVersionInfo(BuildContext context) {
    return Column(
      children: [
        Text(
          'Kikia Store',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Versi Saat Ini: $_currentVersion',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 32),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () {
              setState(() {
                _isChecking = true;
                _error = null;
              });
              _initUpdateCheck();
            },
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildUpToDateState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 48),
          const SizedBox(height: 16),
          Text(
            'Aplikasi Sudah Versi Terbaru',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Anda sudah menggunakan versi terbaru dari Kikia Store.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateAvailableState(BuildContext context, UpdateInfo info) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.new_releases, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Versi Baru Tersedia! (v${info.version})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (info.changelog.isNotEmpty) ...[
            const Text(
              'Yang Baru:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: info.changelog
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• $e', style: const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          if (_isDownloading) ...[
            Text(
              'Mengunduh... ${(_downloadProgress * 100).toStringAsFixed(0)}%',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _downloadProgress,
              backgroundColor: Theme.of(context).colorScheme.outlineVariant,
              color: Theme.of(context).colorScheme.primary,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ] else ...[
            FilledButton.icon(
              onPressed: () => _startDownload(info.apkUrl),
              icon: const Icon(Icons.download),
              label: const Text('Download & Update Sekarang'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
