import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:renizo/core/services/auth_service.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';

/// Handles Firebase Cloud Messaging setup and syncing tokens to the backend.
class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static const String _channelId = 'high_importance_channel';
  static const String _channelName = 'Notifications';

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Fires when a new FCM message is received (foreground or opened from tap).
  /// Notifications screen can listen and refresh the list.
  static final StreamController<void> _newNotificationController =
      StreamController<void>.broadcast();
  static Stream<void> get onNewNotification => _newNotificationController.stream;

  /// Initializes FCM: requests notification permissions, creates channel,
  /// configures foreground presentation, caches the token, and shows notifications.
  static Future<void> init() async {
    await _requestNotificationPermission();
    await _initLocalNotifications();
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      log(
        'Notification permission denied by user',
        name: 'PushNotificationService',
      );
      debugPrint('Notification permission denied');
    }

    final token = await _messaging.getToken();
    if (token != null) {
      await AuthLocalStorage.saveFcmToken(token);
      log('FCM token (init): $token', name: 'PushNotificationService');
      debugPrint('FCM token (init): $token');
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      unawaited(_handleNewToken(token));
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM foreground notification received');
      log(
        'FCM foreground: notification=${message.notification?.title} / ${message.notification?.body}, data=${message.data}',
        name: 'PushNotificationService',
      );
      if (!_newNotificationController.isClosed) {
        _newNotificationController.add(null);
      }
      if (message.notification != null) {
        debugPrint('  title: ${message.notification!.title}');
        debugPrint('  body: ${message.notification!.body}');
        _showLocalNotification(
          title: message.notification!.title ?? 'Notification',
          body: message.notification!.body ?? '',
          payload: message.data.isNotEmpty ? message.data.toString() : null,
        );
      }
      if (message.data.isNotEmpty) {
        debugPrint('  data: ${message.data}');
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM notification tapped (opened app)');
      log(
        'FCM opened: notification=${message.notification?.title}, data=${message.data}',
        name: 'PushNotificationService',
      );
      if (!_newNotificationController.isClosed) {
        _newNotificationController.add(null);
      }
    });
  }

  /// Android 13+ needs runtime permission for notifications.
  static Future<void> _requestNotificationPermission() async {
    if (!Platform.isAndroid) return;
    final status = await Permission.notification.request();
    if (status.isDenied) {
      debugPrint('Notification permission denied (Android)');
    }
  }

  static Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
    );
    const initSettings = InitializationSettings(
      android: android,
      iOS: ios,
    );
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'App notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      debugPrint('Notification tapped, payload: ${response.payload}');
    }
  }

  static int _notificationId = 0;

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    _notificationId = (_notificationId + 1) % 100000;
    const android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'App notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    const details = NotificationDetails(android: android, iOS: ios);
    await _localNotifications.show(
      id: _notificationId,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  /// Fetches the latest FCM token and pushes it to the backend if possible.
  static Future<void> syncTokenToBackend() async {
    final token =
        await _messaging.getToken() ?? await AuthLocalStorage.getFcmToken();
    if (token == null) return;
    await _handleNewToken(token);
  }

  static Future<void> _handleNewToken(String token) async {
    log('FCM token (refresh): $token', name: 'PushNotificationService');
    debugPrint('FCM token (refresh): $token');
    await AuthLocalStorage.saveFcmToken(token);
    final lastSynced = await AuthLocalStorage.getSyncedFcmToken();
    if (lastSynced == token) return;
    try {
      await AuthService.updateFcmToken(token);
      await AuthLocalStorage.markFcmTokenSynced(token);
    } catch (e) {
      log('Failed to sync FCM token: $e', name: 'PushNotificationService');
    }
  }
}
