import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';

import '../controllers/dashboard_screen_controller.dart';

class DashboardScreenView extends StatefulWidget {
  const DashboardScreenView({super.key});

  @override
  State<DashboardScreenView> createState() => _DashboardScreenViewState();
}

class _DashboardScreenViewState extends State<DashboardScreenView> {
  bool _backPressedOnce = false;

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_backPressedOnce) {
          SystemNavigator.pop();
          return;
        }
        setState(() => _backPressedOnce = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Press back again to exit'.tr),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _backPressedOnce = false);
      },
      child: GetX<DashboardScreenController>(
        init: DashboardScreenController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
            body: controller.isLoading.value ? Constant.loader(context: context) : controller.pageList[controller.selectedIndex.value],
            // Tireda custom: Upgraded to Material 3 NavigationBar with HugeIcons opacity trick, top line indicator, and engineered Sell button
            bottomNavigationBar: Obx(
                  () => Container(
                decoration: BoxDecoration(
                  // Tireda custom: Replaced shadow with subtle hairline top border for cleaner elevation
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppThemeData.grey8 : AppThemeData.grey3,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Theme(
                  // Tireda custom: Override NavigationBarTheme for custom label styling per selection state
                  data: Theme.of(context).copyWith(
                    navigationBarTheme: NavigationBarTheme.of(context).copyWith(
                      labelTextStyle: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return TextStyle(
                            fontSize: 12,
                            fontFamily: FontFamily.medium,
                            color: AppThemeData.primary4,
                          );
                        }
                        return TextStyle(
                          fontSize: 12,
                          fontFamily: FontFamily.regular,
                          color: isDark ? AppThemeData.grey6 : AppThemeData.grey5,
                        );
                      }),
                    ),
                  ),
                  child: NavigationBar(
                    // Tireda custom: M3 NavigationBar replaces BottomNavigationBar
                    elevation: 0,
                    height: 64,
                    backgroundColor: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                    // Tireda custom: Transparent indicator to disable default M3 pill, using custom top line instead
                    indicatorColor: Colors.transparent,
                    selectedIndex: controller.selectedIndex.value,
                    onDestinationSelected: (int index) {
                      controller.onTabTap(index);
                    },
                    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                    destinations: [
                      // Tireda custom: Home tab with HugeIcons strokeRounded, opacity trick, and top line indicator
                      NavigationDestination(
                        icon: _buildNavIcon(
                          icon: HugeIcons.strokeRoundedHome03,
                          isSelected: controller.selectedIndex.value == 0,
                          indicatorColor: AppThemeData.primary4,
                          isDark: isDark,
                        ),
                        label: 'Home'.tr,
                      ),
                      // Tireda custom: Chat tab with HugeIcons strokeRounded, opacity trick, top line indicator, and notification badge
                      NavigationDestination(
                        icon: _buildNavIcon(
                          icon: HugeIcons.strokeRoundedMessage02,
                          isSelected: controller.selectedIndex.value == 1,
                          indicatorColor: AppThemeData.primary4,
                          isDark: isDark,
                          badge: controller.hasUnreadMessages.value,
                        ),
                        label: 'Chat'.tr,
                      ),
                      // Tireda custom: Sell tab with engineered raised circle button, amber shadow, and white icon
                      NavigationDestination(
                        icon: _buildSellButton(),
                        label: 'Sell'.tr,
                      ),
                      // Tireda custom: Ads tab with HugeIcons strokeRounded, opacity trick, and top line indicator
                      NavigationDestination(
                        icon: _buildNavIcon(
                          icon: HugeIcons.strokeRoundedTag02,
                          isSelected: controller.selectedIndex.value == 3,
                          indicatorColor: AppThemeData.primary4,
                          isDark: isDark,
                        ),
                        label: 'Ads'.tr,
                      ),
                      // Tireda custom: Profile tab with HugeIcons strokeRounded, opacity trick, and top line indicator
                      NavigationDestination(
                        icon: _buildNavIcon(
                          icon: HugeIcons.strokeRoundedUserCircle02,
                          isSelected: controller.selectedIndex.value == 4,
                          indicatorColor: AppThemeData.primary4,
                          isDark: isDark,
                        ),
                        label: 'Profile'.tr,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Tireda custom: Helper to build navigation icon with top line indicator and opacity trick
  Widget _buildNavIcon({
    required IconData icon,
    required bool isSelected,
    required Color indicatorColor,
    required bool isDark,
    bool badge = false,
  }) {
    Widget iconWidget = Opacity(
      opacity: isSelected ? 1.0 : 0.6,
      child: Icon(
        icon,
        color: isSelected ? indicatorColor : (isDark ? AppThemeData.grey6 : AppThemeData.grey5),
        size: 24,
      ),
    );

    if (badge) {
      iconWidget = Badge(
        smallSize: 10,
        child: iconWidget,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tireda custom: Animated top line indicator, visible only when selected
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: isSelected ? 2 : 0,
          width: 20,
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: indicatorColor,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        iconWidget,
      ],
    );
  }

  // Tireda custom: Engineered Sell button with raised circle, amber shadow, and white icon
  Widget _buildSellButton() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppThemeData.secondary4,
        // Tireda custom: Soft amber shadow for tactile elevation, making Sell button pop
        boxShadow: [
          BoxShadow(
            color: AppThemeData.secondary4.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Icon(
        HugeIcons.strokeRoundedAdd01,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}