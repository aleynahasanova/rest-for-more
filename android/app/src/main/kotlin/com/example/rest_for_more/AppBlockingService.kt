package com.example.rest_for_more

import android.accessibilityservice.AccessibilityService
import android.graphics.Color
import android.graphics.PixelFormat
import android.view.Gravity
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.widget.LinearLayout
import android.widget.TextView

class AppBlockingService : AccessibilityService() {

    private var overlayView: LinearLayout? = null

    private lateinit var windowManager: WindowManager

    override fun onServiceConnected() {
        super.onServiceConnected()

        windowManager =
            getSystemService(WINDOW_SERVICE) as WindowManager
    }

    override fun onAccessibilityEvent(
        event: AccessibilityEvent?
    ) {

        if (
            event?.eventType !=
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
        ) {
            return
        }

        val packageName =
            event.packageName?.toString() ?: return

        val preferences =
            getSharedPreferences(
                "app_blocker",
                MODE_PRIVATE
            )

        val blockingEnabled =
            preferences.getBoolean(
                "blocking_enabled",
                false
            )

        val blockedApps =
            preferences.getStringSet(
                "blocked_apps",
                emptySet()
            ) ?: emptySet()

        if (!blockingEnabled) {
            removeOverlay()
            return
        }

        if (blockedApps.contains(packageName)) {

            showOverlay()

        } else {

            removeOverlay()

        }
    }

    override fun onInterrupt() {
        removeOverlay()
    }

    private fun showOverlay() {

        if (overlayView != null) {
            return
        }

        overlayView = LinearLayout(this).apply {

            orientation =
                LinearLayout.VERTICAL

            gravity =
                Gravity.CENTER

            setBackgroundColor(
                Color.WHITE
            )

            val title =
                TextView(
                    this@AppBlockingService
                ).apply {

                    text = "Rest time"

                    textSize = 30f

                    setTextColor(
                        Color.BLACK
                    )
                }

            val message =
                TextView(
                    this@AppBlockingService
                ).apply {

                    text =
                        "This app is currently blocked."

                    textSize = 18f

                    setTextColor(
                        Color.DKGRAY
                    )
                }

            addView(title)

            addView(message)
        }

        val params =
            WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                PixelFormat.TRANSLUCENT
            )

        windowManager.addView(
            overlayView,
            params
        )
    }

    private fun removeOverlay() {

        overlayView?.let {

            windowManager.removeView(it)

        }

        overlayView = null
    }
}