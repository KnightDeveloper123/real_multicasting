package com.example.real_multicasting

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import androidx.core.content.ContextCompat

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "screen_share_channel")
            .setMethodCallHandler { call, result ->
                if (call.method == "startService") {
                    startScreenCaptureService()
                    result.success("Service started")
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun startScreenCaptureService() {
        val intent = Intent(this, ScreenCaptureService::class.java)
        ContextCompat.startForegroundService(this, intent)
    }
}
