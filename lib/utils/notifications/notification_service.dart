import 'dart:convert';
import 'dart:developer' as developer;
import 'package:eSellify/utils/notifications/notification_router.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessageBackgroundHandle(RemoteMessage message) async {
  developer.log("BG MESSAGE DATA: ${message.data}");
}

class NotificationService {
  static final NotificationService _notificationService = NotificationService._internal();

  factory NotificationService() => _notificationService;

  NotificationService._internal();

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Non-prompting Firebase Messaging setup. Safe to call at app launch,
  /// before the user has seen any UI — does not trigger the OS permission dialog.
  Future<void> initFirebaseCore() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
    FirebaseMessaging.onBackgroundMessage(firebaseMessageBackgroundHandle);
  }

  /// Requests notification permission with an in-app rationale shown first.
  /// Tireda Custom: moved out of app-launch (main.dart) to right after the
  /// Dashboard renders, so the user sees the app before being asked — avoids
  /// Play Store's "permission requested without context" flag.
  Future<void> requestPermissionAndInit() async {
    final messaging = FirebaseMessaging.instance;

    final shouldProceed = await _showNotificationRationale();
    if (!shouldProceed) return;

    var request = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (request.authorizationStatus == AuthorizationStatus.authorized ||
        request.authorizationStatus == AuthorizationStatus.provisional) {

      AndroidInitializationSettings initializationSettingsAndroid =
      const AndroidInitializationSettings('@mipmap/ic_launcher');
      var iosInitializationSettings = const DarwinInitializationSettings();

      final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid, iOS: iosInitializationSettings);

      await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null) {
            try {
              final data = Map<String, dynamic>.from(jsonDecode(response.payload!));
              NotificationRouter.handleNotificationTap(data);
            } catch (e) {
              developer.log('Error parsing notification payload: $e');
            }
          }
        },
      );

      const AndroidNotificationChannel orderChannel = AndroidNotificationChannel(
        'orders_channel',
        'Orders',
        description: 'Channel for new order notifications',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('order_sound'),
      );

      const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
        'default_channel',
        'General',
        description: 'General notifications',
        importance: Importance.high,
        playSound: true,
      );

      final androidPlugin =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(orderChannel);
      await androidPlugin?.createNotificationChannel(defaultChannel);

      // ✅ FIX: Wait for APNS token (iOS only)
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        String? apnsToken;
        int retry = 0;

        while (apnsToken == null && retry < 10) {
          apnsToken = await messaging.getAPNSToken();
          if (apnsToken == null) {
            await Future.delayed(const Duration(milliseconds: 500));
            retry++;
          }
        }

        if (apnsToken == null) {
          developer.log("APNS token not available yet. Skipping topic subscription.");
        }
      }

      // ✅ Safe FCM token fetch (optional but recommended)
      try {
        await messaging.getToken();
      } catch (e) {
        developer.log("FCM token error: $e");
      }

      // ✅ Subscribe AFTER token ready
      try {
        await messaging.subscribeToTopic("esellify-customer");
      } on FirebaseException catch (e) {
        developer.log("Subscribe error: ${e.message}");
      } catch (e) {
        developer.log("Subscribe error: $e");
      }

      setupInteractedMessage();
    }
  }

  Future<bool> _showNotificationRationale() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Stay Updated'),
        content: const Text(
          'Tireda would like to send you notifications for new messages, offers, and updates on your ads.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Not Now'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Continue'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    return result ?? false;
  }

  Future<void> setupInteractedMessage() async {
    final messaging = FirebaseMessaging.instance;

    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      developer.log("TERMINATED CLICK: ${initialMessage.data}");
      Future.delayed(const Duration(seconds: 3), () {
        NotificationRouter.handleNotificationTap(Map<String, dynamic>.from(initialMessage.data));
      });
    }

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      developer.log("BG CLICK: ${message.data}");
      NotificationRouter.handleNotificationTap(Map<String, dynamic>.from(message.data));
    });

    FirebaseMessaging.onMessage.listen((message) {
      developer.log("FG MESSAGE: ${message.data}");
      display(message);
    });
  }

  static Future<String> getToken() async {
    String? token;
    try {
      token = await FirebaseMessaging.instance.getToken();
    } on FirebaseException catch (e) {
      developer.log("Error Getting Token :", error: e);
    } catch (e) {
      developer.log("Error Getting Token :", error: e);
    }
    return token ?? '';
  }

  void display(RemoteMessage message) async {
    try {
      bool isBooking = message.data['isNewOrder'] == 'true';

      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        isBooking ? 'orders_channel' : 'default_channel',
        isBooking ? 'Orders' : 'General',
        channelDescription: 'Order Notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: isBooking ? const RawResourceAndroidNotificationSound('order_sound') : null,
      );

      DarwinNotificationDetails iosDetails =
      DarwinNotificationDetails(presentSound: true, sound: isBooking ? 'order_sound.wav' : null);

      NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await flutterLocalNotificationsPlugin.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: message.data['title'] ?? message.notification?.title,
        body: message.data['body'] ?? message.notification?.body,
        notificationDetails: details,
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      if (kDebugMode) {
        developer.log("DISPLAY ERROR: $e");
      }
    }
  }
}