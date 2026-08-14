import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eSellify/app/dependency/shimmer.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/utils/notifications/notification_router.dart';
import 'package:eSellify/widgets/ad_banner_widget.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../controllers/notifications_controller.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return GetX(
      init: NotificationsController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
          appBar: AppBar(
            backgroundColor: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Get.back(),
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
            ),
            title: TextCustom(title: "Notifications".tr, fontSize: 18, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
            actions: [
              if (controller.unreadCount > 0)
                TextButton(
                  onPressed: () => controller.markAllAsRead(),
                  child: TextCustom(title: "Read all".tr, fontSize: 13, fontFamily: FontFamily.medium, color: AppThemeData.primary4),
                ),
            ],
          ),
          body: Column(
            children: [
              const Center(child: AdBannerWidget()),
              Expanded(
                child: controller.isLoading.value
                    ? _buildShimmer(isDark)
                    : controller.notifications.isEmpty
                    ? _buildEmpty(isDark)
                    : _buildList(controller, isDark),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(color: isDark ? AppThemeData.grey8 : AppThemeData.grey2, shape: BoxShape.circle),
            child: Icon(Icons.notifications_none_rounded, size: 36, color: isDark ? AppThemeData.grey5 : AppThemeData.grey5),
          ),
          spaceH(height: 20),
          TextCustom(title: "No notifications yet".tr, fontSize: 16, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
          spaceH(height: 6),
          TextCustom(title: "You'll see updates here".tr, fontSize: 13, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5),
        ],
      ),
    );
  }

  Widget _buildList(NotificationsController controller, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: controller.notifications.length,
      itemBuilder: (context, index) {
        final notification = controller.notifications[index];
        final isUnread = notification.isRead != true;

        return Dismissible(
          key: Key(notification.id ?? index.toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(color: AppThemeData.danger300, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
          ),
          onDismissed: (_) => controller.deleteNotification(notification.id!),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () {
                if (isUnread) controller.markAsRead(notification.id!);
                NotificationRouter.handleFromModel(notification);
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isUnread ? AppThemeData.primary4.withValues(alpha: 0.3) : (isDark ? AppThemeData.grey8 : AppThemeData.grey3),
                    width: isUnread ? 1 : 0.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(color: _iconBgColor(notification.type, isDark), borderRadius: BorderRadius.circular(12)),
                      child: Icon(_iconData(notification.type), size: 22, color: _iconColor(notification.type)),
                    ),
                    spaceW(width: 14),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          TextCustom(
                            title: notification.title ?? 'Notification'.tr,
                            fontSize: 14,
                            fontFamily: isUnread ? FontFamily.bold : FontFamily.medium,
                            color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                            maxLine: 2,
                          ),
                          if (notification.description != null && notification.description!.isNotEmpty) ...[
                            spaceH(height: 4),
                            TextCustom(
                              title: notification.description!,
                              fontSize: 12,
                              fontFamily: FontFamily.regular,
                              color: isDark ? AppThemeData.grey4 : AppThemeData.grey6,
                              maxLine: 2,
                            ),
                          ],
                          spaceH(height: 6),
                          // Time
                          TextCustom(title: _timeAgo(notification.createdAt), fontSize: 11, color: isDark ? AppThemeData.grey5 : AppThemeData.grey5),
                        ],
                      ),
                    ),
                    // Unread dot
                    if (isUnread)
                      Container(
                        margin: const EdgeInsets.only(top: 4, left: 8),
                        height: 8,
                        width: 8,
                        decoration: BoxDecoration(color: AppThemeData.primary4, shape: BoxShape.circle),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  IconData _iconData(String? type) {
    switch (type) {
      case 'chat':
        return Icons.chat_bubble_outline_rounded;
      case 'offer_response':
        return Icons.local_offer_rounded;
      case 'ad_approved':
      case 'ad_active':
        return Icons.check_circle_outline_rounded;
      case 'ad_rejected':
      case 'ad_soft_rejected':
      case 'ad_permanent_rejected':
        return Icons.cancel_outlined;
      case 'ad_inactive':
      case 'ad_disabled':
        return Icons.block_outlined;
      case 'ad_expired':
        return Icons.timer_off_outlined;
      case 'ad_liked':
        return Icons.favorite_border_rounded;
      case 'job_application':
        return Icons.work_outline_rounded;
      case 'job_application_status':
        return Icons.assignment_turned_in_outlined;
      case 'verification_approved':
        return Icons.verified_outlined;
      case 'verification_rejected':
        return Icons.gpp_bad_outlined;
      case 'welcome':
        return Icons.celebration_outlined;
      case 'broadcast_promotion':
        return Icons.local_offer_outlined;
      case 'broadcast_info':
        return Icons.info_outline_rounded;
      case 'broadcast_update':
        return Icons.system_update_outlined;
      case 'broadcast_announcement':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _iconColor(String? type) {
    switch (type) {
      case 'chat':
        return AppThemeData.primary4;
      case 'offer_response':
        return const Color(0xffFF9500);
      case 'ad_approved':
      case 'ad_active':
      case 'verification_approved':
        return const Color(0xff4CAF50);
      case 'ad_rejected':
      case 'ad_soft_rejected':
      case 'ad_permanent_rejected':
      case 'verification_rejected':
        return AppThemeData.danger300;
      case 'ad_inactive':
      case 'ad_disabled':
      case 'ad_expired':
        return const Color(0xff8E8E93);
      case 'ad_liked':
        return const Color(0xffE91E63);
      case 'job_application':
        return AppThemeData.primary4;
      case 'job_application_status':
        return const Color(0xff4CAF50);
      case 'welcome':
      case 'broadcast_announcement':
        return const Color(0xffFF9500);
      case 'broadcast_promotion':
        return AppThemeData.primary4;
      case 'broadcast_info':
        return const Color(0xff2196F3);
      case 'broadcast_update':
        return const Color(0xff4CAF50);
      default:
        return AppThemeData.primary4;
    }
  }

  Color _iconBgColor(String? type, bool isDark) {
    return _iconColor(type).withValues(alpha: isDark ? 0.15 : 0.1);
  }

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return 'Just now'.tr;
    if (diff.inMinutes < 60) return '${diff.inMinutes}${'m ago'.tr}';
    if (diff.inHours < 24) return '${diff.inHours}${'h ago'.tr}';
    if (diff.inDays == 1) return 'Yesterday'.tr;
    if (diff.inDays < 7) return '${diff.inDays}${'d ago'.tr}';
    final dt = ts.toDate();
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  // ─── Shimmer ──────────────────────────────────────────────────────────────

  Widget _buildShimmer(bool isDark) {
    final base = isDark ? AppThemeData.grey9 : AppThemeData.grey3;
    final highlight = isDark ? AppThemeData.grey8 : AppThemeData.grey2;
    final color = isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(12)),
                ),
                spaceW(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: 200,
                        decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4)),
                      ),
                      spaceH(height: 8),
                      Container(
                        height: 12,
                        width: 150,
                        decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4)),
                      ),
                      spaceH(height: 8),
                      Container(
                        height: 10,
                        width: 60,
                        decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
