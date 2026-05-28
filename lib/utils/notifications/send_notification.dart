// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart' hide Constant;
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/models/notification_model.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:googleapis_auth/auth_io.dart'; // For OAuth 2.0
import 'package:http/http.dart' as http;

class SendNotification {
  static final _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  // Load service account JSON
  static Future getServiceAccountJson() async {
    final response = await http.get(Uri.parse(Constant.jsonFileURL.toString()));
    return json.decode(response.body);
  }

  static String? _cachedToken;
  static DateTime? _tokenExpireTime;

  // Get Access Token for FCM REST API
  static Future<String> getAccessToken() async {
    // Check if we have a valid cached token (tokens usually last 1 hour)
    if (_cachedToken != null && _tokenExpireTime != null && DateTime.now().isBefore(_tokenExpireTime!)) {
      return _cachedToken!;
    }

    // If not cached, fetch it
    final jsonData = await getServiceAccountJson();
    final serviceAccountCredentials = ServiceAccountCredentials.fromJson(jsonData);
    final client = await clientViaServiceAccount(serviceAccountCredentials, _scopes);

    _cachedToken = client.credentials.accessToken.data;
    _tokenExpireTime = client.credentials.accessToken.expiry; // Store expiry

    return _cachedToken!;
  }

  // Send One Notification
  static Future<void> sendOneNotification({
    required String token,
    required String title,
    required String body,
    required bool isPayment,
    required bool isSaveNotification,
    required Map<String, dynamic> payload,
    bool isNewOrder = false,
  }) async {
    // Save notification in Firestore if required
    NotificationModel notificationModel = NotificationModel();
    notificationModel.id = Constant.getUuid();
    notificationModel.type = payload['type'] ?? 'general';
    notificationModel.title = title;
    notificationModel.description = body;
    notificationModel.isRead = false;
    notificationModel.adId = payload['adId'] ?? '';
    notificationModel.chatRoomId = payload['chatRoomId'] ?? '';
    notificationModel.receiverId = payload['receiverId'] ?? '';
    notificationModel.senderId = payload['senderId'] ?? '';
    notificationModel.userType = payload['userType'] ?? '';
    notificationModel.createdAt = Timestamp.now();

    if (isSaveNotification) {
      await FireStoreUtils.setNotification(notificationModel);
    }

    // Prepare payload
    final mergedPayload = {
      ...payload,
      'isNewOrder': isNewOrder ? 'true' : 'false',
    };

    // Prepare message for FCM
    final message = {
      'token': token,
      'data': {
        ...mergedPayload,
        'title': title,
        'body': body,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      }, // Always include data
      'android': {
        'notification': {
          'channel_id': isNewOrder ? 'orders_channel' : 'default_channel',
          'title': title,
          'body': body,
          'sound': isNewOrder ? 'order_sound' : 'default',
        },
      },
      'apns': {
        'headers': {'apns-priority': '10'},
        'payload': {
          'aps': {
            'alert': {'title': title, 'body': body}, // Required for iOS display
            'sound': isNewOrder ? 'order_sound.wav' : 'default',
            'content-available': 1, // Optional: for background updates
          },
        },
      },
    };

    try {
      log("🚀 Step 1: Start notification");
      final accessToken = await getAccessToken();
      log("✅ Step 2: Got access token");
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/${Constant.senderId}/messages:send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'message': message}),
      );
      log("✅ Step 3: FCM Response Code: ${response.statusCode}");
      log("✅ Step 4: FCM Body: ${response.body}");

      log('✅ Notification Response: ${response.body} \n $message');
    } catch (e) {
      log('❌ Error sending notification: $e');
    }
  }

  /// Send notification to a topic (e.g., all admins)
  static Future<void> sendToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic> payload = const {},
  }) async {
    try {
      final message = {
        'topic': topic,
        'data': {...payload.map((k, v) => MapEntry(k, v.toString())), 'title': title, 'body': body},
        'android': {
          'notification': {'channel_id': 'default_channel', 'title': title, 'body': body},
        },
        'apns': {
          'payload': {
            'aps': {'alert': {'title': title, 'body': body}, 'sound': 'default'},
          },
        },
      };

      final accessToken = await getAccessToken();
      await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/${Constant.senderId}/messages:send'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: jsonEncode({'message': message}),
      );
    } catch (e) {
      log('❌ Error sending topic notification: $e');
    }
  }
}
