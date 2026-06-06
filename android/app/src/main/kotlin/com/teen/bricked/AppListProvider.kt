package com.teen.bricked

import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager

class AppListProvider(
    private val packageManager: PackageManager,
    private val currentPackageName: String,
) {

    fun getInstalledApps(): List<Map<String, String>> {
        val flags = PackageManager.MATCH_UNINSTALLED_PACKAGES or
            PackageManager.MATCH_DISABLED_COMPONENTS or
            PackageManager.MATCH_DISABLED_UNTIL_USED_COMPONENTS

        val installedApps = packageManager.getInstalledApplications(flags)
        val visibleApps = mutableListOf<Map<String, String>>()

        for (applicationInfo in installedApps) {
            val packageName = applicationInfo.packageName
            if (packageName.isBlank() || packageName == currentPackageName) {
                continue
            }

            if (!isUserLaunchableApp(applicationInfo)) {
                continue
            }

            val appName = packageManager.getApplicationLabel(applicationInfo)
                ?.toString()
                ?.trim()
                ?.takeIf { it.isNotEmpty() }
                ?: packageName

            visibleApps.add(
                mapOf(
                    "appName" to appName,
                    "packageName" to packageName,
                )
            )
        }

        return visibleApps.sortedWith(
            compareBy<Map<String, String>>(
                { it["appName"]?.lowercase() ?: "" },
                { it["packageName"]?.lowercase() ?: "" },
            )
        )
    }

    private fun isUserLaunchableApp(applicationInfo: ApplicationInfo): Boolean {
        val packageName = applicationInfo.packageName
        val hasLaunchIntent = packageManager.getLaunchIntentForPackage(packageName) != null
        val hasLeanbackIntent = packageManager.getLeanbackLaunchIntentForPackage(packageName) != null
        return hasLaunchIntent || hasLeanbackIntent
    }
}
