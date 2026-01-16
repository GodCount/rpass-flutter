class AppInfo {
  String name;
  String icon;
  String packageName;
  String versionName;
  int versionCode;
  int installedTimestamp;
  bool isSystem;

  AppInfo({
    required this.name,
    required this.icon,
    required this.packageName,
    required this.versionName,
    required this.versionCode,
    required this.installedTimestamp,
    required this.isSystem,
  });

  factory AppInfo.create(dynamic data) {
    return AppInfo(
      name: data["name"],
      icon: data["icon"],
      packageName: data["packageName"],
      versionName: data["versionName"] ?? "1.0.0",
      versionCode: data["versionCode"] ?? 1,
      installedTimestamp: data["installedTimestamp"] ?? 0,
      isSystem: data["isSystem"] ?? false,
    );
  }

  String getVersionInfo() {
    return "$versionName ($versionCode)";
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "icon": icon,
      "packageName": packageName,
      "versionName": versionName,
      "versionCode": versionCode,
      "isSystem": isSystem,
    };
  }

  static List<AppInfo> parseList(dynamic apps) {
    if (apps == null || apps is! List || apps.isEmpty) return [];
    final List<AppInfo> appInfoList = apps
        .where(
          (element) =>
              element is Map &&
              element.containsKey("name") &&
              element.containsKey("packageName"),
        )
        .map((app) => AppInfo.create(app))
        .toList();
    appInfoList.sort((a, b) => a.name.compareTo(b.name));
    return appInfoList;
  }
}
