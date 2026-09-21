package com.example.rest_for_more

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val METHOD_CHANNEL =
            "com.example.rest_for_more/focus_notification"
        private const val NOTIFICATION_CHANNEL_ID = "focus_timer"
        private const val NOTIFICATION_ID = 1001
        private const val NOTIFICATION_PERMISSION_REQUEST = 1002
    }

    private var pendingFinishingAt: Long? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "showFocusTimer" -> {
                    val finishingAt =
                        call.argument<Number>("finishingAtMilliseconds")?.toLong()

                    if (finishingAt == null) {
                        result.error(
                            "missing_finishing_time",
                            "A finishing timestamp is required.",
                            null,
                        )
                    } else {
                        showFocusTimerWhenAllowed(finishingAt)
                        result.success(null)
                    }
                }

                "hideFocusTimer" -> {
                    pendingFinishingAt = null
                    notificationManager().cancel(NOTIFICATION_ID)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun showFocusTimerWhenAllowed(finishingAt: Long) {
        if (
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
                PackageManager.PERMISSION_GRANTED
        ) {
            pendingFinishingAt = finishingAt
            requestPermissions(
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                NOTIFICATION_PERMISSION_REQUEST,
            )
            return
        }

        showFocusTimer(finishingAt)
    }

    private fun showFocusTimer(finishingAt: Long) {
        val remainingMilliseconds =
            (finishingAt - System.currentTimeMillis()).coerceAtLeast(1L)

        createNotificationChannel()

        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            this,
            0,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, NOTIFICATION_CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        builder
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle("Focus Mode")
            .setContentText("Stay with the task in front of you.")
            .setContentIntent(openAppPendingIntent)
            .setCategory(Notification.CATEGORY_STOPWATCH)
            .setWhen(finishingAt)
            .setShowWhen(true)
            .setUsesChronometer(true)
            .setOngoing(true)
            .setOnlyAlertOnce(true)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            builder.setChronometerCountDown(true)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            builder.setTimeoutAfter(remainingMilliseconds)
        }
        if (Build.VERSION.SDK_INT >= 36) {
            // Android 16+ can promote eligible ongoing notifications to a
            // compact status-bar chip. With the chronometer configured above,
            // the system can display the remaining time in that chip.
            builder.extras.putBoolean("android.requestPromotedOngoing", true)
        }

        notificationManager().notify(NOTIFICATION_ID, builder.build())
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            NOTIFICATION_CHANNEL_ID,
            "Focus timer",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Displays the remaining time for an active focus session."
            setSound(null, null)
            enableVibration(false)
        }
        notificationManager().createNotificationChannel(channel)
    }

    private fun notificationManager(): NotificationManager =
        getSystemService(NotificationManager::class.java)

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode != NOTIFICATION_PERMISSION_REQUEST) return

        val finishingAt = pendingFinishingAt
        pendingFinishingAt = null
        if (
            grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED &&
            finishingAt != null
        ) {
            showFocusTimer(finishingAt)
        }
    }
}
