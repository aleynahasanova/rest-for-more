package com.example.rest_for_more

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class ReadingNotificationListenerService : NotificationListenerService() {

    override fun onListenerConnected() {
        super.onListenerConnected()

        Log.d(
            TAG,
            "Notification listener connected",
        )
    }

    override fun onNotificationPosted(
        sbn: StatusBarNotification?,
    ) {
        val notification = sbn ?: return

        Log.d(
            TAG,
            "Notification received from: ${notification.packageName}",
        )

        // Never remove notifications created by Rest For More itself.
        if (notification.packageName == packageName) {
            Log.d(
                TAG,
                "Ignoring Rest For More notification",
            )
            return
        }

        val preferences = getSharedPreferences(
            AppBlockingService.PREFS_NAME,
            MODE_PRIVATE,
        )

        val suppressionEnabled = preferences.getBoolean(
            PREF_NOTIFICATION_SUPPRESSION_ENABLED,
            false,
        )

        Log.d(
            TAG,
            "Suppression enabled: $suppressionEnabled",
        )

        val blockedApps = preferences.getStringSet(
            "blocked_apps",
            emptySet(),
        ) ?: emptySet()

        Log.d(
            TAG,
            "Blocked apps: $blockedApps",
        )

        Log.d(
            TAG,
            "Incoming package: ${notification.packageName}",
        )

        if (!suppressionEnabled) {
            Log.d(
                TAG,
                "Suppression is OFF, leaving notification",
            )
            return
        }

        if (blockedApps.contains(notification.packageName)) {
            Log.d(
                TAG,
                "MATCH FOUND - cancelling notification",
            )

            cancelNotification(notification.key)
        } else {
            Log.d(
                TAG,
                "Package is not selected - leaving notification",
            )
        }
    }

    companion object {
        private const val TAG = "ReadingNotification"

        const val PREF_NOTIFICATION_SUPPRESSION_ENABLED =
            "reading_notification_suppression_enabled"
    }
}