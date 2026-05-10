package com.whatsauto

import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val methodChannel = "com.whatsauto/notification"
    private val eventChannel = "com.whatsauto/notification_events"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isNotificationListenerEnabled" ->
                        result.success(isNotificationListenerEnabled())

                    "openNotificationListenerSettings" -> {
                        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                        result.success(null)
                    }

                    "replyToNotification" -> {
                        val key = call.argument<String>("key") ?: ""
                        val message = call.argument<String>("message") ?: ""
                        val success = WhatsAppNotificationListener.replyToNotification(key, message)
                        result.success(success)
                    }

                    "isOverlayPermissionGranted" -> {
                        val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                            Settings.canDrawOverlays(this) else true
                        result.success(granted)
                    }

                    "requestOverlayPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            )
                            startActivity(intent)
                        }
                        result.success(null)
                    }

                    "showOverlayWindow" -> {
                        val intent = Intent(this, OverlayService::class.java)
                        intent.action = OverlayService.ACTION_SHOW
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(null)
                    }

                    "hideOverlayWindow" -> {
                        val intent = Intent(this, OverlayService::class.java)
                        intent.action = OverlayService.ACTION_HIDE
                        startService(intent)
                        result.success(null)
                    }

                    "startNotificationListenerService" -> {
                        WhatsAppNotificationListener.startListening()
                        result.success(null)
                    }

                    "stopNotificationListenerService" -> {
                        WhatsAppNotificationListener.stopListening()
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannel)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    WhatsAppNotificationListener.eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    WhatsAppNotificationListener.eventSink = null
                }
            })
    }

    private fun isNotificationListenerEnabled(): Boolean {
        val flat = Settings.Secure.getString(
            contentResolver, "enabled_notification_listeners"
        )
        if (!TextUtils.isEmpty(flat)) {
            val names = flat.split(":")
            for (name in names) {
                val cn = ComponentName.unflattenFromString(name)
                if (cn != null && cn.packageName == packageName) return true
            }
        }
        return false
    }
}
