import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'auto_reply_service.dart';
import 'notification_channel.dart';

const notificationChannelId = 'whatsauto_bg';
const notificationId = 888;

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId,
    'WhatsAuto Service',
    description: 'Service de réponse automatique WhatsApp',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'WhatsAuto',
      initialNotificationContent: 'Réponse automatique active...',
      foregroundServiceNotificationId: notificationId,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  final autoReplyService = AutoReplyService();
  await autoReplyService.init();

  NotificationChannelService.notificationStream.listen((data) async {
    final message = data['message'] as String? ?? '';
    final replyKey = data['replyKey'] as String? ?? '';
    final sender = data['sender'] as String? ?? '';

    final reply = autoReplyService.getAutoReply(message);
    if (reply != null && replyKey.isNotEmpty) {
      final delayRule = autoReplyService.rules
          .firstWhere(
            (r) => r.matches(message),
            orElse: () => autoReplyService.rules.first,
          );
      if (delayRule.delaySeconds > 0) {
        await Future.delayed(Duration(seconds: delayRule.delaySeconds));
      }
      await NotificationChannelService.replyToNotification(
        key: replyKey,
        message: reply,
      );
    }
  });

  Timer.periodic(const Duration(seconds: 30), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: 'WhatsAuto actif',
          content:
              'Réponse automatique activée - ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        );
      }
    }
  });
}

class BackgroundServiceManager {
  static final FlutterBackgroundService _service = FlutterBackgroundService();

  static Future<bool> isRunning() => _service.isRunning();

  static Future<void> start() async {
    await initializeBackgroundService();
    await _service.startService();
    await NotificationChannelService.startNotificationListenerService();
  }

  static Future<void> stop() async {
    _service.invoke('stopService');
    await NotificationChannelService.stopNotificationListenerService();
  }
}
