import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/dependency/shimmer.dart';
import 'package:eSellify/app/models/subscription_package_model.dart';
import 'package:eSellify/app/models/user_subscription_model.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/common_ui.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/network_image_widget.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../controllers/subscriptions_controller.dart';

class SubscriptionsView extends GetView<SubscriptionsController> {
  const SubscriptionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return GetX(
      init: SubscriptionsController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
          appBar: UiInterface.customAppBar(context, themeChange, "Subscription Plans"),
          body: controller.isLoading.value
              ? _buildShimmer(isDark)
              : Column(
                  children: [
                    // Tab switcher
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _buildTabSection(controller, isDark),
                    ),
                    spaceH(height: 12),
                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        child: Column(
                          children: [
                            // Active plan banner
                            _buildActivePlanBanner(controller, isDark),
                            // Package list
                            controller.selectedTab.value == 0
                                ? _buildPackageList(controller.adsListingPackages, controller, isDark)
                                : _buildPackageList(controller.featuredAdsPackages, controller, isDark),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  // ─── Tab Section ───────────────────────────────────────────────────────────
  Widget _buildTabSection(SubscriptionsController controller, bool isDark) {
    return Container(
      height: 44,
      decoration: BoxDecoration(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3, borderRadius: BorderRadius.circular(30)),
      child: Row(children: [_buildTabButton("Ad Listing", 0, controller, isDark), _buildTabButton("Featured Ads", 1, controller, isDark)]),
    );
  }

  Widget _buildTabButton(String title, int index, SubscriptionsController controller, bool isDark) {
    final isActive = controller.selectedTab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.changeTab(index),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(color: isActive ? AppThemeData.primary4 : Colors.transparent, borderRadius: BorderRadius.circular(30)),
          child: TextCustom(
            title: title,
            fontSize: isActive ? 15 : 14,
            fontFamily: isActive ? FontFamily.semiBold : FontFamily.regular,
            color: isActive ? Colors.white : (isDark ? AppThemeData.grey4 : AppThemeData.grey7),
          ),
        ),
      ),
    );
  }

  // ─── Active Plan Banner ────────────────────────────────────────────────────
  Widget _buildActivePlanBanner(SubscriptionsController controller, bool isDark) {
    final activeSub = controller.selectedTab.value == 0 ? controller.activeAdListingSub.value : controller.activeFeaturedSub.value;

    if (activeSub == null || !activeSub.isActive) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xff4CAF50), const Color(0xff4CAF50).withValues(alpha: 0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              spaceW(width: 8),
              Text("Active Plan".tr, style: const TextStyle(fontSize: 14, fontFamily: FontFamily.bold, color: Colors.white)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(activeSub.packageName ?? '', style: const TextStyle(fontSize: 12, fontFamily: FontFamily.semiBold, color: Colors.white)),
              ),
            ],
          ),
          spaceH(height: 12),
          Row(
            children: [
              // Ads used
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Ads Posted".tr, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
                    spaceH(height: 2),
                    Text(
                      activeSub.isItemLimitUnlimited == true ? "${activeSub.adsPosted ?? 0} / Unlimited" : "${activeSub.adsPosted ?? 0} / ${activeSub.adLimit ?? 0}",
                      style: const TextStyle(fontSize: 15, fontFamily: FontFamily.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Days remaining
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Days Remaining".tr, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
                    spaceH(height: 2),
                    Text(
                      activeSub.daysRemaining == -1 ? "Unlimited" : "${activeSub.daysRemaining} days",
                      style: const TextStyle(fontSize: 15, fontFamily: FontFamily.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Progress bar for ad usage
          if (activeSub.isItemLimitUnlimited != true && (activeSub.adLimit ?? 0) > 0) ...[
            spaceH(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ((activeSub.adsPosted ?? 0) / (activeSub.adLimit ?? 1)).clamp(0.0, 1.0),
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Package List ──────────────────────────────────────────────────────────
  Widget _buildPackageList(List<SubscriptionPackageModel> packages, SubscriptionsController controller, bool isDark) {
    if (packages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: isDark ? AppThemeData.grey6 : AppThemeData.grey5),
              spaceH(height: 12),
              TextCustom(title: "No packages available".tr, fontSize: 14, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final package = packages[index];
        return _PackageCard(package: package, controller: controller, isDark: isDark);
      },
    );
  }

  // ─── Shimmer ───────────────────────────────────────────────────────────────
  Widget _buildShimmer(bool isDark) {
    final base = isDark ? AppThemeData.grey9 : AppThemeData.grey3;
    final highlight = isDark ? AppThemeData.grey8 : AppThemeData.grey2;
    final color = isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(height: 44, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(30))),
            spaceH(height: 16),
            ...List.generate(3, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(height: 200, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14))),
            )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PACKAGE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _PackageCard extends StatelessWidget {
  final SubscriptionPackageModel package;
  final SubscriptionsController controller;
  final bool isDark;

  const _PackageCard({required this.package, required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isActive = controller.isActivePlan(package);
    // Tireda Custom: grey out (but keep tappable) "Buy Again" for a free
    // package the user has already redeemed — see hasUsedFreePlan() /
    // usedFreeAdListing / usedFreeFeaturedAds. Tapping still shows the
    // explanatory toast from purchasePackage()'s guard clause; this is
    // purely a visual hint, not a second enforcement point.
    final isFreePackage = (package.finalPrice ?? package.price ?? 0) <= 0;
    final alreadyUsedFree = isFreePackage &&
        (package.type == 'ad_listing' ? controller.usedFreeAdListing.value : controller.usedFreeFeaturedAds.value);
    final name = package.name?['en'] ?? '';
    final price = package.price ?? 0;
    final finalPrice = package.finalPrice ?? price;
    final hasDiscount = (package.discountPercentage ?? 0) > 0;
    final currency = Constant.currencyModel?.symbol ?? '\$';
    final decimalDigits = Constant.currencyModel?.decimalDigits ?? 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? AppThemeData.primary4 : (isDark ? AppThemeData.grey8 : AppThemeData.grey3), width: isActive ? 1.5 : 0.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Row 1: Image + Name + Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (package.image != null && package.image!.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: NetworkImageWidget(imageUrl: package.image!, height: 40, width: 40, fit: BoxFit.cover),
                      ),
                      spaceW(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextCustom(title: name, fontSize: 16, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10, maxLine: 1),
                          spaceH(height: 4),
                          // Duration + Ads limit chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _infoChip(Icons.access_time, package.isUnlimited == true ? 'Unlimited' : '${package.packageDuration ?? 0} Days', isDark),
                              _infoChip(Icons.inventory_2_outlined, package.isItemLimitUnlimited == true ? 'Unlimited Ads' : '${package.itemLimit ?? 0} Ads', isDark),
                            ],
                          ),
                        ],
                      ),
                    ),
                    spaceW(width: 8),
                    // Price block
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (hasDiscount)
                          Text('$currency${price.toStringAsFixed(decimalDigits)}', style: TextStyle(fontSize: 11, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6, decoration: TextDecoration.lineThrough, decorationColor: isDark ? AppThemeData.grey5 : AppThemeData.grey6)),
                        Text('$currency${finalPrice.toStringAsFixed(decimalDigits)}', style: TextStyle(fontSize: 18, fontFamily: FontFamily.bold, color: AppThemeData.primary4)),
                        if (hasDiscount)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xff4CAF50).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text('${package.discountPercentage!.toInt()}% OFF', style: const TextStyle(fontSize: 9, fontFamily: FontFamily.bold, color: Color(0xff4CAF50))),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Key points
          if (package.keyPoints != null && package.keyPoints!.isNotEmpty) ...[
            Divider(height: 1, color: isDark ? AppThemeData.grey8 : AppThemeData.grey3),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: package.keyPoints!.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(padding: EdgeInsets.only(top: 1), child: Icon(Icons.check_circle, color: AppThemeData.success300, size: 15)),
                      spaceW(width: 8),
                      Expanded(child: TextCustom(title: feature, fontSize: 12, color: isDark ? AppThemeData.grey4 : AppThemeData.grey6)),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],

          // Tireda Custom: Buy button — always active/tappable, even for the
          // user's current plan. Subscriptions are additive/stackable
          // (see SubscriptionsController.purchasePackage / mergeOrCreateSubscription),
          // so re-buying the same package is a valid action (stacks more ad slots),
          // not a no-op. Previously this rendered an inert "Current Plan" box
          // instead of a button when isActivePlan() was true, which was correct
          // for the old tier-replacement model but blocks legitimate re-purchases
          // now. isActive is still used above for the card's border highlight —
          // that's purely cosmetic and unaffected by this change.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => controller.purchasePackage(package),
                style: ElevatedButton.styleFrom(
                  // Tireda Custom: grey styling only — button stays tappable
                  // so the guard-clause toast in purchasePackage() still fires.
                  backgroundColor: alreadyUsedFree ? (isDark ? AppThemeData.grey7 : AppThemeData.grey4) : AppThemeData.primary4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  isActive ? "Buy Again".tr : "Buy Now".tr,
                  style: TextStyle(fontSize: 15, fontFamily: FontFamily.semiBold, color: alreadyUsedFree ? (isDark ? AppThemeData.grey4 : AppThemeData.grey6) : Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isDark ? AppThemeData.grey4 : AppThemeData.grey6),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey4 : AppThemeData.grey6)),
        ],
      ),
    );
  }
}
