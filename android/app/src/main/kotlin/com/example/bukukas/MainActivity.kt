package com.example.bukukas

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.media.ToneGenerator
import android.media.AudioManager

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.bukukas/beep"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "playBeep") {
                try {
                    // STREAM_ALARM guarantees sound even in Do Not Disturb / Silent Mode
                    val toneGenerator = ToneGenerator(AudioManager.STREAM_ALARM, 100)
                    toneGenerator.startTone(ToneGenerator.TONE_PROP_BEEP)
                    Thread {
                        Thread.sleep(150)
                        toneGenerator.release()
                    }.start()
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to play beep", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
