import 'package:cached_network_image/cached_network_image.dart';
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/dependency/shimmer.dart';
import 'package:eSellify/app/models/ad_model.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/ad_banner_widget.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../controllers/my_purchases_controller.dart';

class MyPurchasesView extends GetView<MyPurchasesController> {
  const MyPurchasesView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return GetX(
      init: MyPurchasesController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
          appBar: AppBar(
            backgroundColor: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
            elevation: 0,
            leading: IconButton(onPressed: () => Get.back(), icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10)),
            title: TextCustom(title: "My Purchases".tr, fontSize: 18, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
          ),
          body: Column(
            children: [
              const Center(child: AdBannerWidget()),
              Expanded(
                child: controller.isLoading.value
                    ? _buildShimmer(isDark)
                    : controller.purchases.isEmpty
                        ? _buildEmpty(isDark)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            itemCount: controller.purchases.length,
                            itemBuilder: (context, index) {
                              final ad = controller.purchases[index];
                              return _PurchaseCard(ad: ad, controller: controller, isDark: isDark);
                            },
                          ),
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
          Container(height: 80, width: 80, decoration: BoxDecoration(color: isDark ? AppThemeData.grey8 : AppThemeData.grey2, shape: BoxShape.circle), child: Icon(Icons.shopping_bag_outlined, size: 36, color: isDark ? AppThemeData.grey5 : AppThemeData.grey5)),
          spaceH(height: 20),
          TextCustom(title: "No purchases yet".tr, fontSize: 16, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
          spaceH(height: 6),
          TextCustom(title: "Products you buy will appear here".tr, fontSize: 13, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5),
        ],
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    final base = isDark ? AppThemeData.grey9 : AppThemeData.grey3;
    final highlight = isDark ? AppThemeData.grey8 : AppThemeData.grey2;
    final color = isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(height: 120, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14))),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PURCHASE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _PurchaseCard extends StatelessWidget {
  final AdModel ad;
  final MyPurchasesController controller;
  final bool isDark;

  const _PurchaseCard({required this.ad, required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final currency = ad.currency?.symbol ?? Constant.currencyModel?.symbol ?? '\$';
    final decimals = ad.currency?.decimalDigits ?? Constant.currencyModel?.decimalDigits ?? 2;
    final price = ad.isJobAd
        ? ad.formattedSalary()
        : (ad.price != null ? '$currency${ad.price!.toStringAsFixed(decimals)}' : 'Negotiable'.tr);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3, width: 0.5),
      ),
      child: Column(
        children: [
          // Ad info
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: (ad.mainImage != null && ad.mainImage!.isNotEmpty)
                      ? CachedNetworkImage(imageUrl: ad.mainImage!, height: 64, width: 64, fit: BoxFit.cover)
                      : Container(height: 64, width: 64, color: isDark ? AppThemeData.grey9 : AppThemeData.grey2, child: Icon(Icons.image_outlined, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5)),
                ),
                spaceW(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextCustom(title: ad.titleFor(Get.locale?.languageCode), fontSize: 15, fontFamily: FontFamily.semiBold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10, maxLine: 1),
                      spaceH(height: 3),
                      TextCustom(title: price, fontSize: 14, fontFamily: FontFamily.bold, color: AppThemeData.primary4),
                      spaceH(height: 3),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 13, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                          spaceW(width: 4),
                          TextCustom(title: "${'Seller:'.tr} ${ad.sellerName ?? ''}", fontSize: 12, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6, maxLine: 1),
                        ],
                      ),
                    ],
                  ),
                ),
                // Sold badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xff007AFF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: TextCustom(title: "Purchased".tr, fontSize: 10, fontFamily: FontFamily.bold, color: const Color(0xff007AFF)),
                ),
              ],
            ),
          ),

          // Review section
          Divider(height: 1, color: isDark ? AppThemeData.grey8 : AppThemeData.grey3),
          Obx(() {
            final reviewed = controller.isReviewed(ad.id ?? '');
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: reviewed
                  ? Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: const Color(0xff4CAF50)),
                        spaceW(width: 8),
                        TextCustom(title: "Review submitted".tr, fontSize: 13, fontFamily: FontFamily.medium, color: const Color(0xff4CAF50)),
                      ],
                    )
                  : GestureDetector(
                      onTap: () => _showReviewDialog(context, ad, controller, isDark),
                      child: Row(
                        children: [
                          Icon(Icons.star_border_rounded, size: 18, color: const Color(0xffFF9500)),
                          spaceW(width: 8),
                          TextCustom(title: "Rate this seller".tr, fontSize: 13, fontFamily: FontFamily.semiBold, color: const Color(0xffFF9500)),
                          const Spacer(),
                          Icon(Icons.chevron_right, size: 20, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                        ],
                      ),
                    ),
            );
          }),
        ],
      ),
    );
  }

  void _showReviewDialog(BuildContext context, AdModel ad, MyPurchasesController controller, bool isDark) {
    final rating = 0.0.obs;
    final commentController = TextEditingController();

    Get.dialog(
      Dialog(
        backgroundColor: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Seller avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: isDark ? AppThemeData.grey8 : AppThemeData.grey3,
                backgroundImage: (ad.sellerProfile != null && ad.sellerProfile!.isNotEmpty) ? CachedNetworkImageProvider(ad.sellerProfile!) : null,
                child: (ad.sellerProfile == null || ad.sellerProfile!.isEmpty) ? Icon(Icons.person, size: 28, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6) : null,
              ),
              spaceH(height: 12),
              TextCustom(title: "${'Rate'.tr} ${ad.sellerName ?? 'Seller'.tr}", fontSize: 17, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10, textAlign: TextAlign.center),
              spaceH(height: 4),
              TextCustom(title: "${'for'.tr} \"${ad.titleFor(Get.locale?.languageCode)}\"", fontSize: 12, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6, textAlign: TextAlign.center, maxLine: 1),
              spaceH(height: 16),

              // Star rating
              Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => rating.value = index + 1.0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < rating.value ? Icons.star_rounded : Icons.star_border_rounded,
                            size: 36,
                            color: index < rating.value ? const Color(0xffFF9500) : (isDark ? AppThemeData.grey6 : AppThemeData.grey4),
                          ),
                        ),
                      );
                    }),
                  )),
              spaceH(height: 16),

              // Comment
              TextField(
                controller: commentController,
                maxLines: 3,
                style: TextStyle(fontSize: 14, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                decoration: InputDecoration(
                  hintText: "Write your experience (optional)...".tr,
                  hintStyle: TextStyle(fontSize: 13, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                  filled: true,
                  fillColor: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              spaceH(height: 20),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (rating.value == 0) {
                      Get.snackbar("Rating Required".tr, "Please select at least 1 star".tr);
                      return;
                    }
                    Get.back();
                    controller.submitReview(ad: ad, rating: rating.value, comment: commentController.text);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffFF9500), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                  child: Text("Submit Review".tr, style: const TextStyle(fontSize: 15, fontFamily: FontFamily.semiBold, color: Colors.white)),
                ),
              ),
              spaceH(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: TextCustom(title: "Cancel".tr, fontSize: 14, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey4 : AppThemeData.grey5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
