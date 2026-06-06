import 'dart:async';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'app_lock_service.dart';
import '../services/storage_service.dart';

class BackgroundNFCService {
  final StorageService _storageService = StorageService();
  final AppLockService _appLockService = AppLockService();
  bool _isMonitoring = false;
  DateTime? _lastTagDetection;
  static const _cooldownDuration = Duration(seconds: 3); // 3 second cooldown
  
  bool get isMonitoring => _isMonitoring;

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    
    try {
      // Start polling for NFC tags in background
      while (_isMonitoring) {
        try {
          final tag = await FlutterNfcKit.poll(
            timeout: Duration(seconds: 5),
            iosMultipleTagMessage: 'Multiple tags found!',
            iosAlertMessage: '',
          );

          await _handleTagDetected(tag.id);
          
          await FlutterNfcKit.finish();
          
          // Add delay between polling attempts to prevent rapid scanning
          await Future.delayed(Duration(seconds: 2));
        } catch (e) {
          // Ignore errors during polling, continue monitoring
          await Future.delayed(Duration(seconds: 2));
        }
      }
    } catch (e) {
      _isMonitoring = false;
    }
  }

  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    await FlutterNfcKit.finish();
  }

  Future<void> _handleTagDetected(String tagId) async {
    // Check if we're in cooldown period
    if (_lastTagDetection != null) {
      final timeSinceLastDetection = DateTime.now().difference(_lastTagDetection!);
      if (timeSinceLastDetection < _cooldownDuration) {
        // Still in cooldown, ignore this detection
        return;
      }
    }
    
    final activeTag = await _storageService.getActiveTag();
    
    if (activeTag != null && activeTag.id == tagId) {
      // This is our registered tag - toggle app locks
      _lastTagDetection = DateTime.now();
      await _toggleAppLocks();
    }
  }

  Future<void> _toggleAppLocks() async {
    final lockedApps = await _storageService.getLockedApps();
    
    for (var app in lockedApps) {
      // Toggle the lock status
      await _storageService.updateAppLockStatus(
        app.packageName,
        !app.isLocked,
      );
    }

    await _syncNativeLockedApps();
  }

  Future<bool> areAppsLocked() async {
    final lockedApps = await _storageService.getLockedApps();
    return lockedApps.any((app) => app.isLocked);
  }

  Future<void> _syncNativeLockedApps() async {
    final lockedApps = await _storageService.getLockedApps();
    final activeLocks = lockedApps
        .where((app) => app.isLocked)
        .map((app) => app.packageName)
        .toList();

    await _appLockService.updateLockedApps(activeLocks);
  }
}
