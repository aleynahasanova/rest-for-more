package com.example.rest_for_more

import android.content.Intent
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channelName = "rest_for_more/app_blocking"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            val preferences = getSharedPreferences(
                AppBlockingService.PREFS_NAME,
                MODE_PRIVATE,
            )

            when (call.method) {
                "setBlockedApps" -> {
                    val apps = call.argument<List<String>>("apps") ?: emptyList()
                    preferences.edit()
                        .putStringSet("blocked_apps", apps.toSet())
                        .apply()
                    result.success(true)
                }

                "startBlocking" -> {
                    preferences.edit()
                        .putBoolean("blocking_enabled", true)
                        .apply()
                    result.success(true)
                }

                "stopBlocking" -> {
                    preferences.edit()
                        .putBoolean("blocking_enabled", false)
                        .apply()
                    result.success(true)
                }

                "openAccessibilitySettings" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(true)
                }

                "isAccessibilityEnabled" -> {
                    result.success(isBlockingServiceEnabled())
                }

                "setTemporaryUnblock" -> {
                    val packageName = call.argument<String>("packageName")
                    val untilEpochMs = call.argument<Number>("untilEpochMs")?.toLong()
                    if (packageName.isNullOrBlank() || untilEpochMs == null) {
                        result.error(
                            "invalid_arguments",
                            "packageName and untilEpochMs are required",
                            null,
                        )
                    } else {
                        preferences.edit()
                            .putLong(
                                AppBlockingService.unblockKey(packageName),
                                untilEpochMs,
                            )
                            .apply()
                        result.success(true)
                    }
                }

                "clearTemporaryUnblock" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName.isNullOrBlank()) {
                        result.error(
                            "invalid_arguments",
                            "packageName is required",
                            null,
                        )
                    } else {
                        preferences.edit()
                            .remove(AppBlockingService.unblockKey(packageName))
                            .apply()
                        result.success(true)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun isBlockingServiceEnabled(): Boolean {
        val manager = getSystemService(ACCESSIBILITY_SERVICE) as AccessibilityManager
        if (!manager.isEnabled) {
            return false
        }

        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ) ?: return false

        val serviceName = "${packageName}/${AppBlockingService::class.java.name}"
        val shortName = "${packageName}/.${AppBlockingService::class.java.simpleName}"
        return enabledServices.split(':').any { enabled ->
            enabled.equals(serviceName, ignoreCase = true) ||
                enabled.equals(shortName, ignoreCase = true)
        }
    }
}
