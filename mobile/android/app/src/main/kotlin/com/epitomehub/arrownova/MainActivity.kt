package com.epitomehub.arrownova

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.install.model.UpdateAvailability

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        // Play binding and the first preferences read may wait on disk/services.
        // Keep both off Android's input thread, even on a cold launch.
        val preferences by lazy { applicationContext.getSharedPreferences("update_reminder", MODE_PRIVATE) }
        MethodChannel(messenger, "arrownova/updates", StandardMethodCodec.INSTANCE, messenger.makeBackgroundTaskQueue())
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "check" -> {
                        try {
                            val lastShown = preferences.getLong("shownAt", 0L)
                            val lastVersion = preferences.getInt("version", -1)
                            AppUpdateManagerFactory.create(applicationContext).appUpdateInfo
                                .addOnSuccessListener { info ->
                                    val version = info.availableVersionCode()
                                    val elapsed = System.currentTimeMillis() - lastShown
                                    val recentlyShown = lastVersion == version &&
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
