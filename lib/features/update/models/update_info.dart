class UpdateInfo {
  final String version;
  final int buildNumber;
  final bool forceUpdate;
  final String apkUrl;
  final List<String> changelog;

  UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.forceUpdate,
    required this.apkUrl,
    required this.changelog,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] as String? ?? '1.0.0',
      buildNumber: json['build_number'] as int? ?? 1,
      forceUpdate: json['force_update'] as bool? ?? false,
      apkUrl: (json['download_url'] ?? json['apk_url']) as String? ?? '',
      changelog: (json['changelog'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
