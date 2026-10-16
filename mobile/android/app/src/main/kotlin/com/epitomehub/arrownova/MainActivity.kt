package com.epitomehub.arrownova

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.install.model.UpdateAvailability

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val preferences = getSharedPreferences("update_reminder", MODE_PRIVATE)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "arrownova/updates")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "check" -> {
                        try {
                            AppUpdateManagerFactory.create(applicationContext).appUpdateInfo
                                .addOnSuccessListener { info ->
                                    val version = info.availableVersionCode()
                                    val elapsed = System.currentTimeMillis() - preferences.getLong("shownAt", 0L)
                                    val recentlyShown = preferences.getInt("version", -1) == version &&
                                        elapsed >= 0 && elapsed < 24 * 60 * 60 * 1000L
                                    result.success(if (info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE &&
                                        !recentlyShown) version else null)
                                }
                                .addOnFailureListener { result.success(null) }
                        } catch (_: Exception) {
                            result.success(null)
                        }
                    }
                    "shown" -> {
                        val version = call.argument<Int>("version")
                        if (version != null) preferences.edit()
                            .putInt("version", version)
                            .putLong("shownAt", System.currentTimeMillis()).apply()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
