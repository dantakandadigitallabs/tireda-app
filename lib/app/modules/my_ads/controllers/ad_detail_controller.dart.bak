import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eSellify/app/constant/show_toast.dart';
import 'package:eSellify/app/models/ad_model.dart';
import 'package:eSellify/app/models/chat_room_model.dart';
import 'package:eSellify/app/models/user_subscription_model.dart';
import 'package:eSellify/app/modules/subscriptions/views/subscriptions_view.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class AdDetailController extends GetxController {
  late AdModel ad;
  final PageController pageController = PageController();
  RxInt currentIndex = 0.obs;
  RxInt reportCount = 0.obs;
  RxBool isFeatured = false.obs;

  void initFeaturedStatus() {
    isFeatured.value = ad.isFeatured ?? false;
  }

  void loadReportCount() async {
    if (ad.id == null) return;
    reportCount.value = await FireStoreUtils.getAdReportCount(ad.id!);
  }

  List<String> get images => [if (ad.mainImage != null && ad.mainImage!.isNotEmpty) ad.mainImage!, ...?ad.otherImages?.where((u) => u.isNotEmpty)];

  String formatPrice() {
    if (ad.isPriceOptional == true || ad.price == null) return "Negotiable";
    final currency = ad.currency;
    final symbol = currency?.symbol ?? '';
    final decimals = currency?.decimalDigits ?? 0;
    final price = ad.price!.toStringAsFixed(decimals);
    return currency?.symbolAtRight == true ? "$price $symbol".trim() : "$symbol$price".trim();
  }

  String formatDate() {
    if (ad.createdAt == null) return '';
    final dt = ad.createdAt!.toDate();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${dt.day} ${months[dt.month - 1]} ${dt.year}";
  }

  Future<bool> deleteAd() async {
    ShowToastDialog.showLoader("Deleting...");
    final success = await FireStoreUtils.deleteAd(ad.id!);
    ShowToastDialog.closeLoader();

    if (success) {
      ShowToastDialog.showSuccess("Ad deleted successfully!");
    } else {
      ShowToastDialog.showError("Failed to delete. Please try again.");
    }
    return success;
  }

  Future<bool> markAsSold({String? soldToUserId, String? soldToUserName}) async {
    ShowToastDialog.showLoader("Updating...");
    final success = await FireStoreUtils.updateAdStatus(ad.id!, 'sold', false, soldToUserId: soldToUserId, soldToUserName: soldToUserName);
    ShowToastDialog.closeLoader();

    if (success) {
      ShowToastDialog.showSuccess("Ad marked as sold!");
    } else {
      ShowToastDialog.showError("Failed to update. Please try again.");
    }
    return success;
  }

  /// Feature this ad — checks subscription first, shows dialog if needed
  Future<void> featureAd() async {
    final uid = FireStoreUtils.getCurrentUid();
    if (uid == null || ad.id == null) return;

    final activeSub = await FireStoreUtils.getActiveSubscription(uid, 'featured_ads');

    if (activeSub == null) {
      _showFeaturedDialog(
        icon: Icons.star_outline_rounded,
        iconColor: const Color(0xffFF9500),
        title: "No Featured Plan",
        message: "Get a Featured Ads plan to boost your ad visibility and attract more buyers.",
        buttonText: "View Featured Plans",
      );
      return;
    }

    if (!activeSub.isActive) {
      _showFeaturedDialog(
        icon: Icons.timer_off_outlined,
        iconColor: const Color(0xffFF9500),
        title: "Plan Expired",
        message: "Your Featured Ads plan has expired. Renew to continue featuring ads.",
        buttonText: "Renew Plan",
      );
      return;
    }

    // Check real featured count
    if (activeSub.isItemLimitUnlimited != true) {
      final featuredCount = await FireStoreUtils.countUserFeaturedAds(uid);
      if (featuredCount >= (activeSub.adLimit ?? 0)) {
        activeSub.adsPosted = featuredCount;
        _showFeaturedDialog(
          icon: Icons.block_outlined,
          iconColor: AppThemeData.danger300,
          title: "Featured Limit Reached",
          message: "You have $featuredCount featured ads (limit: ${activeSub.adLimit}). Upgrade for more.",
          buttonText: "Upgrade Plan",
          sub: activeSub,
        );
        return;
      }
    }

    // All checks passed — feature the ad
    ShowToastDialog.showLoader("Featuring ad...");

    Timestamp? featuredUntil;
    if (activeSub.expiryDate != null) {
      featuredUntil = activeSub.expiryDate;
    }

    final success = await FireStoreUtils.markAdAsFeatured(ad.id!, featuredUntil);
    if (success) {
      await FireStoreUtils.syncFeaturedAdsPosted(activeSub.id!, uid);
      isFeatured.value = true;
      ad.isFeatured = true;
      ShowToastDialog.closeLoader();
      ShowToastDialog.showSuccess("Ad is now featured!");
    } else {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showError("Failed to feature ad");
    }
  }

  void _showFeaturedDialog({
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
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.15 : 0.1),
                  shape: BoxShape.circle,
                ),
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
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xffFF9500).withValues(alpha: 0.15) : const Color(0xffFF9500).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded, size: 16, color: Color(0xffFF9500)),
                      spaceW(width: 6),
                      TextCustom(title: "Featured: ${sub.adsPosted ?? 0}/${sub.adLimit ?? 0} used", fontSize: 13, fontFamily: FontFamily.semiBold, color: const Color(0xffFF9500)),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffFF9500),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(fontSize: 15, fontFamily: FontFamily.semiBold, color: Colors.white),
                  ),
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

  /// Remove featured status
  Future<void> removeFeature() async {
    if (ad.id == null) return;
    ShowToastDialog.showLoader("Removing featured...");
    final success = await FireStoreUtils.removeAdFeatured(ad.id!);
    ShowToastDialog.closeLoader();
    if (success) {
      isFeatured.value = false;
      ad.isFeatured = false;
      ShowToastDialog.showSuccess("Featured status removed");
    } else {
      ShowToastDialog.showError("Failed to remove featured status");
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}

/// Controller for the "Who bought?" screen
class WhoBoughtController extends GetxController {
  late AdModel ad;
  RxList<ChatRoomModel> chatRooms = <ChatRoomModel>[].obs;
  RxBool isLoading = true.obs;
  Rx<String?> selectedBuyerId = Rx<String?>(null);
  Rx<String?> selectedBuyerName = Rx<String?>(null);

  String get currentUserId => FireStoreUtils.getCurrentUid() ?? '';

  void initWithAd(AdModel adModel) {
    ad = adModel;
    _loadBuyers();
  }

  Future<void> _loadBuyers() async {
    final rooms = await FireStoreUtils.getChatRoomsForAd(ad.id!);
    chatRooms.value = rooms;
    isLoading.value = false;
  }

  void selectBuyer(String id, String name) {
    selectedBuyerId.value = id;
    selectedBuyerName.value = name;
  }

  void selectNone() {
    selectedBuyerId.value = 'none';
    selectedBuyerName.value = null;
  }

  Future<bool> markSold() async {
    ShowToastDialog.showLoader("Updating...");
    final success = await FireStoreUtils.updateAdStatus(
      ad.id!,
      'sold',
      false,
      soldToUserId: selectedBuyerId.value == 'none' ? null : selectedBuyerId.value,
      soldToUserName: selectedBuyerName.value,
    );
    ShowToastDialog.closeLoader();

    if (success) {
      ShowToastDialog.showSuccess("Ad marked as sold!");
    } else {
      ShowToastDialog.showError("Failed to update. Please try again.");
    }
    return success;
  }

  String formatPrice() {
    if (ad.isPriceOptional == true || ad.price == null) return "Negotiable";
    final c = ad.currency;
    final s = c?.symbol ?? '';
    final d = c?.decimalDigits ?? 0;
    final p = ad.price!.toStringAsFixed(d);
    return c?.symbolAtRight == true ? "$p $s".trim() : "$s$p".trim();
  }
}
