import 'dart:async';
import 'package:flutter/services.dart';

class NotificationChannelService {
  static const MethodChannel _channel =
      MethodChannel('com.whatsauto/notification');
  static const EventChannel _eventChannel =
      EventChannel('com.whatsauto/notification_events');

  static Stream<Map<String, dynamic>>? _notificationStream;

  static Stream<Map<String, dynamic>> get notificationStream {
    _notificationStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => Map<String, dynamic>.from(event));
    return _notificationStream!;
  }

  static Future<bool> isNotificationListenerEnabled() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('isNotificationListenerEnabled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openNotificationListenerSettings() async {
    try {
      await _channel.invokeMethod('openNotificationListenerSettings');
    } catch (_) {}
  }

  static Future<bool> replyToNotification({
    required String key,
    required String message,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('replyToNotification', {
        'key': key,
        'message': message,
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isOverlayPermissionGranted() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('isOverlayPermissionGranted');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (_) {}
  }

  static Future<void> showOverlayWindow() async {
    try {
      await _channel.invokeMethod('showOverlayWindow');
    } catch (_) {}
  }

  static Future<void> hideOverlayWindow() async {
    try {
      await _channel.invokeMethod('hideOverlayWindow');
    } catch (_) {}
  }

  static Future<void> startNotificationListenerService() async {
    try {
      await _channel.invokeMethod('startNotificationListenerService');
    } catch (_) {}
  }

  static Future<void> stopNotificationListenerService() async {
    try {
      await _channel.invokeMethod('stopNotificationListenerService');
    } catch (_) {}
  }
}
