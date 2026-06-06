class LockedApp {
  final String packageName;
  final String appName;
  final bool isLocked;

  LockedApp({
    required this.packageName,
    required this.appName,
    required this.isLocked,
  });

  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'isLocked': isLocked,
    };
  }

  factory LockedApp.fromJson(Map<String, dynamic> json) {
    return LockedApp(
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      isLocked: json['isLocked'] as bool,
    );
  }

  LockedApp copyWith({
    String? packageName,
    String? appName,
    bool? isLocked,
  }) {
    return LockedApp(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}
