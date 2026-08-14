import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/common_ui.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hugeicons/hugeicons.dart';
import '../controllers/payment_method_controller.dart';

class PaymentMethodView extends GetView<PaymentMethodController> {
  const PaymentMethodView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return GetX(
      init: PaymentMethodController(),
      builder: (controller) {
        final pkg = controller.package;
        // Tireda Custom Merge (eSellify 1.5): localize the package name via
        // the model's helper — falls back through
        // `map[code] → default → en → first non-empty` so the header
        // always matches the app's selected language.
        final packageName = () {
          final n = pkg.nameFor(Get.locale?.languageCode);
          return n.isNotEmpty ? n : 'Package'.tr;
        }();
        final originalPrice = pkg.price ?? 0;
        final finalPrice = pkg.finalPrice ?? originalPrice;
        final hasDiscount = (pkg.discountPercentage ?? 0) > 0;
        final currencySymbol = Constant.currencyModel?.symbol ?? '\$';

        return Scaffold(
          backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
          appBar: UiInterface.customAppBar(context, themeChange, "Payment".tr, isBack: true),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Package summary card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppThemeData.primary4, AppThemeData.primary4.withValues(alpha: 0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (pkg.image != null && pkg.image!.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: CachedNetworkImage(imageUrl: pkg.image!, height: 50, width: 50, fit: BoxFit.cover),
                                  ),
                                if (pkg.image != null && pkg.image!.isNotEmpty) spaceW(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        packageName,
                                        style: const TextStyle(fontSize: 18, fontFamily: FontFamily.bold, color: Colors.white),
                                      ),
                                      spaceH(height: 4),
                                      Text(
                                        pkg.type == 'featured_ads' ? 'Featured Ads Package'.tr : 'Ad Listing Package'.tr,
                                        style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            spaceH(height: 16),
                            Row(
                              children: [
                                if (hasDiscount) ...[
                                  Text(
                                    '$currencySymbol${originalPrice.toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.6), decoration: TextDecoration.lineThrough),
                                  ),
                                  spaceW(width: 10),
                                ],
                                Text(
                                  '$currencySymbol${finalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 26, fontFamily: FontFamily.bold, color: Colors.white),
                                ),
                                if (hasDiscount) ...[
                                  spaceW(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                                    child: Text(
                                      '${pkg.discountPercentage!.toInt()}% ${'OFF'.tr}',
                                      style: const TextStyle(fontSize: 11, fontFamily: FontFamily.bold, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            spaceH(height: 8),
                            Row(
                              children: [
                                // Tireda Custom: HugeIcons — 1.5 base reverted
                                // these to plain Material Icons; not taken,
                                // conflicts with the app-wide HugeIcons standard.
                                HugeIcon(
                                  icon: HugeIcons.strokeRoundedTime02,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  size: 14.0,
                                ),
                                spaceW(width: 6),
                                Text(
                                  pkg.isUnlimited == true ? 'Unlimited Duration'.tr : '${pkg.packageDuration ?? 0} ${'Days'.tr}',
                                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                                ),
                                spaceW(width: 16),
                                HugeIcon(
                                  icon: HugeIcons.strokeRoundedArchive,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  size: 14.0,
                                ),
                                spaceW(width: 6),
                                Text(
                                  pkg.isItemLimitUnlimited == true ? 'Unlimited Ads'.tr : '${pkg.itemLimit ?? 0} ${'Ads'.tr}',
                                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      spaceH(height: 24),

                      // Payment methods
                      TextCustom(title: "Select Payment Method".tr, fontSize: 16, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                      spaceH(height: 12),

                      if (controller.activeGateways.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite, borderRadius: BorderRadius.circular(14)),
                          child: Column(
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedCreditCard,
                                color: isDark ? AppThemeData.grey5 : AppThemeData.grey5,
                                size: 48.0,
                              ),
                              spaceH(height: 12),
                              TextCustom(title: "No payment methods available".tr, fontSize: 14, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                            ],
                          ),
                        )
                      else
                        ...controller.activeGateways.map((gateway) {
                          final isSelected = controller.selectedMethod.value == gateway['key'];
                          final isWallet = gateway['isWallet'] == true;
                          final isCash = gateway['isCash'] == true;
                          final hasImage = gateway['icon'] != null && gateway['icon'].toString().isNotEmpty;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              onTap: () => controller.selectedMethod.value = gateway['key'],
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: isSelected ? AppThemeData.primary4 : (isDark ? AppThemeData.grey8 : AppThemeData.grey3), width: isSelected ? 1.5 : 0.5),
                                ),
                                child: Row(
                                  children: [
                                    // Gateway icon
                                    Container(
                                      height: 44,
                                      width: 44,
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppThemeData.primary4.withValues(alpha: 0.1) : (isDark ? AppThemeData.grey9 : AppThemeData.grey2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: hasImage
                                            ? ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: Image.asset(gateway['icon'], height: 28, width: 28, fit: BoxFit.contain),
                                        )
                                            : HugeIcon(
                                          icon: isWallet
                                              ? HugeIcons.strokeRoundedWallet01
                                              : isCash
                                              ? HugeIcons.strokeRoundedMoney01
                                              : HugeIcons.strokeRoundedCreditCard,
                                          color: isSelected ? AppThemeData.primary4 : (isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                                          size: 22.0,
                                        ),
                                      ),
                                    ),
                                    spaceW(width: 14),
                                    // Gateway name — pulled from the
                                    // admin's Payment Methods settings.
                                    Expanded(
                                      child: TextCustom(
                                        title: (gateway['name'] ?? gateway['key'].toString().capitalizeFirst ?? 'Payment Method'.tr).toString(),
                                        fontSize: 15,
                                        fontFamily: FontFamily.semiBold,
                                        color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                                        maxLine: 1,
                                      ),
                                    ),
                                    // Radio
                                    Container(
                                      height: 22,
                                      width: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: isSelected ? AppThemeData.primary4 : (isDark ? AppThemeData.grey6 : AppThemeData.grey5), width: 2),
                                        color: isSelected ? AppThemeData.primary4 : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? const HugeIcon(
                                        icon: HugeIcons.strokeRoundedTick01,
                                        color: Colors.white,
                                        size: 14.0,
                                      )
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),

              // Pay Now button
              Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: controller.isProcessing.value ? null : () => controller.processPayment(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: controller.isProcessing.value ? (isDark ? AppThemeData.grey7 : AppThemeData.grey4) : AppThemeData.primary4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: controller.isProcessing.value
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        spaceW(width: 12),
                        Text(
                          "Processing...".tr,
                          style: const TextStyle(fontSize: 16, fontFamily: FontFamily.semiBold, color: Colors.white),
                        ),
                      ],
                    )
                        : Text(
                      "${'Pay'.tr} $currencySymbol${finalPrice.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 16, fontFamily: FontFamily.semiBold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}