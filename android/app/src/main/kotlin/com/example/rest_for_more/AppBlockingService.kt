package com.example.rest_for_more

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class AppBlockingService : AccessibilityService() {

    private var overlayView: LinearLayout? = null
    private lateinit var windowManager: WindowManager
    private val handler = Handler(Looper.getMainLooper())
    private val removeOverlayRunnable = Runnable { removeOverlayNow() }

    override fun onServiceConnected() {
        super.onServiceConnected()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            return
        }

        val packageName = event.packageName?.toString() ?: return
        if (shouldIgnorePackage(packageName)) {
            return
        }

        val preferences = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        val blockingEnabled = preferences.getBoolean("blocking_enabled", false)
        if (!blockingEnabled) {
            scheduleRemoveOverlay()
            return
        }

        val blockedApps = preferences.getStringSet("blocked_apps", emptySet())
            ?: emptySet()

        if (blockedApps.contains(packageName) && !isTemporarilyUnblocked(packageName)) {
            handler.removeCallbacks(removeOverlayRunnable)
            showOverlay()
        } else {
            scheduleRemoveOverlay()
        }
    }

    override fun onInterrupt() {
        handler.removeCallbacks(removeOverlayRunnable)
        removeOverlayNow()
    }

    override fun onDestroy() {
        handler.removeCallbacks(removeOverlayRunnable)
        removeOverlayNow()
        super.onDestroy()
    }

    private fun shouldIgnorePackage(packageName: String): Boolean {
        if (packageName == applicationContext.packageName) {
            return true
        }
        return ignoredPackages.contains(packageName)
    }

    private fun isTemporarilyUnblocked(packageName: String): Boolean {
        val until = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
            .getLong(unblockKey(packageName), 0L)
        return until > System.currentTimeMillis()
    }

    private fun showOverlay() {
        if (overlayView != null) {
            return
        }

        val titleView = TextView(this).apply {
            text = "Take a breath"
            textSize = 28f
            setTypeface(typeface, Typeface.BOLD)
            setTextColor(Color.parseColor("#4E3B31"))
            gravity = Gravity.CENTER
        }

        val messageView = TextView(this).apply {
            text = "This app is paused during your focus session."
            textSize = 16f
            setTextColor(Color.parseColor("#994E3B31"))
            gravity = Gravity.CENTER
            setPadding(0, 24, 0, 48)
        }

        val openButton = Button(this).apply {
            text = "Open Rest For More"
            textSize = 16f
            setTextColor(Color.parseColor("#FAF8F4"))
            setBackgroundColor(Color.parseColor("#4E3B31"))
            setOnClickListener { openRestForMore() }
        }

        overlayView = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#FAF8F4"))
            setPadding(64, 64, 64, 64)
            addView(titleView)
            addView(messageView)
            addView(openButton)
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT,
        )

        windowManager.addView(overlayView, params)
    }

    private fun openRestForMore() {
        handler.removeCallbacks(removeOverlayRunnable)
        removeOverlayNow()
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        intent?.addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT,
        )
        if (intent != null) {
            startActivity(intent)
        }
    }

    private fun scheduleRemoveOverlay() {
        handler.removeCallbacks(removeOverlayRunnable)
        handler.postDelayed(removeOverlayRunnable, 250)
    }

    private fun removeOverlayNow() {
        overlayView?.let { view ->
            try {
                windowManager.removeView(view)
            } catch (_: IllegalArgumentException) {
                // Overlay was already detached.
            }
        }
        overlayView = null
    }

    companion object {
        const val PREFS_NAME = "app_blocker"

        fun unblockKey(packageName: String): String = "unblock_until_$packageName"

        private val ignoredPackages = setOf(
            "android",
            "com.android.systemui",
            "com.android.permissioncontroller",
            "com.google.android.permissioncontroller",
            "com.google.android.gms",
            "com.google.android.gsf",
            "com.google.android.inputmethod.latin",
            "com.android.inputmethod.latin",
        )
    }
}
