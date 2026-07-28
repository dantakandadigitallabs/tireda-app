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
          final barBg = isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite;
          return Scaffold(
            backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
            body: controller.isLoading.value ? Constant.loader(context: context) : controller.pageList[controller.selectedIndex.value],
            // Tireda custom: Upgraded to Material 3 NavigationBar — soft pill
            // selection indicator (top-line removed), flat full-opacity icons,
            // semibold/bold label weights, and a slightly elevated Sell FAB.
            bottomNavigationBar: Obx(
                  () => Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppThemeData.grey8 : AppThemeData.grey3,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    navigationBarTheme: NavigationBarTheme.of(context).copyWith(
                      // Tireda custom: selected label bold, unselected semibold
                      // (dropped plain regular weight for unselected).
                      labelTextStyle: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return TextStyle(
                            fontSize: 12,
                            fontFamily: FontFamily.bold,
                            color: AppThemeData.primary4,
                          );
                        }
                        return TextStyle(
                          fontSize: 12,
                          fontFamily: FontFamily.semiBold,
                          color: isDark ? AppThemeData.grey6 : AppThemeData.grey5,
                        );
                      }),
                    ),
                  ),
                  child: NavigationBar(
                    elevation: 0,
                    height: 64,
                    backgroundColor: barBg,
                    indicatorColor: Colors.transparent,
                    selectedIndex: controller.selectedIndex.value,
                    onDestinationSelected: (int index) {
                      controller.onTabTap(index);
                    },
                    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                    destinations: [
                      NavigationDestination(
                        icon: _buildNavIcon(
                          icon: HugeIcons.strokeRoundedHome03,
                          isSelected: controller.selectedIndex.value == 0,
                          isDark: isDark,
                        ),
                        label: 'Home'.tr,
                      ),
                      NavigationDestination(
                        icon: _buildNavIcon(
                          icon: HugeIcons.strokeRoundedMessage02,
                          isSelected: controller.selectedIndex.value == 1,
                          isDark: isDark,
                          unreadCount: controller.unreadMessageCount.value,
                        ),
                        label: 'Chat'.tr,
                      ),
                      NavigationDestination(
                        icon: _buildSellButton(barBg),
                        label: 'Sell'.tr,
                      ),
                      NavigationDestination(
                        icon: _buildNavIcon(
                          icon: HugeIcons.strokeRoundedTag02,
                          isSelected: controller.selectedIndex.value == 3,
                          isDark: isDark,
                        ),
                        label: 'Ads'.tr,
                      ),
                      NavigationDestination(
                        icon: _buildNavIcon(
                          icon: HugeIcons.strokeRoundedUserCircle02,
                          isSelected: controller.selectedIndex.value == 4,
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

  // Tireda custom: nav icon — soft pill background behind selected icon
  // (animated), flat full-opacity color instead of the old opacity-fade
  // trick, and an optional capped numeric unread badge.
  Widget _buildNavIcon({
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    int unreadCount = 0,
  }) {
    final selectedColor = AppThemeData.primary4;
    final unselectedColor = isDark ? AppThemeData.grey6 : AppThemeData.grey5;

    Widget iconWidget = Icon(
      icon,
      color: isSelected ? selectedColor : unselectedColor,
      size: 22,
    );

    if (unreadCount > 0) {
      iconWidget = Badge(
        label: Text(unreadCount > 9 ? '9+' : '$unreadCount'),
        child: iconWidget,
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? selectedColor.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: iconWidget,
    );
  }

  // Tireda custom: Sell button raised slightly above the bar line with a
  // ring matching the bar background, so it visually "pierces" through
  // instead of just floating disconnected above it. Amber shadow retained.
  Widget _buildSellButton(Color barBg) {
    return Transform.translate(
      offset: const Offset(0, -8),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppThemeData.secondary4,
          border: Border.all(color: barBg, width: 3),
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
      ),
    );
  }
}