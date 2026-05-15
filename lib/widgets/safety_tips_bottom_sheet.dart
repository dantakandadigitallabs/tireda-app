import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

/// OLX-style Safety Tips bottom sheet shown before contacting a seller.
/// Tips are loaded dynamically from Firestore (`safety_tips` collection)
/// into [Constant.safetyTips] at app start.
class SafetyTipsBottomSheet {
  /// Shows the bottom sheet. The [onContinue] callback fires when the user
  /// taps the "Continue" button (after dismissing the sheet).
  ///
  /// If there are no tips configured by admin, the sheet is skipped and
  /// [onContinue] is invoked immediately.
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onContinue,
    String continueLabel = "Continue to offer",
  }) async {
    if (Constant.safetyTips.isEmpty) {
      onContinue();
      return;
    }

    final themeChange = Provider.of<DarkThemeProvider>(context, listen: false);
    final isDark = themeChange.isDarkTheme();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppThemeData.grey10 : AppThemeData.primaryWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppThemeData.grey7 : AppThemeData.grey3,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Shield icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppThemeData.success300.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shield_outlined, color: AppThemeData.success300, size: 28),
                  ),
                  const SizedBox(height: 14),
                  TextCustom(
                    title: "Safety Tips".tr,
                    fontSize: 20,
                    fontFamily: FontFamily.bold,
                    color: isDark ? AppThemeData.primaryWhite : AppThemeData.primaryBlack,
                  ),
                  const SizedBox(height: 18),
                  // Tips list
                  ...Constant.safetyTips.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check, color: AppThemeData.success300, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            // Use raw Text — TextCustom hard-codes ellipsis
                            // overflow and would truncate long tips.
                            child: Text(
                              tip,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                fontFamily: FontFamily.regular,
                                color: isDark ? AppThemeData.grey3 : AppThemeData.grey8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(true),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppThemeData.primary4,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          continueLabel.tr,
                          style: const TextStyle(
                            fontSize: 15,
                            fontFamily: FontFamily.semiBold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((confirmed) {
      if (confirmed == true) onContinue();
    });
  }
}
