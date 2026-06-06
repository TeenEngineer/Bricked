package com.teen.bricked

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.teen.bricked/app_lock"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateLockedApps" -> {
                    val lockedApps = call.argument<ArrayList<String>>("lockedApps")
                    val intent = Intent(this, AppLockService::class.java).apply {
                        action = AppLockService.ACTION_UPDATE_LOCKED_APPS
                        putStringArrayListExtra(AppLockService.EXTRA_LOCKED_APPS, lockedApps)
                    }
                    startService(intent)
                    result.success(true)
                }
                "setServiceEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    val intent = Intent(this, AppLockService::class.java).apply {
                        action = AppLockService.ACTION_SET_SERVICE_ENABLED
                        putExtra(AppLockService.EXTRA_SERVICE_ENABLED, enabled)
                    }
                    startService(intent)
                    result.success(true)
                }
                "unlockAll" -> {
                    val intent = Intent(this, AppLockService::class.java).apply {
                        action = AppLockService.ACTION_UNLOCK_ALL
                    }
                    startService(intent)
                    result.success(true)
                }
                "getInstalledApps" -> {
                    val appListProvider = AppListProvider(packageManager, packageName)
                    val apps = appListProvider.getInstalledApps()
                    result.success(apps)
                }
                else -> result.notImplemented()
            }
        }
    }
}
