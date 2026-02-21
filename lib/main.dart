import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:renizo/core/services/push_notification_service.dart';

import 'app.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Log when notification is received in background (check terminal/logcat)
  debugPrint('FCM background notification received: ${message.notification?.title} / ${message.notification?.body}');
  debugPrint('FCM background data: ${message.data}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  bool firebaseOk = false;
  try {
    await Firebase.initializeApp();
    FirebaseAnalytics.instance; // removes "analytics library is missing" warning
    firebaseOk = true;
  } catch (e, st) {
    debugPrint('Firebase init failed (add GoogleService-Info.plist for iOS): $e');
    debugPrint('$st');
  }

  if (firebaseOk) {
    try {
      await PushNotificationService.init();
    } catch (e, st) {
      debugPrint('PushNotificationService.init failed: $e');
      debugPrint('$st');
    }
  }

  runApp(
    ProviderScope(
      child: ScreenUtilInit(
        designSize: const Size(393, 852),
        minTextAdapt: true,
        splitScreenMode: true,
        useInheritedMediaQuery: true,
        child: const App(),
      ),
    ),
  );
}
