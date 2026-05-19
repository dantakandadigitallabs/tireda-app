import 'dart:async'; // Add this

import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/models/user_subscription_model.dart';
import 'package:eSellify/app/modules/chats/views/chats_view.dart';
import 'package:eSellify/app/modules/home/views/home_view.dart';
import 'package:eSellify/app/modules/my_ads/views/my_ads_view.dart';
import 'package:eSellify/app/modules/profile/views/profile_view.dart';
import 'package:eSellify/app/modules/sell_screen/views/sell_screen_view.dart';
import 'package:eSellify/app/modules/subscriptions/views/subscriptions_view.dart';
import 'package:eSellify/app/routes/app_pages.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class DashboardScreenController extends GetxController {
  RxBool isLoading = true.obs;

  RxInt selectedIndex = 0.obs;
  RxList pageList = [const HomeView(), const ChatsView(), const SellScreenView(), const MyAdsView(), const ProfileView()].obs;

  RxString userName = "".obs;
  RxString userEmail = "".obs;
  RxString profileImage = "".obs;

  // ── NEW: Chat Notification State ──
  RxBool hasUnreadMessages = false.obs;
  StreamSubscription? _chatSubscription;

  @override
  void onInit() {
    super.onInit();
    getUserData();
    _listenForUnreadChats(); // Start listening on launch
  }

  void getUserData() {
    if (Constant.userModel != null) {
      userName.value = Constant.userModel!.fullNameString();
      userEmail.value = Constant.userModel!.email ?? "user@example.com";
      profileImage.value = Constant.userModel!.profilePic ?? "";
    } else {
      userName.value = "User";
      userEmail.value = "user@example.com";
      profileImage.value = "";
    }
    isLoading.value = false;
  }

  // ── NEW: Background Chat Stream ──
  void _listenForUnreadChats() {
    final uid = FireStoreUtils.getCurrentUid();
    if (uid == null) return;

    _chatSubscription = FireStoreUtils.getChatRoomsStream(uid).listen((rooms) {
      int totalUnread = 0;
      for (var room in rooms) {
        totalUnread += room.myUnreadCount(uid);
      }
      hasUnreadMessages.value = totalUnread > 0;
    });
  }

  void changeIndex(int index) {
    selectedIndex.value = index;
  }

  Future<void> onSellTap() async {
    // ... [Your existing Sell Tap Logic remains unchanged] ...
    if (Constant.freeAdListing) {
      selectedIndex.value = 2;
      return;
    }

    final uid = FireStoreUtils.getCurrentUid();
    if (uid == null) {
      selectedIndex.value = 2;
      return;
    }

    final activeSub = await FireStoreUtils.getActiveSubscription(uid, 'ad_listing');

    if (activeSub == null) {
      _showSubscriptionDialog(
        icon: Icons.inventory_2_outlined,
        iconColor: AppThemeData.primary4,
        title: "No Active Plan",
        message: "You need a subscription plan to post ads. Choose a plan to get started.",
        buttonText: "View Plans",
      );
      return;
    }

    if (!activeSub.isActive) {
      _showSubscriptionDialog(
        icon: Icons.timer_off_outlined,
        iconColor: const Color(0xffFF9500),
        title: "Plan Expired",
        message: "Your subscription plan has expired. Renew or choose a new plan to continue posting ads.",
        buttonText: "Renew Plan",
      );
      return;
    }

    if (activeSub.isItemLimitUnlimited != true) {
      final activeAdCount = await FireStoreUtils.countUserActiveAds(uid);
      if (activeAdCount >= (activeSub.adLimit ?? 0)) {
        activeSub.adsPosted = activeAdCount;
        _showSubscriptionDialog(
          icon: Icons.block_outlined,
          iconColor: AppThemeData.danger300,
          title: "Ad Limit Reached",
          message: "You have $activeAdCount active ads (limit: ${activeSub.adLimit}). Upgrade to post more.",
          buttonText: "Upgrade Plan",
          sub: activeSub,
        );
        return;
      }
    }

    selectedIndex.value = 2;
  }

  void _showSubscriptionDialog({
    // ... [Your existing dialog logic remains unchanged] ...
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String buttonText,
    UserSubscriptionModel? sub,
  }) {
    final isDark = Provider.of<DarkThemeProvider>(Get.context!, listen: false).isDarkTheme();
    Get.dialog(
      Dialog(
        backgroundColor: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(color: iconColor.withValues(alpha: isDark ? 0.15 : 0.1), shape: BoxShape.circle),
                child: Icon(icon, size: 32, color: iconColor),
              ),
              spaceH(height: 16),
              TextCustom(title: title, fontSize: 18, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10, textAlign: TextAlign.center),
              spaceH(height: 10),
              TextCustom(title: message, fontSize: 13, color: isDark ? AppThemeData.grey4 : AppThemeData.grey6, textAlign: TextAlign.center, maxLine: 3),
              if (sub != null) ...[
                spaceH(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: isDark ? AppThemeData.grey9 : AppThemeData.grey2, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextCustom(title: "Ads used: ${sub.adsPosted ?? 0}/${sub.adLimit ?? 0}", fontSize: 13, fontFamily: FontFamily.semiBold, color: AppThemeData.danger300),
                    ],
                  ),
                ),
              ],
              spaceH(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    Get.to(() => const SubscriptionsView());
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppThemeData.primary4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                  child: Text(buttonText, style: const TextStyle(fontSize: 15, fontFamily: FontFamily.semiBold, color: Colors.white)),
                ),
              ),
              spaceH(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: TextCustom(title: "Maybe Later", fontSize: 14, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey4 : AppThemeData.grey5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void logout() {
    Get.offAllNamed(Routes.LOGIN_SCREEN);
  }

  @override
  void onClose() {
    _chatSubscription?.cancel(); // Don't forget to close the stream!
    super.onClose();
  }
}