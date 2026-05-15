import 'dart:async';

import 'package:eSellify/app/models/notification_model.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class NotificationsController extends GetxController {
  RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  RxBool isLoading = true.obs;
  StreamSubscription? _subscription;

  String? get currentUserId => FireStoreUtils.getCurrentUid();

  int get unreadCount => notifications.where((n) => n.isRead != true).length;

  @override
  void onInit() {
    super.onInit();
    _listenToNotifications();
  }

  void _listenToNotifications() {
    final uid = currentUserId;
    if (uid == null) {
      isLoading.value = false;
      return;
    }

    _subscription = FireStoreUtils.getNotificationsStream(uid).listen((list) {
      notifications.value = list;
      isLoading.value = false;
    }, onError: (e) {
      isLoading.value = false;
    });
  }

  Future<void> markAsRead(String notificationId) async {
    await FireStoreUtils.markNotificationRead(notificationId);
  }

  Future<void> markAllAsRead() async {
    final uid = currentUserId;
    if (uid == null) return;
    await FireStoreUtils.markAllNotificationsRead(uid);
  }

  Future<void> deleteNotification(String notificationId) async {
    await FireStoreUtils.deleteNotification(notificationId);
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
