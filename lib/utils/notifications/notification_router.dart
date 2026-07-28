import 'dart:developer' as developer;

import 'package:eSellify/app/models/notification_model.dart';
import 'package:eSellify/app/modules/ad_listing_detail/views/ad_listing_detail_view.dart';
import 'package:eSellify/app/modules/dashboard_screen/controllers/dashboard_screen_controller.dart';
import 'package:eSellify/app/routes/app_pages.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:get/get.dart';
// Tireda Customs. ad details listings stateless refactor. Must use Navigation Helper
import 'package:eSellify/utils/navigation_helper.dart';

class NotificationRouter {
  /// Navigate to the dashboard with a specific tab selected.
  static void _goToDashboardTab(int tabIndex) {
    try {
      final dashController = Get.find<DashboardScreenController>();
      dashController.selectedIndex.value = tabIndex;
      // If we're not on the dashboard, navigate there
      if (Get.currentRoute != Routes.DASHBOARD_SCREEN) {
        Get.offAllNamed(Routes.DASHBOARD_SCREEN);
      }
    } catch (_) {
      // Controller not found — navigate fresh
      Get.offAllNamed(Routes.DASHBOARD_SCREEN);
    }
  }

  /// Route to the correct screen based on notification type and payload.
  static Future<void> handleNotificationTap(Map<String, dynamic> data) async {
    final type = data['type'] as String? ?? '';

    developer.log('Notification tap: type=$type, data=$data');

    switch (type) {
    // ── Chat / Offer ── go to Chat tab (index 1)
      case 'chat':
      case 'offer_response':
        _goToDashboardTab(1);
        break;

    // ── Ad events ── open ad detail
      case 'ad_approved':
      case 'ad_rejected':
      case 'ad_active':
      case 'ad_inactive':
      case 'ad_soft_rejected':
      case 'ad_permanent_rejected':
      case 'ad_disabled':
      case 'ad_liked':
        final adId = data['adId'] as String?;
        if (adId != null && adId.isNotEmpty) {
          final ad = await FireStoreUtils.getAdById(adId);
          if (ad != null) {
            goToAdDetail(ad);
            return;
          }
        }
        // Fallback: go to My Ads tab (index 3)
        _goToDashboardTab(3);
        break;

    // ── Someone you follow posted a new ad ── open ad detail
      case 'followed_seller_new_ad':
        final followedAdId = data['adId'] as String?;
        if (followedAdId != null && followedAdId.isNotEmpty) {
          final ad = await FireStoreUtils.getAdById(followedAdId);
          if (ad != null) {
            goToAdDetail(ad);
            return;
          }
        }
        // Fallback: go to Home tab (0) — not the user's own ad
        _goToDashboardTab(0);
        break;

    // ── New follower ── open the follower's seller profile
      case 'new_follower':
        final followerId = data['senderId'] as String?;
        if (followerId != null && followerId.isNotEmpty) {
          Get.toNamed(Routes.SELLER_REVIEWS, arguments: {'sellerId': followerId, 'sellerName': ''});
          return;
        }
        _goToDashboardTab(0);
        break;

    // ── Job application ── employer opens the applicants list for their ad
      case 'job_application':
        final adId = data['adId'] as String?;
        if (adId != null && adId.isNotEmpty) {
          final ad = await FireStoreUtils.getAdById(adId);
          if (ad != null) {
            Get.toNamed(Routes.JOB_APPLICANTS, arguments: {'adId': adId, 'adTitle': ad.title});
            return;
          }
        }
        // Fallback: go to My Ads tab (index 3)
        _goToDashboardTab(3);
        break;

    // ── Job application status (shortlisted/rejected) ── applicant opens Job Applications
      case 'job_application_status':
        Get.toNamed(Routes.JOB_APPLICATIONS);
        break;

    // ── Verification ──
      case 'verification_approved':
      case 'verification_rejected':
        Get.toNamed(Routes.VERIFICATION);
        break;

    // ── Broadcast ── just open app (stay on home)
      case 'broadcast_promotion':
      case 'broadcast_info':
      case 'broadcast_update':
      case 'broadcast_announcement':
      case 'welcome':
        _goToDashboardTab(0);
        break;

      default:
        developer.log('Unknown notification type: $type');
        break;
    }
  }

  /// Convenience: route from NotificationModel
  static Future<void> handleFromModel(NotificationModel notification) async {
    await handleNotificationTap({
      'type': notification.type ?? '',
      'adId': notification.adId ?? '',
      'chatRoomId': notification.chatRoomId ?? '',
      'receiverId': notification.receiverId ?? '',
      'senderId': notification.senderId ?? '',
    });
  }
}
