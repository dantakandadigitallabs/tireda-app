import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart'; // Added HugeIcons import

import '../controllers/dashboard_screen_controller.dart';

class DashboardScreenView extends StatelessWidget {
  const DashboardScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return GetX<DashboardScreenController>(
      init: DashboardScreenController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
          body: controller.isLoading.value ? Constant.loader(context: context) : controller.pageList[controller.selectedIndex.value],
          bottomNavigationBar: Obx(
                () => Container(
              decoration: BoxDecoration(
                color: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  BottomNavigationBar(
                    elevation: 0,
                    type: BottomNavigationBarType.fixed,
                    currentIndex: controller.selectedIndex.value,
                    onTap: (int index) {
                      controller.selectedIndex.value = index;
                    },
                    backgroundColor: themeChange.isDarkTheme() ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                    // The magic happens here: These two lines will automatically color the HugeIcons
                    selectedItemColor: AppThemeData.primary4,
                    unselectedItemColor: themeChange.isDarkTheme() ? AppThemeData.grey6 : AppThemeData.grey5,
                    selectedLabelStyle: TextStyle(fontSize: 14, fontFamily: FontFamily.medium, color: AppThemeData.primary4),
                    showSelectedLabels: true,
                    showUnselectedLabels: true,
                    unselectedLabelStyle: TextStyle(fontSize: 12, fontFamily: FontFamily.regular, color: themeChange.isDarkTheme() ? AppThemeData.grey6 : AppThemeData.grey5),
                    items: [
                      BottomNavigationBarItem(
                        // Replaced SVG with standard Icon wrapping HugeIcons
                        icon: const Icon(HugeIcons.strokeRoundedHome03),
                        label: "Home".tr,
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(HugeIcons.strokeRoundedMessage02),
                        label: "Chat".tr,
                      ),
                      BottomNavigationBarItem(
                          icon: const SizedBox(height: 24, width: 24),
                          label: "Sell".tr
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(HugeIcons.strokeRoundedTag02), // Perfect for "Ads/Listings"
                        label: "Ads".tr,
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(HugeIcons.strokeRoundedUserCircle02),
                        label: "Profile".tr,
                      ),
                    ],
                  ),
                  Positioned(
                    top: -27,
                    child: GestureDetector(
                      onTap: () => controller.onSellTap(),
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppThemeData.primary4,
                          boxShadow: [BoxShadow(color: AppThemeData.primary4.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        // Updated the center FAB to use HugeIcons as well for consistency
                        child: Center(
                          child: Icon(
                              HugeIcons.strokeRoundedAdd01,
                              color: AppThemeData.primaryWhite,
                              size: 30
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
    );
  }
}