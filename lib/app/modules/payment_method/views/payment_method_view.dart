import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/dependency/shimmer.dart';
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
        final packageName = pkg.name?.values.firstOrNull ?? 'Package';
        final originalPrice = pkg.price ?? 0;
        final finalPrice = pkg.finalPrice ?? originalPrice;
        final hasDiscount = (pkg.discountPercentage ?? 0) > 0;
        final currencySymbol = Constant.currencyModel?.symbol ?? '\$';

        return Scaffold(
          backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
          appBar: UiInterface.customAppBar(context, themeChange, "Payment", isBack: true),
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
                                        pkg.type == 'featured_ads' ? 'Featured Ads Package' : 'Ad Listing Package',
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
                                      '${pkg.discountPercentage!.toInt()}% OFF',
                                      style: const TextStyle(fontSize: 11, fontFamily: FontFamily.bold, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            spaceH(height: 8),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                                spaceW(width: 6),
                                Text(
                                  pkg.isUnlimited == true ? 'Unlimited Duration' : '${pkg.packageDuration ?? 0} Days',
                                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                                ),
                                spaceW(width: 16),
                                Icon(Icons.inventory_2_outlined, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                                spaceW(width: 6),
                                Text(
                                  pkg.isItemLimitUnlimited == true ? 'Unlimited Ads' : '${pkg.itemLimit ?? 0} Ads',
                                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      spaceH(height: 24),

                      // Payment methods
                      TextCustom(title: "Select Payment Method", fontSize: 16, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
                      spaceH(height: 12),

                      if (controller.activeGateways.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite, borderRadius: BorderRadius.circular(14)),
                          child: Column(
                            children: [
                              Icon(Icons.payment, size: 48, color: isDark ? AppThemeData.grey5 : AppThemeData.grey5),
                              spaceH(height: 12),
                              TextCustom(title: "No payment methods available", fontSize: 14, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
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
                                            : Icon(
                                                isWallet ? Icons.account_balance_wallet_rounded : isCash ? Icons.money_rounded : Icons.payment_rounded,
                                                size: 22,
                                                color: isSelected ? AppThemeData.primary4 : (isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                                              ),
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
                                      child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
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
                              const Text(
                                "Processing...",
                                style: TextStyle(fontSize: 16, fontFamily: FontFamily.semiBold, color: Colors.white),
                              ),
                            ],
                          )
                        : Text(
                            "Pay $currencySymbol${finalPrice.toStringAsFixed(2)}",
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
