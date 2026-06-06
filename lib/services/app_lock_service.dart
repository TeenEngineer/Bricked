import 'package:flutter/services.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

class AppLockService {
  static const MethodChannel _channel = MethodChannel('com.teen.bricked/app_lock');
  
  Future<void> updateLockedApps(List<String> packageNames) async {
    try {
      await _channel.invokeMethod('updateLockedApps', {
        'lockedApps': packageNames,
      });
    } catch (e) {
      print('Error updating locked apps: $e');
    }
  }
  
  Future<void> setServiceEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod('setServiceEnabled', {
        'enabled': enabled,
      });
    } catch (e) {
      print('Error setting service enabled: $e');
    }
  }
  
  Future<void> emergencyUnlock() async {
    try {
      await _channel.invokeMethod('unlockAll');
    } catch (e) {
      print('Error emergency unlocking: $e');
    }
  }
  
  Future<List<Map<String, String>>> getInstalledApps() async {
    try {
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: false,
        excludeNonLaunchableApps: true,
        withIcon: false,
      );

      return _mapAndSortApps(apps);
    } catch (e) {
      print('Error getting installed apps from plugin: $e');
    }

    try {
      final result = await _channel.invokeMethod('getInstalledApps');
      if (result is List) {
        final apps = result.map((app) => Map<String, String>.from(app)).toList();
        apps.sort((a, b) {
          final appNameCompare = (a['appName'] ?? '').toLowerCase()
              .compareTo((b['appName'] ?? '').toLowerCase());
          if (appNameCompare != 0) {
            return appNameCompare;
          }
          return (a['packageName'] ?? '').toLowerCase()
              .compareTo((b['packageName'] ?? '').toLowerCase());
        });
        return apps;
      }
    } catch (e) {
      print('Error getting installed apps from native fallback: $e');
    }

    return [];
  }

  List<Map<String, String>> _mapAndSortApps(List<AppInfo> apps) {
    final mappedApps = apps
        .map(
          (app) => {
            'appName': app.name.trim().isEmpty ? app.packageName : app.name.trim(),
            'packageName': app.packageName,
          },
        )
        .toList();

    mappedApps.sort((a, b) {
      final appNameCompare = (a['appName'] ?? '').toLowerCase()
          .compareTo((b['appName'] ?? '').toLowerCase());
      if (appNameCompare != 0) {
        return appNameCompare;
      }
      return (a['packageName'] ?? '').toLowerCase()
          .compareTo((b['packageName'] ?? '').toLowerCase());
    });

    return mappedApps;
  }
}
