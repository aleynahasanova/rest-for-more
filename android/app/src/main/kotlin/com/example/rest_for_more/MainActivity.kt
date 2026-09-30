package com.example.rest_for_more

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL =
        "rest_for_more/app_blocking"

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {

        super.configureFlutterEngine(
            flutterEngine
        )

        MethodChannel(
            flutterEngine
                .dartExecutor
                .binaryMessenger,

            CHANNEL

        ).setMethodCallHandler {
            call,
            result ->

            when (call.method) {

                "setBlockedApps" -> {

                    val apps =
                        call.argument<List<String>>(
                            "apps"
                        ) ?: emptyList()

                    getSharedPreferences(
                        "app_blocker",
                        MODE_PRIVATE
                    )
                        .edit()

                        .putStringSet(
                            "blocked_apps",
                            apps.toSet()
                        )

                        .apply()

                    result.success(true)
                }

                "startBlocking" -> {

                    getSharedPreferences(
                        "app_blocker",
                        MODE_PRIVATE
                    )
                        .edit()

                        .putBoolean(
                            "blocking_enabled",
                            true
                        )

                        .apply()

                    result.success(true)
                }

                "stopBlocking" -> {

                    getSharedPreferences(
                        "app_blocker",
                        MODE_PRIVATE
                    )
                        .edit()

                        .putBoolean(
                            "blocking_enabled",
                            false
                        )

                        .apply()

                    result.success(true)
                }

                "openAccessibilitySettings" -> {

                    val intent =
                        Intent(
                            Settings.ACTION_ACCESSIBILITY_SETTINGS
                        )

                    startActivity(intent)

                    result.success(true)
                }

                else -> {

                    result.notImplemented()

                }
            }
        }
    }
}