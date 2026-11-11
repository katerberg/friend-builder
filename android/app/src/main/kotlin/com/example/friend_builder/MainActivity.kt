package com.example.friend_builder

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val iconNames = listOf(
        "Sky", "Mint", "Pink", "Peach", "Lavender", "Yellow", "Coral", "Black"
    )

    // Applied when the app leaves the foreground: switching launcher aliases
    // while visible can make some launchers close the app.
    private var pendingIconName: String? = null
    private var hasPendingIcon = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.friend_builder/app_icon"
        ).setMethodCallHandler { call, result ->
            if (call.method != "setIcon") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val iconName = call.argument<String>("iconName")
            if (iconName != null && iconName !in iconNames) {
                result.error("invalid_icon", "Unknown icon: $iconName", null)
                return@setMethodCallHandler
            }
            pendingIconName = iconName
            hasPendingIcon = true
            result.success(null)
        }
    }

    override fun onStop() {
        super.onStop()
        if (hasPendingIcon) {
            hasPendingIcon = false
            applyIcon(pendingIconName)
        }
    }

    private fun applyIcon(iconName: String?) {
        val selected = "Launcher${iconName ?: "Default"}"
        val aliases = listOf("LauncherDefault") + iconNames.map { "Launcher$it" }
        // Enable the new alias before disabling the others so there is always a launcher entry.
        // Aliases are declared relative to the manifest namespace (this class's package).
        val aliasPackage = javaClass.name.substringBeforeLast('.')
        val ordered = aliases.sortedBy { if (it == selected) 0 else 1 }
        for (alias in ordered) {
            val state = if (alias == selected) {
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            } else {
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            }
            packageManager.setComponentEnabledSetting(
                ComponentName(this, "$aliasPackage.$alias"),
                state,
                PackageManager.DONT_KILL_APP
            )
        }
    }
}
