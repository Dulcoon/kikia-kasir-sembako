import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../models/update_info.dart';
import '../services/update_service.dart';

class UpdateDialog extends ConsumerStatefulWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  ConsumerState<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends ConsumerState<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String? _error;

  Future<void> _startUpdate() async {
    setState(() {
      _isDownloading = true;
      _error = null;
    });

    try {
      final updateService = ref.read(updateServiceProvider);
      await updateService.downloadAndInstallApk(
        apkUrl: widget.updateInfo.apkUrl,
        onProgress: (progress) {
          setState(() {
            _progress = progress;
          });
        },
      );
      
      // Jika berhasil membuka APK, tutup dialog (meskipun install akan overlay)
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
        // Hapus tulisan "Exception: " jika ada
        _error = e.toString().replaceAll('Exception: ', ''); 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prevent dismissing if force update is true or currently downloading
    return PopScope(
      canPop: !widget.updateInfo.forceUpdate && !_isDownloading,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.system_update, color: AppColors.primary, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pembaruan Tersedia',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Versi ${widget.updateInfo.version} sudah tersedia. ${widget.updateInfo.forceUpdate ? "Pembaruan ini wajib dilakukan." : "Apakah Anda ingin memperbarui sekarang?"}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              if (widget.updateInfo.changelog.isNotEmpty) ...[
                const Text(
                  'Yang Baru:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.updateInfo.changelog
                        .map((e) => Text('• $e', style: const TextStyle(fontSize: 13)))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              if (_error != null) ...[
                 Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppColors.danger, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_isDownloading) ...[
                Text(
                  'Mengunduh... ${(_progress * 100).toStringAsFixed(0)}%',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: AppColors.border,
                  color: AppColors.primary,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!widget.updateInfo.forceUpdate)
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Nanti Saja', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                      onPressed: _startUpdate,
                      child: const Text('Update Sekarang'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
