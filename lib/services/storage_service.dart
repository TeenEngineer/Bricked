import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/nfc_tag.dart';
import '../models/locked_app.dart';

class StorageService {
  static const String _activeTagKey = 'active_nfc_tag';
  static const String _lockedAppsKey = 'locked_apps';

  Future<NFCTag?> getActiveTag() async {
    final prefs = await SharedPreferences.getInstance();
    final tagJson = prefs.getString(_activeTagKey);
    
    if (tagJson == null) return null;
    
    try {
      return NFCTag.fromJson(jsonDecode(tagJson));
    } catch (e) {
      return null;
    }
  }

  Future<void> setActiveTag(NFCTag tag) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeTagKey, jsonEncode(tag.toJson()));
  }

  Future<void> clearActiveTag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeTagKey);
  }

  Future<List<LockedApp>> getLockedApps() async {
    final prefs = await SharedPreferences.getInstance();
    final appsJson = prefs.getStringList(_lockedAppsKey);
    
    if (appsJson == null) return [];
    
    try {
      return appsJson
          .map((json) => LockedApp.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveLockedApps(List<LockedApp> apps) async {
    final prefs = await SharedPreferences.getInstance();
    final appsJson = apps.map((app) => jsonEncode(app.toJson())).toList();
    await prefs.setStringList(_lockedAppsKey, appsJson);
  }

  Future<void> addLockedApp(LockedApp app) async {
    final apps = await getLockedApps();
    
    // Remove if already exists
    apps.removeWhere((a) => a.packageName == app.packageName);
    
    apps.add(app);
    await saveLockedApps(apps);
  }

  Future<void> removeLockedApp(String packageName) async {
    final apps = await getLockedApps();
    apps.removeWhere((a) => a.packageName == packageName);
    await saveLockedApps(apps);
  }

  Future<void> updateAppLockStatus(String packageName, bool isLocked) async {
    final apps = await getLockedApps();
    final index = apps.indexWhere((a) => a.packageName == packageName);
    
    if (index != -1) {
      apps[index] = apps[index].copyWith(isLocked: isLocked);
      await saveLockedApps(apps);
    }
  }

  Future<void> setAllAppLockStatuses(bool isLocked) async {
    final apps = await getLockedApps();
    final updatedApps = apps
        .map((app) => app.copyWith(isLocked: isLocked))
        .toList();
    await saveLockedApps(updatedApps);
  }
}
