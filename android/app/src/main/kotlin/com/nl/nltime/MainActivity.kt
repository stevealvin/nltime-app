package com.nl.nltime

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Binder
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.nl.nltime/overlay"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkOverlayPermission" -> {
                    result.success(isOverlayPermissionGranted())
                }
                "requestOverlayPermission" -> {
                    openOverlaySettings()
                    result.success(true)
                }
                "startNativeFloatWindow", "updateFloatParams" -> {
                    val offset = (call.argument<Number>("offsetMs") ?: 0).toLong()
                    val rtt = (call.argument<Number>("rttMs") ?: 0).toInt()
                    val source = call.argument<String>("source") ?: "哔哩哔哩授时"
                    val showMs = call.argument<Boolean>("showMs") ?: true
                    val showOffset = call.argument<Boolean>("showOffset") ?: true
                    val showSource = call.argument<Boolean>("showSource") ?: true
                    val opacity = (call.argument<Number>("opacity") ?: 0.9).toFloat()
                    val scale = (call.argument<Number>("scale") ?: 1.0).toFloat()
                    val themeIdx = (call.argument<Number>("themeIdx") ?: 0).toInt()

                    FloatClockService.updateParams(
                        offset, rtt, source, showMs, showOffset, showSource, opacity, scale, themeIdx
                    )

                    if (call.method == "startNativeFloatWindow" && !FloatClockService.isRunning) {
                        startFloatService()
                    } else if (FloatClockService.isRunning) {
                        FloatClockService.applyParamsUpdate()
                    }
                    result.success(true)
                }
                "stopNativeFloatWindow" -> {
                    stopFloatService()
                    result.success(true)
                }
                "isNativeFloatRunning" -> {
                    result.success(FloatClockService.isRunning)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun startFloatService() {
        val intent = Intent(this, FloatClockService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopFloatService() {
        val intent = Intent(this, FloatClockService::class.java)
        stopService(intent)
    }

    private fun isOverlayPermissionGranted(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(this)) {
                return false
            }
            try {
                val appOpsManager = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
                val mode = appOpsManager.checkOpNoThrow(
                    "android:system_alert_window",
                    Binder.getCallingUid(),
                    packageName
                )
                return mode == AppOpsManager.MODE_ALLOWED
            } catch (e: Exception) {
                return Settings.canDrawOverlays(this)
            }
        }
        return true
    }

    private fun openOverlaySettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // Xiaomi MIUI Special Permission Page Intent
            try {
                val intent = Intent("miui.intent.action.apppermsetting")
                intent.putExtra("extra_pkgname", packageName)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                return
            } catch (_: Exception) {}

            // Standard Android Overlay Settings
            try {
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:$packageName")
                )
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            } catch (e: Exception) {
                try {
                    val intent = Intent(Settings.ACTION_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                } catch (_: Exception) {}
            }
        }
    }
}
