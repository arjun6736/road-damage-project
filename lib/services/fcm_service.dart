import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:routefixer/routes.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final StreamController<void> _notificationStreamController =
      StreamController.broadcast();

  static Stream<void> get notificationStream =>
      _notificationStreamController.stream;

  // =============================
  // INIT
  // =============================
  static Future<void> init() async {
    // Request permission
    await _messaging.requestPermission();

    // Android channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'default_channel',
      'General Notifications',
      description: 'Road damage notifications',
      importance: Importance.high,
    );

    // Init settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    // FIXED initialize()
    await _localNotifications.initialize(
      settings: settings,

      onDidReceiveNotificationResponse: (NotificationResponse response) {
        router.go('/reports');

        _notificationStreamController.add(null);
      },
    );

    // Create channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Foreground message
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);

      _notificationStreamController.add(null);
    });

    // Background click
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      router.go('/reports');

      _notificationStreamController.add(null);
    });

    // Terminated state
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      router.go('/reports');

      _notificationStreamController.add(null);
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // =============================
  // BACKGROUND HANDLER
  // =============================
  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    _notificationStreamController.add(null);
  }

  // =============================
  // SHOW NOTIFICATION
  // =============================
  static Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'default_channel',
          'General Notifications',
          channelDescription: 'Road damage notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    // FIXED show()
    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,

      title: message.notification?.title ?? "Report Verified",

      body: message.notification?.body ?? "Verification completed",

      notificationDetails: details,
    );
  }
}
