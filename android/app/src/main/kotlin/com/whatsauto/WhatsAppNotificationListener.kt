package com.whatsauto

import android.app.Notification
import android.app.RemoteInput
import android.content.Intent
import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import io.flutter.plugin.common.EventChannel

class WhatsAppNotificationListener : NotificationListenerService() {

    companion object {
        var eventSink: EventChannel.EventSink? = null
        var isListening = false

        private val WHATSAPP_PACKAGES = setOf(
            "com.whatsapp",
            "com.whatsapp.w4b"
        )

        private val pendingReplies = mutableMapOf<String, StatusBarNotification>()

        fun replyToNotification(key: String, message: String): Boolean {
            val sbn = pendingReplies[key] ?: return false
            return try {
                val actions = sbn.notification.actions ?: return false
                val replyAction = actions.firstOrNull { action ->
                    action.remoteInputs?.isNotEmpty() == true
                } ?: return false

                val remoteInput = replyAction.remoteInputs.first()
                val resultBundle = Bundle()
                resultBundle.putCharSequence(remoteInput.resultKey, message)

                val resultIntent = Intent()
                RemoteInput.addResultsToIntent(replyAction.remoteInputs, resultIntent, resultBundle)
                replyAction.actionIntent.send(applicationContext, 0, resultIntent)
                true
            } catch (e: Exception) {
                e.printStackTrace()
                false
            }
        }

        fun startListening() {
            isListening = true
        }

        fun stopListening() {
            isListening = false
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (!isListening) return
        sbn ?: return
        if (sbn.packageName !in WHATSAPP_PACKAGES) return

        val notification = sbn.notification ?: return
        val extras = notification.extras ?: return

        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: return
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: return

        if (text.isBlank()) return

        val hasReplyAction = notification.actions?.any { action ->
            action.remoteInputs?.isNotEmpty() == true
        } == true

        if (!hasReplyAction) return

        val key = sbn.key
        pendingReplies[key] = sbn

        val data = mapOf(
            "sender" to title,
            "message" to text,
            "replyKey" to key,
            "packageName" to sbn.packageName,
            "timestamp" to System.currentTimeMillis()
        )

        android.os.Handler(android.os.Looper.getMainLooper()).post {
            eventSink?.success(data)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        sbn ?: return
        pendingReplies.remove(sbn.key)
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        isListening = true
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        isListening = false
    }
}
