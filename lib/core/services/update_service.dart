import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdateService {
  // Gunakan branch dev untuk mengambil version.json sesuai repositori GitHub
  static const String versionUrl = 'https://raw.githubusercontent.com/Dulcoon/kikia-kasir-sembako/dev/version.json';
  
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final dio = Dio();
      // Tambahkan header untuk mencegah caching
      final response = await dio.get(
        versionUrl,
        options: Options(
          headers: {
            'Cache-Control': 'no-cache',
          },
        ),
      );
      
      var data = response.data;
      if (data is String) {
        data = jsonDecode(data);
      }
      final Map<String, dynamic> jsonMap = data;

      final int latestBuildNumber = jsonMap['build_number'];
      final String latestVersion = jsonMap['version'];
      final String downloadUrl = jsonMap['download_url'];
      final String releaseNotes = jsonMap['release_notes'] ?? '';

      final packageInfo = await PackageInfo.fromPlatform();
      final int currentBuildNumber = int.parse(packageInfo.buildNumber);

      if (latestBuildNumber > currentBuildNumber) {
        if (context.mounted) {
          _showUpdateDialog(context, latestVersion, releaseNotes, downloadUrl);
        }
      }
    } catch (e) {
      debugPrint('Gagal mengecek pembaruan: $e');
    }
  }

  static void _showUpdateDialog(BuildContext context, String version, String notes, String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isDownloading = false;
        double progress = 0.0;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Update Tersedia (v$version)'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Versi baru dari Kikia Store telah tersedia. Apakah Anda ingin memperbarui sekarang?'),
                  const SizedBox(height: 12),
                  if (notes.isNotEmpty) ...[
                    const Text('Catatan Rilis:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(notes, style: const TextStyle(fontSize: 13)),
                  ],
                  if (isDownloading) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 8),
                    Text('${(progress * 100).toStringAsFixed(0)}% Diunduh', style: const TextStyle(fontSize: 12)),
                  ]
                ],
              ),
              actions: [
                if (!isDownloading)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Nanti'),
                  ),
                ElevatedButton(
                  onPressed: isDownloading ? null : () async {
                    setState(() {
                      isDownloading = true;
                    });
                    
                    try {
                      // Minta izin install aplikasi untuk Android 8+
                      if (Platform.isAndroid) {
                        await Permission.requestInstallPackages.request();
                      }
                      
                      final tempDir = await getTemporaryDirectory();
                      final savePath = '${tempDir.path}/app-update.apk';
                      
                      final dio = Dio();
                      await dio.download(
                        url,
                        savePath,
                        onReceiveProgress: (received, total) {
                          if (total != -1) {
                            setState(() {
                              progress = received / total;
                            });
                          }
                        },
                      );
                      
                      if (context.mounted) {
                        Navigator.pop(context); // Tutup dialog setelah selesai
                      }
                      
                      // Buka APK untuk diinstal
                      final result = await OpenFilex.open(savePath);
                      if (result.type != ResultType.done) {
                        debugPrint('Gagal membuka APK: ${result.message}');
                      }
                    } catch (e) {
                      setState(() {
                        isDownloading = false;
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal mengunduh pembaruan: $e')),
                        );
                      }
                    }
                  },
                  child: Text(isDownloading ? 'Mengunduh...' : 'Update Sekarang'),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
