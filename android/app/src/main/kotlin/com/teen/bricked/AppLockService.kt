package com.teen.bricked

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.graphics.Color
import android.graphics.PixelFormat
import android.content.Intent
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class AppLockService : AccessibilityService() {

    private var lockedApps = HashSet<String>()
    private var isServiceEnabled = false
    private lateinit var windowManager: WindowManager
    private var overlayView: View? = null
    private var currentLockedPackage: String? = null

    companion object {
        const val ACTION_UPDATE_LOCKED_APPS = "com.teen.bricked.UPDATE_LOCKED_APPS"
        const val EXTRA_LOCKED_APPS = "locked_apps"
        const val ACTION_SET_SERVICE_ENABLED = "com.teen.bricked.SET_SERVICE_ENABLED"
        const val EXTRA_SERVICE_ENABLED = "service_enabled"
        const val ACTION_UNLOCK_ALL = "com.teen.bricked.UNLOCK_ALL"
    }
    
    override fun onServiceConnected() {
        super.onServiceConnected()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        val info = AccessibilityServiceInfo()
        info.eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
        info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
        info.flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
        info.packageNames = null // Monitor all apps
        serviceInfo = info
        isServiceEnabled = true
    }
    
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (!isServiceEnabled || event == null) return

        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            return
        }

        val foregroundPackage = event.packageName?.toString() ?: return
        if (shouldIgnoreForegroundPackage(foregroundPackage)) {
            return
        }

        if (foregroundPackage in lockedApps) {
            showLockOverlay(foregroundPackage)
        }
    }

    override fun onInterrupt() {
        isServiceEnabled = false
        dismissLockOverlay()
    }

    override fun onDestroy() {
        dismissLockOverlay()
        super.onDestroy()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.let {
            when (it.action) {
                ACTION_UPDATE_LOCKED_APPS -> {
                    val apps = it.getStringArrayListExtra(EXTRA_LOCKED_APPS)
                    apps?.let { appList ->
                        lockedApps.clear()
                        lockedApps.addAll(appList)
                        val activeOverlayPackage = currentLockedPackage
                        if (activeOverlayPackage == null || activeOverlayPackage !in lockedApps) {
                            dismissLockOverlay()
                        }
                    }
                }
                ACTION_SET_SERVICE_ENABLED -> {
                    isServiceEnabled = it.getBooleanExtra(EXTRA_SERVICE_ENABLED, false)
                    if (!isServiceEnabled) {
                        dismissLockOverlay()
                    }
                }
                ACTION_UNLOCK_ALL -> {
                    lockedApps.clear()
                    dismissLockOverlay()
                }
            }
        }
        return START_STICKY
    }

    private fun showLockOverlay(packageName: String) {
        if (overlayView != null && currentLockedPackage == packageName) {
            return
        }

        dismissLockOverlay()
        currentLockedPackage = packageName

        val overlayLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(0xD9111827.toInt())
            isClickable = true
            isFocusable = true
        }

        val cardLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.WHITE)
            setPadding(dp(24), dp(24), dp(24), dp(24))
        }

        val titleText = TextView(this).apply {
            text = "App Locked"
            textSize = 24f
            setTextColor(Color.BLACK)
            gravity = Gravity.CENTER
        }

        val messageText = TextView(this).apply {
            text = "This app is locked. Tap your NFC tag in Brick to unlock it."
            textSize = 16f
            setTextColor(0xFF374151.toInt())
            gravity = Gravity.CENTER
            setPadding(0, dp(16), 0, dp(16))
        }

        val appNameText = TextView(this).apply {
            text = resolveAppName(packageName)
            textSize = 18f
            setTextColor(0xFF111827.toInt())
            gravity = Gravity.CENTER
        }

        val packageText = TextView(this).apply {
            text = packageName
            textSize = 13f
            setTextColor(0xFF6B7280.toInt())
            gravity = Gravity.CENTER
            setPadding(0, dp(8), 0, dp(20))
        }

        val homeButton = Button(this).apply {
            text = "Go Home"
            setOnClickListener {
                dismissLockOverlay()
                performGlobalAction(GLOBAL_ACTION_HOME)
            }
        }

        cardLayout.addView(titleText)
        cardLayout.addView(messageText)
        cardLayout.addView(appNameText)
        cardLayout.addView(packageText)
        cardLayout.addView(homeButton)

        val cardParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT,
        ).apply {
            setMargins(dp(24), dp(24), dp(24), dp(24))
        }
        overlayLayout.addView(cardLayout, cardParams)

        val layoutParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_FULLSCREEN,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
        }

        try {
            windowManager.addView(overlayLayout, layoutParams)
            overlayView = overlayLayout
        } catch (_: Exception) {
            overlayView = null
            currentLockedPackage = null
        }
    }

    private fun dismissLockOverlay() {
        if (!::windowManager.isInitialized) {
            overlayView = null
            currentLockedPackage = null
            return
        }

        overlayView?.let { view ->
            try {
                windowManager.removeViewImmediate(view)
            } catch (_: Exception) {
                // Ignore stale-window errors when the system removes the overlay.
            }
        }
        overlayView = null
        currentLockedPackage = null
    }

    private fun shouldIgnoreForegroundPackage(foregroundPackage: String): Boolean {
        return foregroundPackage == packageName
    }

    private fun resolveAppName(packageName: String): String {
        return try {
            val applicationInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(applicationInfo)?.toString() ?: packageName
        } catch (_: Exception) {
            packageName
        }
    }

    private fun dp(value: Int): Int {
        return (value * resources.displayMetrics.density).toInt()
    }
}
