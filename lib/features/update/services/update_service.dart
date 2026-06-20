import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/update_info.dart';

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});

class UpdateService {
  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 5)));

  // Menggunakan URL GitHub raw untuk version.json
  final String _updateUrl = 'https://raw.githubusercontent.com/Dulcoon/kikia-kasir-sembako/dev/version.json';

  Future<UpdateInfo?> checkUpdate() async {
    try {
      final response = await _dio.get(_updateUrl);
      
      if (response.statusCode == 200) {
        var data = response.data;
        if (data is String) {
          data = jsonDecode(data);
        }
        final serverUpdateInfo = UpdateInfo.fromJson(data);
        
        final packageInfo = await PackageInfo.fromPlatform();
        final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

        // Bandingkan build number atau versi (disini contoh pakai build number)
        if (serverUpdateInfo.buildNumber > currentBuildNumber) {
          return serverUpdateInfo;
        }
      }
      return null;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        throw Exception('Tidak ada koneksi internet. Gagal mengecek pembaruan.');
      }
      throw Exception('Terjadi kesalahan saat mengecek pembaruan: ${e.message}');
    } catch (e) {
      throw Exception('Gagal memproses data pembaruan.');
    }
  }

  Future<void> downloadAndInstallApk({
    required String apkUrl,
    required Function(double) onProgress,
  }) async {
    try {
      // 1. Minta Izin
      if (Platform.isAndroid) {
        var status = await Permission.requestInstallPackages.request();
        if (!status.isGranted) {
           throw Exception('Izin instalasi aplikasi tidak diberikan.');
        }
      }

      // 2. Tentukan lokasi download
      Directory tempDir = await getTemporaryDirectory();
      String savePath = '${tempDir.path}/update_warungkasir.apk';

      // 3. Download APK
      await _dio.download(
        apkUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );

      // 4. Buka APK untuk Install
      final result = await OpenFilex.open(savePath);
      if (result.type != ResultType.done) {
        throw Exception('Gagal membuka file instalasi: ${result.message}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.connectionError) {
        throw Exception('Koneksi internet bermasalah. Pastikan sinyal stabil.');
      }
      throw Exception('Gagal mengunduh (Code: ${e.response?.statusCode}): ${e.message} \nDetail: ${e.error}');
    } catch (e) {
      throw Exception('Error tak terduga: $e');
    }
  }
}
